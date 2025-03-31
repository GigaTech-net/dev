# syntax=docker/dockerfile:1.7
FROM debian:bookworm-slim AS base

LABEL maintainer="dev@gigatech.net"

ENV DEBIAN_FRONTEND=noninteractive
ENV USER gigatech
ENV HOME /home/$USER

# Create user early
RUN groupadd -r $USER && useradd -m -d $HOME -r -g $USER $USER

# Install common utilities
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl wget unzip gnupg jq git zsh lsb-release ca-certificates groff \
    openssh-client procps sudo && \
    rm -rf /var/lib/apt/lists/*

# Install Oh My Zsh
RUN git clone https://github.com/ohmyzsh/ohmyzsh.git $HOME/.oh-my-zsh && \
    cp $HOME/.oh-my-zsh/templates/zshrc.zsh-template $HOME/.zshrc && \
    chown -R $USER:$USER $HOME/.oh-my-zsh $HOME/.zshrc

# Use zsh as default
RUN chsh -s /bin/zsh root && chsh -s /bin/zsh $USER

# Add tools dynamically using a script
COPY bin/install-tools.sh /usr/local/bin/install-tools.sh
RUN chmod +x /usr/local/bin/install-tools.sh && /usr/local/bin/install-tools.sh

# Install FHIR validator
RUN mkdir -p /usr/java/fhirvalidator && \
    wget -qO /usr/java/fhirvalidator/validator_cli.jar \
    https://github.com/hapifhir/org.hl7.fhir.core/releases/latest/download/validator_cli.jar

ENV FHIR_VALIDATOR_JAR=/usr/java/fhirvalidator/validator_cli.jar
ENV JAVA_CLASSPATH=${JAVA_CLASSPATH}:/usr/java/fhirvalidator

# Copy user scripts
COPY --chown=${USER}:${USER} bin/fhirvalidator.sh ${HOME}/bin/fhirvalidator.sh
RUN chmod 755 ${HOME}/bin/fhirvalidator.sh

# Setup ssh-config and optional ssh-agent script
COPY --chown=$USER:$USER src/.zshrc $HOME/.zshrc
COPY --chown=$USER:$USER src/ssh-config $HOME/.ssh/config
COPY start-agent.sh /etc/profile.d/start-agent.sh
RUN chmod +x /etc/profile.d/start-agent.sh

USER $USER
WORKDIR $HOME
ENV PATH="${HOME}/bin:/usr/local/go/bin:${HOME}/go/bin:${PATH}"

ENTRYPOINT ["/bin/zsh"]
