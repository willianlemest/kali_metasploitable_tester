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
MODE=""
TARGET=""
USER_SINGLE=""
USERLIST=""
PASSLIST=""
PAGE_TARGET=""
PORT="${DEFAULT_HTTP_PORT}"
OUTPUT_FILE=""
RESULTS_FILE=""

usage() {
    cat <<EOF
Uso: ${SCRIPT_NAME} -s|-l -t TARGET (-u USER | -U USERLIST) -P PASSLIST -r PAGETGT [opções]

Modos:
  -s                Single user
  -l                Lista de usuários

Parâmetros obrigatórios:
  -t TARGET         IP ou hostname do alvo
  -u USER           Usuário único (com -s)
  -U USERLIST       Arquivo de usuários (com -l)
  -P PASSLIST       Arquivo de senhas
  -r PAGETGT        Caminho da página de login

Opções:
  -p PORT           Porta HTTP (default: ${DEFAULT_HTTP_PORT})
  -o FILE           Arquivo de saída (log)
  -h                Mostrar esta ajuda
EOF
}

while getopts ":slt:u:U:P:r:p:o:h" opt; do
    case "${opt}" in
        s) MODE="single" ;;
        l) MODE="list" ;;
        t) TARGET="${OPTARG}" ;;
        u) USER_SINGLE="${OPTARG}" ;;
        U) USERLIST="${OPTARG}" ;;
        P) PASSLIST="${OPTARG}" ;;
        r) PAGE_TARGET="${OPTARG}" ;;
        p) PORT="${OPTARG}" ;;
        o) OUTPUT_FILE="${OPTARG}" ;;
        h) usage; exit 0 ;;
        \?) die "Opção inválida: -${OPTARG}" 1 ;;
        :) die "A opção -${OPTARG} requer um valor." 1 ;;
    esac
done

require_non_empty "${MODE}" "Modo (-s ou -l)"
require_non_empty "${TARGET}" "Target"
require_non_empty "${PASSLIST}" "Passlist"
require_non_empty "${PAGE_TARGET}" "Página alvo"
require_file "${PASSLIST}"
require_command medusa

case "${MODE}" in
    single)
        require_non_empty "${USER_SINGLE}" "Usuário (-u)"
        ;;
    list)
        require_non_empty "${USERLIST}" "Userlist (-U)"
        require_file "${USERLIST}"
        ;;
    *)
        die "Modo inválido. Use -s ou -l."
        ;;
esac

if [[ -z "${OUTPUT_FILE}" ]]; then
    OUTPUT_FILE="$(default_output_file "webform_${TARGET}")"
fi
RESULTS_FILE="${OUTPUT_FILE%.log}_results.txt"

print_section "Sessão HTTP Form"
print_info "Target: ${TARGET}:${PORT}"
print_info "Página: ${PAGE_TARGET}"
print_info "Passlist: ${PASSLIST}"
print_info "Log: ${OUTPUT_FILE}"
if [[ "${MODE}" == "single" ]]; then
    print_info "Modo: single user (${USER_SINGLE})"
else
    print_info "Modo: userlist (${USERLIST})"
fi

if [[ "${MODE}" == "single" ]]; then
    run_logged_command "${OUTPUT_FILE}" medusa -h "${TARGET}" -u "${USER_SINGLE}" -P "${PASSLIST}" -M http -n "${PORT}" -m "PAGE:${PAGE_TARGET}" -m "FORM:${DEFAULT_HTTP_FORM}" -m "${DEFAULT_HTTP_FAIL}" -t "${DEFAULT_THREADS}"
else
    run_logged_command "${OUTPUT_FILE}" medusa -h "${TARGET}" -U "${USERLIST}" -P "${PASSLIST}" -M http -n "${PORT}" -m "PAGE:${PAGE_TARGET}" -m "FORM:${DEFAULT_HTTP_FORM}" -m "${DEFAULT_HTTP_FAIL}" -t "${DEFAULT_THREADS}"
fi

extract_medusa_successes "${OUTPUT_FILE}" "${RESULTS_FILE}"
print_log_summary "${OUTPUT_FILE}" "${RESULTS_FILE}"
