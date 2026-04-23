#!/usr/bin/env bash

if [[ -z "${PROJECT_ROOT:-}" ]]; then
    # shellcheck disable=SC1091
    source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/config.sh"
fi

timestamp() {
    date +'%Y%m%d_%H%M%S'
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

print_info() {
    printf '%b %s\n' "${INFO_PREFIX}" "$*"
}

print_warn() {
    printf '%b %s\n' "${WARN_PREFIX}" "$*" >&2
}

print_error() {
    printf '%b %s\n' "${ERROR_PREFIX}" "$*" >&2
}

print_success() {
    printf '%b %s\n' "${OK_PREFIX}" "$*"
}

die() {
    local message="$1"
    local code="${2:-1}"
    print_error "${message}"
    exit "${code}"
}

pause_for_user() {
    printf '\n'
    read -r -p "Pressione ENTER para continuar..." _
}

require_command() {
    local binary="$1"
    command_exists "${binary}" || die "Dependência não encontrada no PATH: ${binary}" 127
}

require_executable() {
    local path="$1"
    [[ -x "${path}" ]] || die "Script não encontrado ou sem permissão de execução: ${path}"
}

require_non_empty() {
    local value="$1"
    local label="$2"
    [[ -n "${value}" ]] || die "${label} não pode ficar em branco."
}

require_file() {
    local path="$1"
    [[ -f "${path}" ]] || die "Arquivo não encontrado: ${path}"
}

ensure_dir() {
    local path="$1"
    mkdir -p "${path}"
}

default_output_file() {
    local prefix="$1"
    ensure_dir "${LOGS_DIR}"
    printf '%s/%s_%s.log\n' "${LOGS_DIR}" "${prefix}" "$(timestamp)"
}

install_interrupt_trap() {
    trap 'printf "\n%b Operação interrompida pelo usuário.\n" "${WARN_PREFIX}" >&2; exit 130' INT
}
