#!/bin/bash

# Create port forwarding
function create_port_forwarding {
    # $1: namespace, $2: service name, $3: local port, $4: remote port
    kubectl --context kind-kind -n $1 port-forward svc/$2 $3:$4
}

# Main execution flow
if [ "$#" -ne 4 ]; then
    echo "Usage: $0 <namespace> <service name> <local port> <remote port>"
    exit 1
fi

create_port_forwarding $1 $2 $3 $4
