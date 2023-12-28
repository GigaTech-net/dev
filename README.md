# GigaTECH Development environment

[![CI](https://github.com/GigaTech-net/dev/actions/workflows/main.yml/badge.svg)](https://github.com/GigaTech-net/dev/actions/workflows/main.yml)
[![Project Status: Active – The project has reached a stable, usable state and is being actively developed.](https://www.repostatus.org/badges/latest/active.svg)](https://www.repostatus.org/#active)
[![Docker Pulls](https://img.shields.io/docker/pulls/GigaTech-net/dev?style=flat)](https://hub.docker.com/repository/docker/gigatech/dev/general)

A development environment for use at GigaTECH. Published to a [docker image](https://hub.docker.com/repository/docker/gigatech/dev).

## using the docker container

### Running the container in non interactive mode

For example, run the development environment to execute the [FHIR validator](https://confluence.hl7.org/display/FHIR/Using+the+FHIR+Validator) in the current directory.

```zsh
export HOME="/Users/matthewjenks"
export GTDEV_IMG="gigatech/dev"
export GTDEV_VER=latest

docker container run --rm -w /home/gigatech/workdir \
      -v "$(pwd)":/home/gigatech/workdir \
      -v "${HOME}/.zsh_history":/home/gigatech/.zsh_history \
      -v "${HOME}/.terraform.d":/home/gigatech/.terraform.d \
      -v "${HOME}/.aws":/home/gigatech/.aws \
      -e "TF_LOG=${loglevel}" \
      ${GTDEV_IMG}:${GTDEV_VER} fhirvalidator.sh source/Patient_QuestionnaireResponse_Example.json -transform http://my.hl7.org/Patient-StructureMap -version 4.0.1 -ig logical/ -ig map/patient-structuremap-test.json -log test.txt -output output/Patient_Example-mj.json
```

### Running the container in interactive mode

For example, run the development environment to run curl with jq.

```zsh
export HOME="/Users/matthewjenks"
export GTDEV_IMG="gigatech/dev"
export GTDEV_VER=latest

docker container run --rm -it -w /home/gigatech/workdir \
      -v "$(pwd)":/home/gigatech/workdir \
      -v "${HOME}/.zsh_history":/home/gigatech/.zsh_history \
      -v "${HOME}/.terraform.d":/home/gigatech/.terraform.d \
      -v "${HOME}/.aws":/home/gigatech/.aws \
      -v "${HOME}/.ssh/mjgmail":/home/gigatech/.ssh/id_rsa \
      -v "${HOME}/.ssh/mjgmail.pub":/home/gigatech/.ssh/id_rsa.pub \
      -e "TF_LOG=${loglevel}" \
      ${GTDEV_IMG}:${GTDEV_VER} zsh
```

will get you a zsh prompt. From here you can run the curl command such as:

```zsh
curl -s http://hapi.fhir.org/baseR4/Patient | jq .
```

Notes: If you don't map a public and private key then that config will be ignored. This is useful for communicating with github. If you map those volumes and your key has a passcode, you will br prompted once for it when you start the container.

## Tagging the docker container

tag with a command like:

```bash
git tag -a 0.2.0 -m "add a test tag for version 0.2.0"
git push origin 0.2.0
```

because the current workflow uses elgohr/Publish-Docker-Github-Action@master and the [tag_semver](https://github.com/elgohr/Publish-Docker-Github-Action#tag_semver) option.

## Base development environment

I recommend installing:

- [zsh](http://zsh.sourceforge.net/)
- [ohmyzsh](https://ohmyz.sh/)
- [docker](https://www.docker.com/)
- [aws cli (docker)](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2-docker.html)
- [Terraform](https://www.terraform.io/)
- [Terragrunt](https://terragrunt.gruntwork.io/)
- [Postman](https://www.postman.com/)
- [Serverless Framework](https://www.serverless.com/framework/docs/)
- [This dev environment](https://hub.docker.com/repository/docker/gigatech/dev)

## This environment includes the following utilities

- [zsh](http://zsh.sourceforge.net/)
- [jq](https://stedolan.github.io/jq/)
- wget
- curl
- gnupg
- uuid-runtime
- git
- [aws cli](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html)
- [Terraform](https://www.terraform.io/)
- [Terragrunt](https://terragrunt.gruntwork.io/)
- [go](https://golang.org/)
- [openjdk](http://jdk.java.net/16/)
- [FHIR Validator](https://www.hl7.org/fhir/downloads.html)
