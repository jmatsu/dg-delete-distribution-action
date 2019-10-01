#!/usr/bin/env bash

set -eu

source /toolkit.sh

normalize_boolean() {
  if [[ "${1,,}" =~ ^(true|yes|y)$ ]]; then
    echo "true"
  else
    echo "false"
  fi
}

readonly action_version="$(cat /VERSION)"

github::debug "the action version is $action_version"

event_ref="$(jq --raw-output .ref "$GITHUB_EVENT_PATH")"
distribution_name="${INPUT_DISTRIBUTION_NAME:-${event_ref}}"

if [[ -z "${distribution_name:-}" ]]; then
  github::warning 'Could not determine a distribution name.'
  github::error 'Exit because distribution name is not found'
  github::failure
fi

# Don't use double-quate
if [[ -n "${INPUT_EXCLUDE_PATTERN:-}" ]] && [[ "$distribution_name" =~ $INPUT_EXCLUDE_PATTERN ]]; then
  github::warning "$distribution_name matched with ($INPUT_EXCLUDE_PATTERN) so this action does nothing."
  github::success
fi

api_token="${INPUT_API_TOKEN:-${DPG_API_TOKEN:-${DEPLOYGATE_API_TOKEN:-}}}"

if [[ -z "${api_token:-}" ]]; then
  github::warning 'Could not get an api token.'
  github::error 'You must provide DEPLOYGATE_API_TOKEN through environment variables or inputs.api_token.'
  github::error 'Exit because api token is not found'
  github::failure
fi

app_owner_name="${INPUT_APP_OWNER_NAME:-${DPG_APP_OWNER_NAME:-${DEPLOYGATE_USER_NAME:-${DEPLOYGATE_APP_OWNER_NAME:-}}}}"
github::debug "inputs.app_owner_name is ${INPUT_APP_OWNER_NAME:-}"
github::debug "DPG_APP_OWNER_NAME is ${DPG_APP_OWNER_NAME:-}"
github::debug "DEPLOYGATE_USER_NAME is ${DEPLOYGATE_USER_NAME:-}"
github::debug "DEPLOYGATE_APP_OWNER_NAME is ${DEPLOYGATE_APP_OWNER_NAME:-}"
github::debug "app_owner_name: $app_owner_name will be used"

if [[ -z "${app_owner_name:-}" ]]; then
  github::warning 'Could not get an app owner name.'
  github::error 'You must provide DEPLOYGATE_APP_OWNER_NAME, DEPLOYGATE_USER_NAME through environment variables or inputs.app_owner_name.'
  github::error 'Exit because application owner name is not found'
  github::failure
fi

app_id="${INPUT_APP_ID:-${DPG_APP_ID:-}}"
github::debug "inputs.app_id is ${INPUT_APP_ID:-}"
github::debug "DPG_APP_ID is ${DPG_APP_ID:-}"
github::debug "app_id: $app_id will be used"

if [[ -z "$app_id" ]]; then
  github::warning 'Could not get an id of an application to deploy.'
  github::error 'You must provide inputs.app_id.'
  github::error 'Exit because application id is not found'
  github::failure
fi

platform="${INPUT_PLATFORM,,}"
github::debug "inputs.platform is ${INPUT_PLATFORM:-}"
github::debug "platform: $platform will be used"

if [[ ! "$platform" =~ ^(android|ios)$ ]]; then
  github::warning 'Could not determine platform.'
  github::error 'inputs.platform must be either android or ios. (lettercase insensitive)'
  github::error 'Exit because platform is invalid'
  github::failure
fi

ignore_api_failure="$(normalize_boolean ${INPUT_IGNORE_API_FAILURE:-false})"
github::debug "ignore_api_failure: $ignore_api_failure will be used"

if [[ "$ignore_api_failure" != "true" ]]; then
  github::debug "never ignore api failures"

  curl() {
    command curl -f "$@"
  }
else
  github::debug "ignore api failures"
fi

curl -sSL \
  -A "dg-delete-distribution-action/$action_version (GithubAction; jmatsu/dg-delete-distribution-action)" \
  -H "Authorization: token $api_token" \
  -X DELETE \
  "https://deploygate.com/api/users/$app_owner_name/platforms/$platform/apps/$app_id/distributions" \
  -d "distribution_name=$distribution_name"