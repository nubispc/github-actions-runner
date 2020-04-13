#!/bin/bash
set -e

RUNNER_TOKEN=$(curl -H "Authorization: token ${GH_TOKEN}" -XPOST https://api.github.com/repos/${GH_ORG}/${GH_REPO}/actions/runners/registration-token| jq .token)
REPO_URL=https://github.com/${GH_ORG}/${GH_REPO}
./config.sh --unattended --replace --url ${REPO_URL} --token ${RUNNER_TOKEN}
exec ./run.sh
