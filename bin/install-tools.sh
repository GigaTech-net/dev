#!/bin/bash
set -euo pipefail

arch=$(uname -m)
TGT_OS="linux"
TGT_ARCH="amd64"
[[ "$arch" == "aarch64" ]] && TGT_ARCH="arm64"

# Terraform
TERRAFORM_VERSION=$(curl -s https://checkpoint-api.hashicorp.com/v1/check/terraform | jq -r .current_version)
wget https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_${TGT_OS}_${TGT_ARCH}.zip
unzip terraform_${TERRAFORM_VERSION}_${TGT_OS}_${TGT_ARCH}.zip
mv terraform /usr/bin && rm terraform_*.zip
terraform -version

# Terragrunt
TERRAGRUNT_VERSION=$(curl -s https://api.github.com/repos/gruntwork-io/terragrunt/releases/latest | jq -r .tag_name | sed 's/v//')
wget -O /usr/local/bin/terragrunt https://github.com/gruntwork-io/terragrunt/releases/download/v${TERRAGRUNT_VERSION}/terragrunt_${TGT_OS}_${TGT_ARCH}
chmod +x /usr/local/bin/terragrunt
terragrunt --version

# AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-${arch}.zip" -o "awscliv2.zip"
unzip awscliv2.zip && ./aws/install && rm -rf aws awscliv2.zip
aws --version

# AWS IAM Authenticator
AUTH_VERSION=$(curl -s https://api.github.com/repos/kubernetes-sigs/aws-iam-authenticator/releases/latest | jq -r .tag_name | sed 's/v//')
curl -Lo aws-iam-authenticator https://github.com/kubernetes-sigs/aws-iam-authenticator/releases/download/v${AUTH_VERSION}/aws-iam-authenticator_${TGT_OS}_${TGT_ARCH}
chmod +x aws-iam-authenticator && mv aws-iam-authenticator /usr/local/bin/
aws-iam-authenticator version

# gosu
GOSU_VERSION=$(curl -s https://api.github.com/repos/tianon/gosu/releases/latest | jq -r .tag_name)
dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')"
wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/${GOSU_VERSION}/gosu-${dpkgArch}"
chmod +x /usr/local/bin/gosu
gosu --version
