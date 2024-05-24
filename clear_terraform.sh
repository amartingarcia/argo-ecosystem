# Delete all the Terraform state files and cache files

directories=(00-argo 10-eventbus)

for dir in "${directories[@]}"; do
  echo "Deleting $dir"
  rm -rf "$dir/.terraform"
  rm -rf "$dir/.terraform.lock.hcl"
  rm -rf "$dir/.terraform.cache"
  rm -rf "$dir/.terraform.tfstate"
  rm -rf "$dir/.terraform.tfstate.backup"
done

rm -rf gitlab_ssh_key
rm -rf gitlab_ssh_key.pub
rm -rf known_hosts
rm -rf kubeconfig.yaml
