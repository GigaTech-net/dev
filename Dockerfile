# hadolint global ignore=SC2015,DL4001,DL3047,DL3015,DL4006,DL3003,SC2164,DL3008
FROM debian:bookworm-slim
LABEL maintainer="dev@gigatech.net"

# add our user and group first to make sure their IDs get assigned consistently, regardless of whatever dependencies get added
ENV USER gigatech
ENV HOME /home/$USER
RUN set -ex; \
  groupadd -r $USER; \
  useradd -m -d $HOME -r -g $USER $USER;

# install tini to handle signal processing
ENV TINI_VERSION v0.19.0
# checkov:skip=CKV_DOCKER_4: USe add for URL as COPY wont work
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
RUN chmod +x /tini
ENTRYPOINT ["/tini", "--"]

# install base tools
# grab gosu for easy step-down from root (https://github.com/tianon/gosu/releases)
ENV GOSU_VERSION 1.14
RUN set -ex; \
  \
  apt-get update; \
  apt-get -y upgrade; \
  apt-get install -y \
  unzip \
  jq \
  wget \
  uuid-runtime \
  gnupg2 \
  curl \
  git \
  zsh \
  groff \
  default-jdk && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*

RUN set -ex; \
  dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')"; \
  wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch"; \
  wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch.asc"; \
  export GNUPGHOME="$(mktemp -d)"; \
  for server in ha.pool.sks-keyservers.net \
  hkp://p80.pool.sks-keyservers.net:80 \
  keyserver.ubuntu.com \
  hkp://keyserver.ubuntu.com:80 \
  pgp.mit.edu; do \
  gpg --keyserver "$server" --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 && break || echo "Trying new server..."; \
  done; \
  gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu; \
  command -v gpgconf && gpgconf --kill all || :; \
  rm -r "$GNUPGHOME" /usr/local/bin/gosu.asc; \
  chmod +x /usr/local/bin/gosu; \
  gosu nobody true; 

# install aws tools
RUN set -ex; \
  curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"; \
  unzip awscliv2.zip; \
  ./aws/install; \
  aws --version; \
  rm awscliv2.zip; \
  rm -rf ./aws; \
  curl -o aws-iam-authenticator https://amazon-eks.s3-us-west-2.amazonaws.com/1.10.3/2018-07-26/bin/linux/amd64/aws-iam-authenticator; \
  chmod +x ./aws-iam-authenticator; \
  cp ./aws-iam-authenticator /usr/local/bin; \
  rm -f aws-iam-authenticator; \
  aws-iam-authenticator help

# install go
ENV GO_VERSION 1.21.5
RUN wget https://dl.google.com/go/go$GO_VERSION.linux-amd64.tar.gz; \
  tar -C /usr/local -xzf go$GO_VERSION.linux-amd64.tar.gz; \
  rm -f go$GO_VERSION.linux-amd64.tar.gz; \
  /usr/local/go/bin/go version;

# install terraform
ENV TERRAFORM_VERSION 1.6.6
RUN set -ex; \
  wget https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip; \
  unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip; \
  mv terraform /usr/bin; \
  rm terraform_${TERRAFORM_VERSION}_linux_amd64.zip;

# install terragrunt
# ENV TERRAGRUNT_VERSION 0.52.3
ENV TERRAGRUNT_VERSION 0.54.11
RUN set -ex; \
  wget https://github.com/gruntwork-io/terragrunt/releases/download/v${TERRAGRUNT_VERSION}/terragrunt_linux_amd64; \
  mv terragrunt_linux_amd64 /usr/bin/terragrunt; \
  chmod a+rx /usr/bin/terragrunt;

# install FHIR validator JAR 
RUN mkdir -p /usr/java/fhirvalidator; \
  cd /usr/java/fhirvalidator; \
  wget https://github.com/hapifhir/org.hl7.fhir.core/releases/latest/download/validator_cli.jar;

ENV FHIR_VALIDATOR_JAR /usr/java/fhirvalidator/validator_cli.jar
ENV JAVA_CLASSPATH ${JAVA_CLASSPATH}:/usr/java/fhirvalidator

USER $USER
WORKDIR $HOME
ENV PATH="${HOME}/bin:/usr/local/go/bin:${HOME}/go/bin:${PATH}"

# install FHIR validator start script
RUN mkdir -p bin
COPY --chown=${USER}:${USER} bin/fhirvalidator.sh ${HOME}/bin/fhirvalidator.sh
RUN chmod 755 ${HOME}/bin/fhirvalidator.sh

# setup zsh
RUN wget https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh -O - | zsh || true
RUN rm .wget-hsts

COPY --chown=$USER:$USER src/.zshrc $HOME/.zshrc
RUN mkdir -p $HOME/.ssh
COPY --chown=$USER:$USER src/ssh-config $HOME/.ssh/config

CMD ["zsh"]
# checkov:skip=CKV_DOCKER_2: Healthcheck not needed for this image