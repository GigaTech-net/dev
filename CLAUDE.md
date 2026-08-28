# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repository is

`dev` builds GigaTECH's shared development-environment container, published to Docker
Hub as [`gigatech/dev`](https://hub.docker.com/repository/docker/gigatech/dev/general).
It is a Dockerfile plus three shell scripts — there is no application source here.

The image is the team's common toolchain: Debian bookworm-slim, Zsh + Oh My Zsh,
Terraform, Terragrunt, AWS CLI v2, `aws-iam-authenticator`, the HL7 FHIR validator, and
the usual `jq`/`curl`/`git`/`gnupg` set. It runs as the unprivileged user `gigatech`
with `$HOME=/home/gigatech`.

**The default branch is `development`, not `main`.**

## Build and release

```bash
docker build -t gigatech/dev:local .
```

Publishing is tag-driven, not branch-driven. `main-release.yaml` fires on tags matching
`v*` and pushes to Docker Hub via Buildx:

```bash
git tag -a 0.2.0 -m "add a test tag for version 0.2.0"
git push origin 0.2.0
```

## Running the image

Work is mounted at `/home/gigatech/workdir`, which is also the working directory:

```bash
docker container run --rm -it -w /home/gigatech/workdir \
  -v "$(pwd)":/home/gigatech/workdir \
  -v "${HOME}/.aws":/home/gigatech/.aws \
  -v "${HOME}/.terraform.d":/home/gigatech/.terraform.d \
  gigatech/dev:latest zsh
```

Drop `-it` and append a command to run non-interactively — for example
`fhirvalidator.sh <file> -version 4.0.1`.

SSH keys are optional. `bin/start-agent.sh` runs from `/etc/profile.d/` and starts an
agent only if `$HOME/.ssh` exists, adding every `id_*` that is not a `.pub`. Mount a key
pair to `id_rsa`/`id_rsa.pub` to enable Git-over-SSH; mount nothing and the config is
simply ignored. A passphrase is prompted for once at container start.

## Structure

| Path                           | Holds                                                             |
| ------------------------------ | ----------------------------------------------------------------- |
| `Dockerfile`                   | multi-stage build; installs are ordered so tool layers cache      |
| `bin/install-tools.sh`         | the toolchain install, run during build                           |
| `bin/fhirvalidator.sh`         | `java -jar` wrapper on the HL7 validator, on `$PATH` in the image |
| `bin/start-agent.sh`           | conditional ssh-agent bootstrap, sourced at login                 |
| `src/.zshrc`, `src/ssh-config` | shell and SSH config baked into the image                         |

`install-tools.sh` detects `x86_64` vs `arm64` and **resolves every tool version at build
time** — Terraform from the HashiCorp checkpoint API, Terragrunt and
`aws-iam-authenticator` from their GitHub latest-release endpoints, the FHIR validator
from `latest/download`. Nothing is pinned, so two builds of the same commit can produce
different tool versions, and a build can break because an upstream release changed rather
than because this repository did. Check upstream before debugging the Dockerfile.

## CI architecture

Six workflows in `.github/workflows/`, one per branch event: `feature-push`,
`development-pr` / `development-push`, `main-pr` / `main-push`, `main-release`.

Every step is a composite action pinned at `@v1` from
`GigaTech-net/reusable-workflows/.github/actions/*`. The workflow files here orchestrate;
the logic lives upstream — fix behaviour in `reusable-workflows` rather than inlining a
step here. `.github/linters/` holds the Super-Linter configuration, including
`.hadolint.yaml` for the Dockerfile and `trivy.yaml` for image scanning.

`concurrency: cancel-in-progress: true` is set on `${{ github.ref }}-${{ github.workflow }}`,
so a push followed by a PR-open cancels the first run. **A cancelled run reported as a
failure is usually this** — look for a newer run on the branch before investigating.

### Tokens

Write steps take the App token `setup-token` puts in `$GITHUB_ENV`, as
`${{ env.GITHUB_TOKEN }}`. Never a personal access token, and never override with
`secrets.GITHUB_TOKEN` on the approve step — that attributes the approval to
`github-actions[bot]`, which does not satisfy `required_approving_review_count`.

## PR titles

CI validates the format and fails the PR if it does not match:

```text
<type>: <scope>: <description>
```

`<type>` is a Conventional Commits keyword; `<scope>` is `hotfix`, `maint`, or a Jira
issue ID such as `PRO-1234`. Both colons and both spaces are required.

## Code comments

**Never write a comment whose subject is a change you made.** No "removed X", no
"switched from Y to Z", no "X is no longer used", no "was previously W".

The reason is searchability. A comment naming a removed identifier keeps that identifier
greppable forever, so every later search for it returns the epitaph alongside the real
hits with no way to tell them apart.

Document what the code **is** and does. The change belongs in the commit message, the PR
body, and the Jira ticket — all attributed and attached to a diff, which a comment is not.
Where a rejected alternative must be recorded, describe the failure mode without naming
the dead identifier.
