#!/usr/bin/env bash

if [[ -z "${PROJECT_ROOT:-}" ]]; then
    # shellcheck disable=SC1091
    source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/config.sh"
fi

# shellcheck disable=SC1091
source "${LIB_DIR}/common.sh"

extract_enum4linux_users() {
    local raw_file="$1"
    local output_file="$2"

    require_file "${raw_file}"
    grep -E "user:\[" "${raw_file}" 2>/dev/null \
        | sed -E 's/.*user:\[([^]]+)\].*/\1/' \
        | sort -u > "${output_file}" || true
}

extract_medusa_successes() {
    local log_file="$1"
    local results_file="$2"

    require_file "${log_file}"
    grep -E "ACCOUNT FOUND|SUCCESS" "${log_file}" 2>/dev/null \
        | sed 's/\r$//' \
        | sort -u > "${results_file}" || true
}
