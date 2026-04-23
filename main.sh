#!/usr/bin/env bash

set -euo pipefail

# shellcheck disable=SC1091
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/config.sh"
# shellcheck disable=SC1091
source "${LIB_DIR}/common.sh"
# shellcheck disable=SC1091
source "${LIB_DIR}/reporting.sh"

FTP_SCRIPT="${SCRIPTS_DIR}/ftp_protocol.sh"
SMB_ENUM_SCRIPT="${SCRIPTS_DIR}/smb_enum_user.sh"
SMB_SCRIPT="${SCRIPTS_DIR}/smb_protocol.sh"
WEB_FORM_SCRIPT="${SCRIPTS_DIR}/webform_protocol.sh"

install_interrupt_trap

print_menu() {
    print_banner
    print_section "Selecione uma opção"
    printf '  %b[1]%b FTP Brute Force         %b(%s)%b\n' "${CYAN}" "${RESET}" "${DIM}" "$(basename "${FTP_SCRIPT}")" "${RESET}"
    printf '  %b[2]%b Enumeração SMB          %b(%s)%b\n' "${CYAN}" "${RESET}" "${DIM}" "$(basename "${SMB_ENUM_SCRIPT}")" "${RESET}"
    printf '  %b[3]%b SMB Password Spraying   %b(%s)%b\n' "${CYAN}" "${RESET}" "${DIM}" "$(basename "${SMB_SCRIPT}")" "${RESET}"
    printf '  %b[4]%b HTTP Form Brute Force   %b(%s)%b\n' "${CYAN}" "${RESET}" "${DIM}" "$(basename "${WEB_FORM_SCRIPT}")" "${RESET}"
    printf '\n  %b[0]%b Sair\n\n' "${RED}" "${RESET}"
}

prompt_target() {
    local prompt_label="$1"
    local value=""
    read -r -p "${prompt_label}: " value
    require_non_empty "${value}" "${prompt_label}"
    printf '%s\n' "${value}"
}

run_ftp_menu() {
    local target mode username userlist passlist

    print_banner
    print_section "[ FTP Brute Force - Medusa ]"
    require_file "${FTP_SCRIPT}"

    target="$(prompt_target 'Alvo (IP ou hostname)')"
    printf '\n'
    printf '%bModo:%b\n' "${BOLD}" "${RESET}"
    printf '  [1] Single user (-s)\n'
    printf '  [2] Userlist (-l)\n\n'
    read -r -p "Escolha (1 ou 2): " mode

    case "${mode}" in
        1)
            read -r -p "Usuário único: " username
            read -r -p "Wordlist de senhas: " passlist
            require_non_empty "${username}" "Usuário"
            require_non_empty "${passlist}" "Wordlist de senhas"
            bash "${FTP_SCRIPT}" -s -t "${target}" -u "${username}" -P "${passlist}"
            ;;
        2)
            read -r -p "Wordlist de usuários: " userlist
            read -r -p "Wordlist de senhas: " passlist
            require_non_empty "${userlist}" "Wordlist de usuários"
            require_non_empty "${passlist}" "Wordlist de senhas"
            bash "${FTP_SCRIPT}" -l -t "${target}" -U "${userlist}" -P "${passlist}"
            ;;
        *)
            print_warn "Opção inválida."
            ;;
    esac

    pause_for_user
}

run_smb_enum_menu() {
    local target outfile

    print_banner
    print_section "[ Enumeração de Usuários SMB - enum4linux ]"
    require_file "${SMB_ENUM_SCRIPT}"

    target="$(prompt_target 'Alvo (IP ou hostname)')"
    read -r -p "Arquivo de saída (ENTER para usar o padrão): " outfile

    if [[ -n "${outfile}" ]]; then
        bash "${SMB_ENUM_SCRIPT}" -t "${target}" -o "${outfile}"
    else
        bash "${SMB_ENUM_SCRIPT}" -t "${target}"
    fi

    pause_for_user
}

run_smb_menu() {
    local target userlist passlist

    print_banner
    print_section "[ SMB Password Spraying / Brute Force - Medusa ]"
    require_file "${SMB_SCRIPT}"

    target="$(prompt_target 'Alvo (IP ou hostname)')"
    read -r -p "Wordlist de usuários: " userlist
    read -r -p "Wordlist de senhas: " passlist
    require_non_empty "${userlist}" "Wordlist de usuários"
    require_non_empty "${passlist}" "Wordlist de senhas"

    bash "${SMB_SCRIPT}" -t "${target}" -U "${userlist}" -P "${passlist}"
    pause_for_user
}

run_web_menu() {
    local target page_target userlist passlist

    print_banner
    print_section "[ HTTP Form Brute Force - Medusa ]"
    require_file "${WEB_FORM_SCRIPT}"

    target="$(prompt_target 'Alvo (IP ou hostname)')"
    read -r -p "Página alvo (ex: /dvwa/login.php): " page_target
    read -r -p "Wordlist de usuários: " userlist
    read -r -p "Wordlist de senhas: " passlist
    require_non_empty "${page_target}" "Página alvo"
    require_non_empty "${userlist}" "Wordlist de usuários"
    require_non_empty "${passlist}" "Wordlist de senhas"

    bash "${WEB_FORM_SCRIPT}" -l -t "${target}" -U "${userlist}" -P "${passlist}" -r "${page_target}"
    pause_for_user
}

main() {
    local option

    while true; do
        print_menu
        read -r -p "Opção: " option
        printf '\n'

        case "${option}" in
            1) run_ftp_menu ;;
            2) run_smb_enum_menu ;;
            3) run_smb_menu ;;
            4) run_web_menu ;;
            0)
                print_success "Saindo."
                exit 0
                ;;
            *)
                print_warn "Opção inválida."
                sleep 1
                ;;
        esac
    done
}

main "$@"
