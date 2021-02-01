# GigaTECH Development environment

A development environment for use at GigaTECH. Published to a [docker image](https://hub.docker.com/repository/docker/gigatech/dev).

## using the docker container

For example, run the development environment to run curl with jq.

```zsh
docker container run --rm -it -w /home/gigatech/workdir -v "$(pwd)":/home/gigatech/workdir -v "${HOME}":/home/gigatech -e "TF_LOG=ERROR" gigatech/dev:latest zsh
```

will get you a zsh prompt. Form here you can run the curl command such as:

```zsh
curl -s http://hapi.fhir.org/baseR4/Patient | jq . 
```

## Tagging the docker container

tag with a command like:

```bash
git tag -a 0.2.0 -m "add a test tag for version 0.2.0"
git push origin 0.2.0
```

because the current workflow uses elgohr/Publish-Docker-Github-Action@master and the [tag_semver](https://github.com/elgohr/Publish-Docker-Github-Action#tag_semver) option.

## Base development environment

I recommend installing:

- [zsh][http://zsh.sourceforge.net/]
- [ohmyzsh](https://ohmyz.sh/)
- [docker](https://www.docker.com/)
- [aws cli (docker)](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2-docker.html)
- [Terraform](https://www.terraform.io/)
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
- [go](https://golang.org/)
