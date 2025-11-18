#!/bin/bash
# kali_metaexplot_tester - SMB user enumeration helper
# Uso: ./smb_enum_users.sh -t 192.168.56.101

usage() {
    cat <<EOF
[ Enumerar usuários SMB com enum4linux ]

Uso:
  $0 -t <TARGET>

Opções:
  -t    IP ou hostname do alvo (TARGET)
  -h    Mostra esta ajuda

Exemplo:
  $0 -t 192.168.56.101

Este script é um wrapper simples para:
  enum4linux -a <TARGET> | tee output.txt
EOF
}

# --- Parse de argumentos ---
TARGET=""

while getopts ":t:h" opt; do
    case "$opt" in
        t)
            TARGET="$OPTARG"
            ;;
        h)
            usage
            exit 0
            ;;
        \?)
            echo "[!] Opção inválida: -$OPTARG" >&2
            usage
            exit 1
            ;;
        :)
            echo "[!] A opção -$OPTARG requer um valor." >&2
            usage
            exit 1
            ;;
    esac
done

if [ -z "$TARGET" ]; then
    echo "[!] TARGET não informado."
    usage
    exit 1
fi

# --- Checar se enum4linux existe ---
if ! command -v enum4linux >/dev/null 2>&1; then
    echo "[!] enum4linux não encontrado no sistema."
    echo "    Instale com algo como:"
    echo "    sudo apt install enum4linux"
    exit 1
fi

# --- Execução ---
echo "[*] Rodando enum4linux contra: $TARGET"
echo "[*] Comando: enum4linux -a $TARGET | tee output.txt"
echo

enum4linux -a "$TARGET" | tee output.txt

echo
echo "[+] Enumeração concluída."
echo "[+] Resultado salvo em: ./output.txt"
