#!/bin/bash
# kali_metaexplot_tester - SMB user enumeration helper
# Uso: bash smb_enum_user.sh -t 192.168.56.101

usage() {
    cat <<EOF
[ Enumerar usuários SMB com enum4linux ]

Uso:
  $0 -t <TARGET> [-o <ARQUIVO_SAIDA>]

Opções:
  -t    IP ou hostname do alvo (TARGET) [obrigatório]
  -o    Arquivo de saída para a lista de usuários (default: users_<TARGET>.txt)
  -h    Mostra esta ajuda

Este script:
  1) Roda: enum4linux -a <TARGET>
  2) Salva a saída completa em: enum4linux_<TARGET>.raw
  3) Extrai possíveis usuários para: users_<TARGET>.txt (ou arquivo definido em -o)
EOF
}

TARGET=""
OUTFILE=""

while getopts ":t:o:h" opt; do
    case "$opt" in
        t)
            TARGET="$OPTARG"
            ;;
        o)
            OUTFILE="$OPTARG"
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

# Definir nome padrão de saída se não informado
if [ -z "$OUTFILE" ]; then
    OUTFILE="users_${TARGET}.txt"
fi

RAW_OUT="enum4linux_${TARGET}.raw"

# --- Checar se enum4linux existe ---
if ! command -v enum4linux >/dev/null 2>&1; then
    echo "[!] enum4linux não encontrado no sistema."
    echo "    Instale com algo como:"
    echo "    sudo apt install enum4linux"
    exit 1
fi

echo "[*] Rodando enum4linux contra: $TARGET"
echo "[*] Salvando saída completa em: $RAW_OUT"
echo

# Salva saída completa num arquivo
enum4linux -a "$TARGET" | tee "$RAW_OUT"

echo
echo "[*] Extraindo possíveis usuários da saída..."

# Padrão comum do enum4linux: linhas com 'user:[nome]'
grep -E "user:\[" "$RAW_OUT" 2>/dev/null \
    | sed -E 's/.*user:\[([^]]+)\].*/\1/' \
    | sort -u > "$OUTFILE"

if [ -s "$OUTFILE" ]; then
    echo "[+] Lista de usuários gerada em: $OUTFILE"
    echo "[+] Você pode usar este arquivo com o script de SMB, por exemplo:"
    echo "    bash smb_bruteforce.sh -t $TARGET -U $OUTFILE -P passwords.txt"
else
    echo "[!] Não foi possível extrair usuários automaticamente."
    echo "    Verifique manualmente o arquivo: $RAW_OUT"
fi
