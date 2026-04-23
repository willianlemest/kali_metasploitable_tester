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
USERLIST=""
PASSLIST=""
THREADS="${DEFAULT_THREADS}"
OUTPUT_FILE=""
RESULTS_FILE=""

usage() {
    cat <<EOF
Uso: ${SCRIPT_NAME} -t <TARGET> -U <userlist> -P <passlist> [opções]

Obrigatórios:
  -t <TARGET>      IP ou hostname do alvo
  -U <userlist>    Arquivo com lista de usuários
  -P <passlist>    Arquivo com lista de senhas

Opcionais:
  -T <threads>     Número de threads do Medusa (default: ${DEFAULT_THREADS})
  -o <arquivo>     Arquivo de saída para salvar o log
  -h               Mostrar esta ajuda
EOF
}

while getopts ":t:U:P:T:o:h" opt; do
    case "${opt}" in
        t) TARGET="${OPTARG}" ;;
        U) USERLIST="${OPTARG}" ;;
        P) PASSLIST="${OPTARG}" ;;
        T) THREADS="${OPTARG}" ;;
        o) OUTPUT_FILE="${OPTARG}" ;;
        h) usage; exit 0 ;;
        \?) die "Opção inválida: -${OPTARG}" 1 ;;
        :) die "A opção -${OPTARG} requer um valor." 1 ;;
    esac
done

require_non_empty "${TARGET}" "Target"
require_non_empty "${USERLIST}" "Userlist"
require_non_empty "${PASSLIST}" "Passlist"
require_file "${USERLIST}"
require_file "${PASSLIST}"
require_command medusa

if [[ -z "${OUTPUT_FILE}" ]]; then
    OUTPUT_FILE="$(default_output_file "smb_medusa")"
fi
RESULTS_FILE="${OUTPUT_FILE%.log}_results.txt"

print_section "Sessão SMB"
print_info "Target: ${TARGET}"
print_info "Userlist: ${USERLIST}"
print_info "Passlist: ${PASSLIST}"
print_info "Threads: ${THREADS}"
print_info "Log: ${OUTPUT_FILE}"

run_logged_command "${OUTPUT_FILE}" medusa -h "${TARGET}" -U "${USERLIST}" -P "${PASSLIST}" -M smbnt -t "${THREADS}"
extract_medusa_successes "${OUTPUT_FILE}" "${RESULTS_FILE}"
print_log_summary "${OUTPUT_FILE}" "${RESULTS_FILE}"
