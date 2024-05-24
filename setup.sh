#!/bin/bash

stty -echoctl

KIND_VERSION="v0.22.0"
KUBECTL_VERSION="v1.30.0"
TERRAFORM_VERSION="1.8.1"

# Print with color
function print_color {
    # $1: color, $2: message
    # $1: red, green, yellow, blue, magenta, cyan, white

    start_color=""
    end_color="\e[0m"

    case $1 in
        red)
            start_color="\e[31m"
            ;;
        green)
            start_color="\e[32m"
            ;;
        yellow)
            start_color="\e[33m"
            ;;
        blue)
            start_color="\e[34m"
            ;;
        magenta)
            start_color="\e[35m"
            ;;
        cyan)
            start_color="\e[36m"
            ;;
        white)
            start_color="\e[37m"
            ;;
        *)
            start_color="\e[37m"
            ;;
    esac

    echo -e "${start_color}${2}${end_color}"
}

# Check for Docker
function check_docker {
    # Print with white color
    print_color white "[*] Checking for Docker..."
    if ! command -v docker &> /dev/null; then
        print_color red "[!] Docker is not installed."
        exit 1
    fi
    print_color green "[+] Docker is installed."
}

# Install Kind
function install_kind {
    print_color white "[*] Installing Kind..."
    curl -Lo ./kind "https://github.com/kubernetes-sigs/kind/releases/download/${KIND_VERSION}/kind-$(uname)-amd64"
    chmod +x ./kind
    sudo mv ./kind /usr/local/bin/kind
    print_color green "[+] Kind installed successfully."
}

# Check for Kind
function check_kind {
    print_color white "[*] Checking for Kind..."
    if ! command -v kind &> /dev/null; then
        print_color yellow "[!] Kind is not installed."
        install_kind
    else
        print_color green "[+] Kind is installed."
    fi
}

# Check for kubectl
function install_kubectl {
    local os=$(uname | awk '{print tolower($0)}')
    print_color white "[*] Installing kubectl..."
    curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/${os}/amd64/kubectl"
    chmod +x kubectl
    sudo mv kubectl /usr/local/bin/kubectl
    print_color green "[+] kubectl installed successfully."
}

function check_kubectl {
    print_color white "[*] Checking for kubectl..."
    if ! command -v kubectl &> /dev/null; then
        print_color yellow "[!] kubectl is not installed."
        install_kubectl
    else
        print_color green "[+] kubectl is installed."
    fi
}

# Check for Terraform
function install_terraform {
    local os=$(uname | awk '{print tolower($0)}')
    print_color white "[*] Installing Terraform..."
    curl -Lo terraform.zip "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_${os}_amd64.zip"
    unzip terraform.zip
    chmod +x terraform
    sudo mv terraform /usr/local/bin/
    rm terraform.zip
    print_color green "[+] Terraform installed successfully."
}

function check_terraform {
    print_color white "[*] Checking for Terraform..."
    if ! command -v terraform &> /dev/null; then
        print_color yellow "[!] Terraform is not installed."
        install_terraform
    else
        print_color green "[+] Terraform is installed."
    fi
}

function install_helm {
    print_color white "[*] Installing Helm..."
    curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
    chmod 700 get_helm.sh
    ./get_helm.sh
    rm get_helm.sh
    print_color green "[+] Helm installed successfully."
}

function check_helm {
    print_color white "[*] Checking for Helm..."
    if ! command -v helm &> /dev/null; then
        print_color yellow "[!] Helm is not installed."
        install_helm
    else
        print_color green "[+] Helm is installed."
    fi
}

function check_helm_chart {
    # $1: chart name, $2: namespace, $3: repo, $4: repo url
    print_color white "[*] Checking for $1 helm chart..."
    if ! helm list -n $2 | grep -q "$1"; then
        print_color yellow "[!] $1 helm chart is not installed."
        print_color white "[*] Installing $1 helm chart..."
        helm repo add $3 $4
        helm repo update
        helm install $1 $3/$1 -n $2
        print_color green "[+] $1 helm chart installed successfully."
    else
        print_color green "[+] $1 helm chart is installed."
    fi
}

