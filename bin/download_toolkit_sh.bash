#!/usr/bin/env bash

set -eu

readonly version="v1.0"

git clone -b "$version" "https://github.com/jmatsu/github-actions-toolkit.git" github-actions-toolkit
cp github-actions-toolkit/toolkit.sh ./toolkit.sh
rm -fr github-actions-toolkit