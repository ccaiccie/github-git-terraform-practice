# GitLab-managed state: an empty HTTP backend.
# The OpenTofu component fills in the address and credentials in CI.
terraform {
  backend "http" {
  }
}