function kill_cluster {
    print_color white "[*] Killing Kind cluster..."
    kind delete cluster --name kind
    print_color green "[+] Kind cluster killed successfully."
    exit 0
}

# Main execution flow
function main {
    # Check for dependencies
    check_docker
    check_kind
    check_kubectl
    check_terraform
    check_helm

    print_color white "[*] Setting up local registry..."
    reg_name='kind-registry'
    reg_port='5001'
    if [ "$(docker inspect -f '{{.State.Running}}' "${reg_name}" 2>/dev/null || true)" != 'true' ]; then
        docker run \
            -d --restart=always -p "127.0.0.1:${reg_port}:5000" --name "${reg_name}" \
            registry:2
    fi

    # Check for Kind cluster
    print_color white "[*] Checking for Kind cluster..."
    
    if ! kind get clusters | grep -q "kind"; then
        print_color yellow "[!] Kind cluster is not running."
        print_color white "[*] Creating Kind cluster..."
        cat <<EOF | kind create cluster --name kind --config=-
            kind: Cluster
            apiVersion: kind.x-k8s.io/v1alpha4
            containerdConfigPatches:
            - |-
                [plugins."io.containerd.grpc.v1.cri".registry.mirrors."localhost:${reg_port}"]
                    endpoint = ["http://${reg_name}:5000"]
EOF

        print_color green "[+] Kind cluster created successfully."
    else
        print_color green "[+] Kind cluster is running."
    fi

    # Wait for cluster to be ready
    print_color white "[*] Waiting for Kind cluster to be ready..."
    kubectl wait --for=condition=Ready node --all --timeout=1m

    print_color white "[*] Connecting registry to Kind cluster..."
    if [ "$(docker inspect -f='{{json .NetworkSettings.Networks.kind}}' "${reg_name}")" = 'null' ]; then
        docker network connect "kind" "${reg_name}"
    fi

    # Document the local registry
    # https://github.com/kubernetes/enhancements/tree/master/keps/sig-cluster-lifecycle/generic/1755-communicating-a-local-registry
    print_color white "[*] Documenting the local registry..."

    cat <<EOF | kubectl apply -f -
    apiVersion: v1
    kind: ConfigMap
    metadata:
        name: local-registry-hosting
        namespace: kube-public
    data:
        localRegistryHosting.v1: |
            host: "localhost:${reg_port}"
            help: "https://kind.sigs.k8s.io/docs/user/local-registry/"
EOF

    # Trap SIGINT signal
    trap 'kill_cluster' SIGINT
    
    kind export kubeconfig
    # Set kubeconfig
    print_color white "[*] Setting kubeconfig..."
    kubectl --context kind-kind cluster-info
    print_color green "[+] kubeconfig set successfully."

    # Check for Kubernetes Dashboard helm chart
    check_helm_chart "kubernetes-dashboard" "kube-system" "kubernetes-dashboard" "https://kubernetes.github.io/dashboard/"
    
    # Wait for Kubernetes Dashboard to be ready
    print_color white "[*] Waiting for Kubernetes Dashboard to be ready..."
    kubectl wait --for=condition=Ready pod -l app.kubernetes.io/instance=kubernetes-dashboard -n kube-system --timeout=1m

    # Create service account and cluster role binding
    # Check if does not exist service account
    if ! kubectl get sa admin-user -n kube-system &> /dev/null; then
        print_color white "[*] Creating service account and cluster role binding..."
        kubectl apply -f resources/dashboard-admin.yaml
        print_color green "[+] Service account and cluster role binding created successfully."
    else
        print_color green "[+] Service account and cluster role binding already exists."
    fi

    # Get token
    token=$(kubectl get secret admin-user -n kube-system -o jsonpath={".data.token"} | base64 -d)
    print_color white "[*] Token: ${token}"

    # Generate kubeconfig
    print_color white "[*] Generating kubeconfig..."
    kubectl config view --raw > kubeconfig.yaml

    # Start Kubernetes Dashboard
    print_color white "[*] Starting Kubernetes Dashboard..."
    kubectl --context kind-kind -n kube-system port-forward svc/kubernetes-dashboard-kong-proxy 8443:443
}

main
