# hadolint global ignore=SC2015,DL4001,DL3047,DL3015,DL4006,DL3003,SC2164,DL3008
# Use the latest Debian Slim image as the base
FROM debian:bookworm-slim
LABEL maintainer="dev@gigatech.net"

# Set environment variables to non-interactive to avoid prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Define versions for the tools to be installed
ENV TERRAFORM_VERSION=1.11.3
ENV TERRAGRUNT_VERSION=0.77.2
ENV AWSCLI_VERSION=2.25.6
ENV AWS_IAM_AUTHENTICATOR_VERSION=0.6.30
ENV GOSU_VERSION 1.17
ENV TGT_OS=linux

# add our user and group first to make sure their IDs get assigned consistently, regardless of whatever dependencies get added
ENV USER gigatech
ENV HOME /home/$USER
RUN set -ex; \
  groupadd -r $USER; \
  useradd -m -d $HOME -r -g $USER $USER;

# Update package list and install common web tools and dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        curl \
        wget \
        jq \
        unzip \
        gnupg \
        lsb-release \
        ca-certificates \
        groff \
        zsh \
        git && \
    rm -rf /var/lib/apt/lists/*

# Install Terraform
RUN set -ex; \
    case "$(uname -m)" in \
        x86_64) export TGT_ARCH="amd64" ;; \
        aarch64) export TGT_ARCH="arm64" ;; \
        *) echo "Unsupported architecture"; exit 1 ;; \
    esac && \
    wget https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_${TGT_OS}_${TGT_ARCH}.zip; \
    unzip terraform_${TERRAFORM_VERSION}_${TGT_OS}_${TGT_ARCH}.zip; \
    mv terraform /usr/bin; \
    rm terraform_${TERRAFORM_VERSION}_${TGT_OS}_${TGT_ARCH}.zip;

# Verify Terraform
RUN terraform --version

# Install Terragrunt
RUN case "$(uname -m)" in \
        x86_64) export TGT_ARCH="amd64" ;; \
        aarch64) export TGT_ARCH="arm64" ;; \
        *) echo "Unsupported architecture"; exit 1 ;; \
    esac && \
    wget -O /usr/local/bin/terragrunt https://github.com/gruntwork-io/terragrunt/releases/download/v${TERRAGRUNT_VERSION}/terragrunt_${TGT_OS}_${TGT_ARCH} && \
    chmod +x /usr/local/bin/terragrunt

# Verify Terragrunt
RUN terragrunt --version

# Install AWS CLI
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-$(uname -m).zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install && \
    rm -rf awscliv2.zip aws/

# Verify AWS cli
RUN aws help

# Install AWS IAM Authenticator
RUN case "$(uname -m)" in \
        x86_64) export TGT_ARCH="amd64" ;; \
        aarch64) export TGT_ARCH="arm64" ;; \
        *) echo "Unsupported architecture"; exit 1 ;; \
        esac && \
    curl -Lo aws-iam-authenticator https://github.com/kubernetes-sigs/aws-iam-authenticator/releases/download/v${AWS_IAM_AUTHENTICATOR_VERSION}/aws-iam-authenticator_${AWS_IAM_AUTHENTICATOR_VERSION}_${TGT_OS}_${TGT_ARCH} && \
    chmod +x aws-iam-authenticator && \
    mv aws-iam-authenticator /usr/local/bin/aws-iam-authenticator

# Verify AWS IAM Authenticator
RUN aws-iam-authenticator version

# Install gosu
RUN set -eux; \
  # save list of currently installed packages for later so we can clean up
  savedAptMark="$(apt-mark showmanual)"; \
  apt-get update; \
  apt-get install -y --no-install-recommends ca-certificates gnupg wget; \
  rm -rf /var/lib/apt/lists/*; \
  \
  dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')"; \
  wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch"; \
  wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch.asc"; \
  \
  # verify the signature
  export GNUPGHOME="$(mktemp -d)"; \
  gpg --batch --keyserver hkps://keys.openpgp.org --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4; \
  gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu; \
  gpgconf --kill all; \
  rm -rf "$GNUPGHOME" /usr/local/bin/gosu.asc; \
  \
  # clean up fetch dependencies
  apt-mark auto '.*' > /dev/null; \
  [ -z "$savedAptMark" ] || apt-mark manual $savedAptMark; \
  apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
  \
  chmod +x /usr/local/bin/gosu;

# verify that the binary works
RUN gosu --version; \
    gosu nobody true

# install FHIR validator JAR 
RUN mkdir -p /usr/java/fhirvalidator; \
  cd /usr/java/fhirvalidator; \
  wget https://github.com/hapifhir/org.hl7.fhir.core/releases/latest/download/validator_cli.jar;

ENV FHIR_VALIDATOR_JAR /usr/java/fhirvalidator/validator_cli.jar
ENV JAVA_CLASSPATH ${JAVA_CLASSPATH}:/usr/java/fhirvalidator

# Set Zsh as the default shell for the root user
RUN chsh -s /bin/zsh root

USER $USER
WORKDIR $HOME
ENV PATH="${HOME}/bin:/usr/local/go/bin:${HOME}/go/bin:${PATH}"

# install FHIR validator start script
RUN mkdir -p bin
COPY --chown=${USER}:${USER} bin/fhirvalidator.sh ${HOME}/bin/fhirvalidator.sh
RUN chmod 755 ${HOME}/bin/fhirvalidator.sh

# setup zsh
# setup zsh (use git instead of piping script to zsh)
RUN git clone https://github.com/ohmyzsh/ohmyzsh.git $HOME/.oh-my-zsh && \
    cp $HOME/.oh-my-zsh/templates/zshrc.zsh-template $HOME/.zshrc && \
    chown -R $USER:$USER $HOME/.oh-my-zsh $HOME/.zshrc


COPY --chown=$USER:$USER src/.zshrc $HOME/.zshrc
RUN mkdir -p $HOME/.ssh
COPY --chown=$USER:$USER src/ssh-config $HOME/.ssh/config

# Set the entrypoint to Zsh for interactive access
ENTRYPOINT ["/bin/zsh"]

# Default command to run in interactive mode
CMD ["zsh"]
# checkov:skip=CKV_DOCKER_2: Healthcheck not needed for this image