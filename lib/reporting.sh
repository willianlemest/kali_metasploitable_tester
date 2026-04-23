#!/usr/bin/env bash

if [[ -z "${PROJECT_ROOT:-}" ]]; then
    # shellcheck disable=SC1091
    source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/config.sh"
fi

# shellcheck disable=SC1091
source "${LIB_DIR}/common.sh"

print_banner() {
    clear 2>/dev/null || true
    cat <<EOF
${MAGENTA}====================================================${RESET}
${MAGENTA}   _  __     _ _       __  __      _        _       ${RESET}
${MAGENTA}  | |/ /__ _| (_)_ __ |  \/  | ___| |_ __ _| |___   ${RESET}
${MAGENTA}  | ' // _\` | | | '_ \| |\/| |/ _ \ __/ _\` | / -_)  ${RESET}
${MAGENTA}  |_|\_\__,_|_|_| .__/|_|  |_|\___/\__\__,_|_\___|  ${RESET}
${MAGENTA}               |_|   kali_metasploitable_tester     ${RESET}
${MAGENTA}====================================================${RESET}
 ${DIM}Shell-based lab helper for Medusa and enum4linux${RESET}

EOF
}

print_section() {
    printf '%b%s%b\n' "${BOLD}" "$1" "${RESET}"
}

print_log_summary() {
    local log_file="$1"
    local results_file="${2:-}"

    printf '\n'
    print_section "Resumo"
    print_info "Log completo: ${log_file}"
    if [[ -n "${results_file}" ]]; then
        if [[ -s "${results_file}" ]]; then
            print_success "Resultados relevantes salvos em: ${results_file}"
        else
            print_warn "Nenhum resultado relevante foi extraído para ${results_file}"
        fi
    fi
}
