#!/bin/bash
set -euo pipefail


arch=$(uname -m)
case "$arch" in
  x86_64) 
    TGT_ARCH="amd64"
    AWS_ARCH="x86_64"
    ;;
  aarch64 | arm64)
    TGT_ARCH="arm64"
    AWS_ARCH="aarch64"
    ;;
  *)
    echo "Unsupported architecture: $arch"
    exit 1
    ;;
esac

TGT_OS="linux"

echo "Detected architecture: $TGT_ARCH"

# Install Terraform (corrected URL format)
TERRAFORM_VERSION=$(curl -s https://checkpoint-api.hashicorp.com/v1/check/terraform | jq -r .current_version)
TERRAFORM_URL="https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_${TGT_OS}_${TGT_ARCH}.zip"

echo "Downloading Terraform from: $TERRAFORM_URL"

curl -fsSL -o terraform.zip "$TERRAFORM_URL"
unzip terraform.zip
mv terraform /usr/local/bin/
rm terraform.zip

terraform version

# Install Terragrunt
TERRAGRUNT_VERSION=$(curl -s https://api.github.com/repos/gruntwork-io/terragrunt/releases/latest | jq -r .tag_name | sed 's/^v//')
curl -fsSL -o /usr/local/bin/terragrunt https://github.com/gruntwork-io/terragrunt/releases/download/v${TERRAGRUNT_VERSION}/terragrunt_${TGT_OS}_${TGT_ARCH}
chmod +x /usr/local/bin/terragrunt
terragrunt --version

echo "Installing AWS CLI for $AWS_ARCH"

AWS_ZIP_URL="https://awscli.amazonaws.com/awscli-exe-linux-${AWS_ARCH}.zip"
curl -fsSL -o awscliv2.zip "$AWS_ZIP_URL"
unzip awscliv2.zip
./aws/install
rm -rf aws awscliv2.zip

aws --version

# Install AWS IAM Authenticator
# Get latest version
AUTH_VERSION=$(curl -s https://api.github.com/repos/kubernetes-sigs/aws-iam-authenticator/releases/latest | jq -r .tag_name | sed 's/^v//')

# Build correct URL
AUTH_URL="https://github.com/kubernetes-sigs/aws-iam-authenticator/releases/download/v${AUTH_VERSION}/aws-iam-authenticator_${AUTH_VERSION}_${TGT_OS}_${TGT_ARCH}"

echo "Downloading AWS IAM Authenticator from: $AUTH_URL"

# Download and verify
curl -fsSL -o /usr/local/bin/aws-iam-authenticator "$AUTH_URL"
chmod +x /usr/local/bin/aws-iam-authenticator
aws-iam-authenticator version

# Install gosu
GOSU_VERSION=$(curl -s https://api.github.com/repos/tianon/gosu/releases/latest | jq -r .tag_name)
dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')"
curl -fsSL -o /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/${GOSU_VERSION}/gosu-${dpkgArch}"
chmod +x /usr/local/bin/gosu
gosu --version
