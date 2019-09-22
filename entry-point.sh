#!/usr/bin/env bash

set -eu

warn() {
  {
    if [[ -p /dev/stdin ]]; then
      cat -
    else
      echo "$*"
    fi
  } >&2
}

die() {
  warn "$*"
  exit 1
}

normalize_boolean() {
  if [[ "${1,,}" =~ ^(true|yes|y)$ ]]; then
    echo "true"
  else
    echo "false"
  fi
}

is_debug() {
  [[ -n "${DEBUG:-}" ]]
}

# functions depend on debug-mode
if is_debug; then
  log() {
    if [[ -p /dev/stdin ]]; then
      cat - | warn
    else
      warn "$*"
    fi
  }
else
  log() { :; } # no-op
fi

event_ref_type="$(jq --raw-output .ref_type "$GITHUB_EVENT_PATH")"

if [[ "$event_ref_type" != "branch" ]]; then
  echo "deletee is not a branch but $event_ref_type. This action does nothing."
  exit 0
fi

event_ref="$(jq --raw-output .ref "$GITHUB_EVENT_PATH")"
distribution_name="${INPUT_DISTRIBUTION_NAME:-${event_ref}}"

if [[ -z "${distribution_name:-}" ]]; then
  die 'Could not determine a distribution name.'
fi

# Don't use double-quate
if [[ -n "${INPUT_EXCLUDE_PATTERN:-}" ]] && [[ "$distribution_name" =~ $INPUT_EXCLUDE_PATTERN ]]; then
  echo "$distribution_name matched with ($INPUT_EXCLUDE_PATTERN) so this action does nothing."
  exit 0
fi

api_token="${INPUT_API_TOKEN:-${DPG_API_TOKEN:-${DEPLOYGATE_API_TOKEN:-}}}"

if [[ -z "${api_token:-}" ]]; then
  warn 'Could not get an api token.'
  warn 'You must provide DEPLOYGATE_API_TOKEN through environment variables or inputs.api_token.'
  die 'Exiting...'
fi

app_owner_name="${INPUT_APP_OWNER_NAME:-${DPG_APP_OWNER_NAME:-${DEPLOYGATE_USER_NAME:-${DEPLOYGATE_APP_OWNER_NAME:-}}}}"

if [[ -z "${app_owner_name:-}" ]]; then
  warn 'Could not get an app owner name.'
  warn 'You must provide DEPLOYGATE_APP_OWNER_NAME, DEPLOYGATE_USER_NAME through environment variables or inputs.app_owner_name.'
  die 'Exiting...'
fi

app_id="${INPUT_APP_ID:-${DPG_APP_ID:-}}"

if [[ -z "${app_id:-}" ]]; then
  warn 'Could not get an id of an application to deploy.'
  warn 'You must provide inputs.app_id.'
  die 'Exiting...'
fi

platform="${INPUT_PLATFORM,,}"

if [[ ! "$platform" =~ ^(android|ios)$ ]]; then
  warn 'Could not determine platform.'
  warn 'inputs.platform must be either android or ios. (lettercase insensitive)'
  die 'Exiting...'
fi

ignore_api_failure="$(normalize_boolean ${INPUT_IGNORE_API_FAILURE:-false})"

if [[ "$ignore_api_failure" != "true" ]]; then
  curl() {
    command curl -f "$@"
  }
fi

cat <<EOF | log
information:
app-owner-name=$app_owner_name
app-id=$app_id
platform=$platform
distribution-name=$distribution_name

options:
ignore_api_failure=$ignore_api_failure
EOF

curl -sSL \
  -A "dg-destroy-distribution-action/$(cat /VERSION) (GithubAction; jmatsu/dg-destroy-distribution-action)" \
  -H "Authorization: token $api_token" \
  -X DELETE \
  "https://deploygate.com/api/users/$app_owner_name/platforms/$platform/apps/$app_id/distributions" \
  -d "distribution_name=$distribution_name"