#!/usr/bin/env bash

if [[ -z "${PROJECT_ROOT:-}" ]]; then
    # shellcheck disable=SC1091
    source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/config.sh"
fi

# shellcheck disable=SC1091
source "${LIB_DIR}/common.sh"

print_command() {
    local command_text
    printf -v command_text '%q ' "$@"
    printf '%b %s\n' "${INFO_PREFIX}" "Comando: ${BOLD}${command_text% }${RESET}"
}

run_logged_command() {
    local output_file="$1"
    shift

    ensure_dir "$(dirname "${output_file}")"
    print_command "$@"
    "$@" 2>&1 | tee "${output_file}"
}

append_logged_command() {
    local output_file="$1"
    shift

    ensure_dir "$(dirname "${output_file}")"
    print_command "$@"
    "$@" 2>&1 | tee -a "${output_file}"
}

check_port_connectivity() {
    local target="$1"
    local port="$2"

    if ! command_exists nc; then
        print_warn "nc não encontrado. Pulando teste de conectividade."
        return 2
    fi

    if nc -z -w3 "${target}" "${port}"; then
        print_success "Porta ${port} em ${target} aparentemente aberta."
        return 0
    fi

    print_warn "Não foi possível confirmar a porta ${port} em ${target}."
    return 1
}
