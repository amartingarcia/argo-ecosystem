# Generate a pair of SSH keys
ssh-keygen -t rsa -b 4096 -C "github_ssh_key" -f "github_ssh_key" -N ""

# Generate known_hosts file
ssh-keyscan -t rsa github.com > known_hosts

# Create secret in Kubernetes cluster
kubectl delete secret git-creds --namespace default &> /dev/null
kubectl create secret generic git-creds \
  --namespace default \
  --from-file=ssh=github_ssh_key \
  --from-file=known_hosts=known_hosts

# Note
echo "Upload the public key to Gihub:"
echo $(cat github_ssh_key.pub)
