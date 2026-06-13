#!/usr/bin/env bash
set -Eeuo pipefail

app_id="${STEAM_APP_ID:-565060}"
state_file="${STEAM_BUILDID_FILE:-.github/steam-buildid.txt}"
steamcmd="${STEAMCMD:-steamcmd}"

current_buildid="$(${steamcmd} +login anonymous +app_info_update 1 +app_info_print "${app_id}" +quit \
    | awk '$1 == "\"buildid\"" { gsub(/\"/, "", $2); buildid = $2 } END { print buildid }')"

if [[ -z "${current_buildid}" ]]; then
    echo "Unable to resolve Steam buildid for app ${app_id}" >&2
    exit 1
fi

previous_buildid=""
if [[ -f "${state_file}" ]]; then
    previous_buildid="$(tr -d '[:space:]' < "${state_file}")"
fi

mkdir -p "$(dirname "${state_file}")"
printf '%s\n' "${current_buildid}" > "${state_file}"

{
    echo "current_buildid=${current_buildid}"
    echo "previous_buildid=${previous_buildid}"
    if [[ "${current_buildid}" != "${previous_buildid}" ]]; then
        echo "updated=true"
    else
        echo "updated=false"
    fi
} >> "${GITHUB_OUTPUT:-/dev/stdout}"
