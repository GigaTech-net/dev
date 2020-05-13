FROM debian:buster
LABEL maintainer="dev@gigatech.net"

# add our user and group first to make sure their IDs get assigned consistently, regardless of whatever dependencies get added
ENV USER gigatech
ENV HOME /home/$USER
RUN set -ex; \
  groupadd -r $USER; \
  useradd -m -d $HOME -r -g $USER $USER;

# install tini to handle signal processing
ENV TINI_VERSION v0.18.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
RUN chmod +x /tini
ENTRYPOINT ["/tini", "--"]

# install base tools
# grab gosu for easy step-down from root (https://github.com/tianon/gosu/releases)
ENV GOSU_VERSION 1.10
RUN set -ex; \
  \
  apt-get update; \
  apt-get -y upgrade; \
  apt-get install -y \
    python3-pip \
    jq \
    wget \
    uuid-runtime \
    gnupg2 \
    curl \
    git \
    zsh \
  ; \
  rm -rf /var/lib/apt/lists/*

RUN set -ex; \
  dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')"; \
	wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch"; \
	wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch.asc"; \
	export GNUPGHOME="$(mktemp -d)"; \
	gpg --keyserver ha.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4; \
	gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu; \
	command -v gpgconf && gpgconf --kill all || :; \
	rm -r "$GNUPGHOME" /usr/local/bin/gosu.asc; \
	chmod +x /usr/local/bin/gosu; \
	gosu nobody true; 

# install aws tools
RUN set -ex; \
  pip3 install awscli; \
  aws --version; \
  curl -o aws-iam-authenticator https://amazon-eks.s3-us-west-2.amazonaws.com/1.10.3/2018-07-26/bin/linux/amd64/aws-iam-authenticator; \
  chmod +x ./aws-iam-authenticator; \
  cp ./aws-iam-authenticator /usr/local/bin; \
  rm -f aws-iam-authenticator; \
  aws-iam-authenticator help

# install go
ENV GO_VERSION 1.14.2
RUN wget https://dl.google.com/go/go$GO_VERSION.linux-amd64.tar.gz; \
  tar -C /usr/local -xzf go$GO_VERSION.linux-amd64.tar.gz; \
  rm -f go$GO_VERSION.linux-amd64.tar.gz; \
  /usr/local/go/bin/go version;

USER $USER
WORKDIR $HOME
ENV PATH="$HOME/bin:/usr/local/go/bin:$HOME/go/bin:${PATH}"
# install cfssl
RUN set -ex; \
  go get -v -u github.com/cloudflare/cfssl/cmd/cfssl; \
  go get -v -u github.com/cloudflare/cfssl/cmd/cfssljson; \
  rm -rf go/src

# setup zsh
RUN wget https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh -O - | zsh || true
RUN rm .wget-hsts

CMD ["zsh"]