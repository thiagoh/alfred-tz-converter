#!/usr/bin/env bash

set -x

# THESE VARIABLES MUST BE SET. SEE THE ONEUPDATER README FOR AN EXPLANATION OF EACH.
readonly remote_metadata_json='https://raw.githubusercontent.com/thiagoh/alfred-tz-converter/main/metadata.json'
readonly workflow_url='https://github.com/thiagoh/alfred-tz-converter/raw/main/alfred-tz-converter.alfredworkflow'
readonly download_type='direct'
readonly frequency_check="${1:-7}"

# FROM HERE ON, CODE SHOULD BE LEFT UNTOUCHED!
function abort {
  echo "${1}" >&2
  exit 1
}

function url_exists {
  curl --silent --location --output /dev/null --fail --range 0-0 "${1}"
}

function notification {
  local -r notificator="$(find . -type f -name 'notificator')"

  if [[ -f "${notificator}" && "$(/usr/bin/file --brief --mime-type "${notificator}")" == 'text/x-shellscript' ]]; then
    "${notificator}" --message "${1}" --title "${alfred_workflow_name}" --subtitle 'A new version is available'
    return
  fi

  osascript -e "display notification \"${1}\" with title \"${alfred_workflow_name}\" subtitle \"A new version is available\""
}

# Local sanity checks
readonly local_metadata_json='metadata.json'
readonly local_version=$(osascript -l JavaScript -e 'function run(argv) { return JSON.parse(argv).alfredworkflow.version; }' "$(cat metadata.json)")
echo "local_version: $local_version" >> /tmp/alfred.txt
# readonly local_version="$(/usr/libexec/PlistBuddy -c 'print version' "${local_metadata_json}")"

[[ -n "${local_version}" ]] || abort 'You need to set a workflow version in the configuration sheet.'
[[ "${download_type}" =~ ^(direct|page|github_release)$ ]] || abort "'download_type' (${download_type}) needs to be one of 'direct', 'page', or 'github_release'."
[[ "${frequency_check}" =~ ^[0-9]+$ ]] || abort "'frequency_check' (${frequency_check}) needs to be a number."

# Check for updates
if [[ $(find "${local_metadata_json}" -mtime +"${frequency_check}"d) ]]; then
  # Remote sanity check
  if ! url_exists "${remote_metadata_json}"; then
    abort "'remote_metadata_json' (${remote_metadata_json}) appears to not be reachable."
  fi

  readonly tmp_file="$(mktemp)"
  curl --silent --location --output "${tmp_file}" "${remote_metadata_json}"
  readonly remote_version=$(osascript -l JavaScript -e 'function run(argv) { return JSON.parse(argv).alfredworkflow.version; }' "$(cat $tmp_file)")
  echo "remote_version: $remote_version" >> /tmp/alfred.txt
  rm "${tmp_file}"

  if [[ "${local_version}" == "${remote_version}" ]]; then
    echo "Version is up to date" >> /tmp/alfred.txt
    touch "${local_metadata_json}" # Reset timer by touching local file
    exit 0
  else
    echo "Workflow needs to be updated to $remote_version" >> /tmp/alfred.txt
  fi

  if [[ "${download_type}" == 'page' ]]; then
    notification 'Opening download page…'
    open "${workflow_url}"
    exit 0
  fi

  readonly download_url="$(
    if [[ "${download_type}" == 'github_release' ]]; then
      osascript -l JavaScript -e 'function run(argv) { return JSON.parse(argv[0])["assets"].find(asset => asset["browser_download_url"].endsWith(".alfredworkflow"))["browser_download_url"] }' "$(curl --silent "https://api.github.com/repos/${workflow_url}/releases/latest")"
    else
      echo "${workflow_url}"
    fi
  )"

  if url_exists "${download_url}"; then
    notification 'Downloading and installing…'
    readonly download_name="$(basename "${download_url}")"
    curl --silent --location --output "${HOME}/Downloads/${download_name}" "${download_url}"
    open "${HOME}/Downloads/${download_name}"
  else
    abort "'workflow_url' (${download_url}) appears to not be reachable."
  fi
fi
