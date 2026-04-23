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
PORT="${DEFAULT_FTP_PORT}"
USERLIST=""
SINGLE_USER=""
PASSLIST=""
OUTPUT_DIR="${LOGS_DIR}/ftp"
MODE=""

usage() {
    cat <<EOF
${SCRIPT_NAME} - Testes de credenciais FTP em ambiente de laboratório

Uso:
  Single user:
    ${SCRIPT_NAME} -s -t <alvo> -u <usuario> -P <passlist> [opções]

  Userlist:
    ${SCRIPT_NAME} -l -t <alvo> -U <userlist> -P <passlist> [opções]

Parâmetros:
  -s              Modo single user
  -l              Modo userlist
  -t <alvo>       IP ou hostname do FTP
  -u <usuario>    Usuário único (com -s)
  -U <userlist>   Arquivo com lista de usuários (com -l)
  -P <passlist>   Arquivo com lista de senhas
  -p <porta>      Porta FTP (default: ${DEFAULT_FTP_PORT})
  -o <dir>        Diretório de saída (default: ${OUTPUT_DIR})
  -h              Mostrar esta ajuda
EOF
}

while getopts ":t:p:U:u:P:slo:h" opt; do
    case "${opt}" in
        t) TARGET="${OPTARG}" ;;
        p) PORT="${OPTARG}" ;;
        U) USERLIST="${OPTARG}" ;;
        u) SINGLE_USER="${OPTARG}" ;;
        P) PASSLIST="${OPTARG}" ;;
        s) MODE="single" ;;
        l) MODE="list" ;;
        o) OUTPUT_DIR="${OPTARG}" ;;
        h) usage; exit 0 ;;
        :) die "A opção -${OPTARG} requer um valor." 1 ;;
        \?) die "Opção inválida: -${OPTARG}" 1 ;;
    esac
done

require_non_empty "${MODE}" "Modo (-s ou -l)"
require_non_empty "${TARGET}" "Alvo"
require_non_empty "${PASSLIST}" "Passlist"
require_file "${PASSLIST}"
require_command medusa

case "${MODE}" in
    single)
        require_non_empty "${SINGLE_USER}" "Usuário (-u)"
        ;;
    list)
        require_non_empty "${USERLIST}" "Userlist (-U)"
        require_file "${USERLIST}"
        ;;
    *)
        die "Modo inválido. Use -s ou -l."
        ;;
esac

SESSION_DIR="${OUTPUT_DIR}/ftp_${TARGET}_$(timestamp)"
LOG_FILE="${SESSION_DIR}/ftp_bruteforce.log"
RESULTS_FILE="${SESSION_DIR}/valid_credentials.txt"
ensure_dir "${SESSION_DIR}"

print_section "Sessão FTP"
print_info "Target: ${TARGET}:${PORT}"
print_info "Modo: ${MODE}"
print_info "Userlist: ${USERLIST:-'(não usado)'}"
print_info "Usuário único: ${SINGLE_USER:-'(não usado)'}"
print_info "Passlist: ${PASSLIST}"
print_info "Saída: ${SESSION_DIR}"

check_port_connectivity "${TARGET}" "${PORT}" || true

if [[ "${MODE}" == "single" ]]; then
    append_logged_command "${LOG_FILE}" medusa -h "${TARGET}" -u "${SINGLE_USER}" -P "${PASSLIST}" -M ftp -n "${PORT}" -t "${DEFAULT_THREADS}"
else
    append_logged_command "${LOG_FILE}" medusa -h "${TARGET}" -U "${USERLIST}" -P "${PASSLIST}" -M ftp -n "${PORT}" -t "${DEFAULT_THREADS}"
fi

extract_medusa_successes "${LOG_FILE}" "${RESULTS_FILE}"
print_log_summary "${LOG_FILE}" "${RESULTS_FILE}"
