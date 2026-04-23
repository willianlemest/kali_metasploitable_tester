#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/../config.sh"
# shellcheck disable=SC1091
source "${LIB_DIR}/common.sh"
# shellcheck disable=SC1091
source "${LIB_DIR}/executor.sh"
# shellcheck disable=SC1091
source "${LIB_DIR}/parser.sh"
# shellcheck disable=SC1091
source "${LIB_DIR}/reporting.sh"

SCRIPT_NAME="$(basename "$0")"
TARGET=""
OUTFILE=""
RAW_OUT=""

usage() {
    cat <<EOF
Uso:
  ${SCRIPT_NAME} -t <TARGET> [-o <ARQUIVO_SAIDA>]

Opções:
  -t    IP ou hostname do alvo
  -o    Arquivo de saída para a lista de usuários (default: logs/users_<TARGET>.txt)
  -h    Mostrar esta ajuda
EOF
}

while getopts ":t:o:h" opt; do
    case "${opt}" in
        t) TARGET="${OPTARG}" ;;
        o) OUTFILE="${OPTARG}" ;;
        h) usage; exit 0 ;;
        \?) die "Opção inválida: -${OPTARG}" 1 ;;
        :) die "A opção -${OPTARG} requer um valor." 1 ;;
    esac
done

require_non_empty "${TARGET}" "Target"
require_command enum4linux
ensure_dir "${LOGS_DIR}"

if [[ -z "${OUTFILE}" ]]; then
    OUTFILE="${LOGS_DIR}/users_${TARGET}.txt"
fi
RAW_OUT="${LOGS_DIR}/enum4linux_${TARGET}_$(timestamp).raw"

print_section "Sessão enum4linux"
print_info "Target: ${TARGET}"
print_info "Saída bruta: ${RAW_OUT}"
print_info "Lista de usuários: ${OUTFILE}"

run_logged_command "${RAW_OUT}" enum4linux -a "${TARGET}"
extract_enum4linux_users "${RAW_OUT}" "${OUTFILE}"

if [[ -s "${OUTFILE}" ]]; then
    print_success "Lista de usuários gerada em: ${OUTFILE}"
else
    print_warn "Não foi possível extrair usuários automaticamente. Verifique ${RAW_OUT}"
fi
