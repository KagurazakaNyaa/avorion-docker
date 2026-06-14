#!/usr/bin/env bash
set -Eeuo pipefail

steamcmd="/home/steam/steamcmd/steamcmd.sh"
server_binary="${AVORION_SERVER_DIR}/bin/AvorionServer"
galaxy_dir="${AVORION_DATA_PATH}/${GALAXY_NAME}"

bool_arg() {
    case "${1,,}" in
        true|1|yes|on) return 0 ;;
        false|0|no|off|"") return 1 ;;
        *) return 1 ;;
    esac
}

append_csv_flags() {
    local option_name="$1"
    local raw_value="$2"

    if [[ -z "${raw_value}" ]]; then
        return
    fi

    local value
    IFS=',' read -ra values <<< "${raw_value}"
    for value in "${values[@]}"; do
        value="${value//[[:space:]]/}"
        if [[ -n "${value}" ]]; then
            server_args+=("${option_name}" "${value}")
        fi
    done
}

update_server() {
    if [[ ! -x "${server_binary}" ]] || bool_arg "${FORCE_UPDATE}"; then
        "${steamcmd}" +login anonymous +quit

        local update_args=(
            +force_install_dir "${AVORION_SERVER_DIR}"
            +login anonymous
            +app_update "${AVORION_APP_ID}"
        )

        if [[ -n "${AVORION_BRANCH:-}" ]]; then
            update_args+=(-beta "${AVORION_BRANCH}")
        fi

        if [[ -n "${AVORION_BETA_PASSWORD:-}" ]]; then
            update_args+=(-betapassword "${AVORION_BETA_PASSWORD}")
        fi

        if bool_arg "${VALIDATE_SERVER}"; then
            update_args+=(validate)
        fi

        "${steamcmd}" "${update_args[@]}" +quit
    fi
}

update_workshop_mods() {
    local modconfig="${galaxy_dir}/modconfig.lua"

    if ! bool_arg "${UPDATE_WORKSHOP_MODS}" || [[ ! -f "${modconfig}" ]]; then
        return
    fi

    mapfile -t workshop_ids < <(grep -Eo 'workshopid[[:space:]]*=[[:space:]]*"[0-9]+"' "${modconfig}" \
        | grep -Eo '[0-9]+' \
        | sort -u)

    if [[ "${#workshop_ids[@]}" -eq 0 ]]; then
        return
    fi

    local steam_workshop_dir="${galaxy_dir}/steamapps/workshop"
    local avorion_workshop_dir="${galaxy_dir}/workshop"
    mkdir -p "${galaxy_dir}/steamapps" "${avorion_workshop_dir}"

    if [[ -L "${steam_workshop_dir}" ]]; then
        rm -f "${steam_workshop_dir}"
    elif [[ -d "${steam_workshop_dir}" ]]; then
        cp -a "${steam_workshop_dir}/." "${avorion_workshop_dir}/"
        rm -rf "${steam_workshop_dir}"
    elif [[ -e "${steam_workshop_dir}" ]]; then
        echo "ERROR: ${steam_workshop_dir} exists but is not a directory or symlink" >&2
        exit 1
    fi

    ln -s "../workshop" "${steam_workshop_dir}"

    local steamcmd_args=(
        +force_install_dir "${galaxy_dir}"
        +login anonymous
    )

    local workshop_id
    for workshop_id in "${workshop_ids[@]}"; do
        steamcmd_args+=(+workshop_download_item "${AVORION_GAME_APP_ID}" "${workshop_id}" validate)
    done

    "${steamcmd}" "${steamcmd_args[@]}" +quit
}

if [[ "$#" -gt 0 ]]; then
    exec "$@"
fi

mkdir -p "${AVORION_SERVER_DIR}" "${galaxy_dir}"

update_server
update_workshop_mods

server_args=(
    --galaxy-name "${GALAXY_NAME}"
    --datapath "${AVORION_DATA_PATH}"
    --server-name "${SERVER_NAME}"
    --port "${SERVER_PORT}"
)

append_csv_flags --admin "${ADMIN_STEAM_IDS}"

if [[ -n "${MAX_PLAYERS}" ]]; then
    server_args+=(--max-players "${MAX_PLAYERS}")
fi

if [[ -n "${SERVER_PUBLIC}" ]]; then
    server_args+=(--public "${SERVER_PUBLIC}")
fi

if [[ -n "${SERVER_LISTED}" ]]; then
    server_args+=(--listed "${SERVER_LISTED}")
fi

if [[ -n "${USE_STEAM_NETWORKING}" ]]; then
    server_args+=(--use-steam-networking "${USE_STEAM_NETWORKING}")
fi

if [[ -n "${EXTRA_ARGS}" ]]; then
    read -r -a extra_args <<< "${EXTRA_ARGS}"
    server_args+=("${extra_args[@]}")
fi

cd "${AVORION_SERVER_DIR}"
exec "${server_binary}" "${server_args[@]}"
