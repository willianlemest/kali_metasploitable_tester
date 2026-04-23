#!/usr/bin/env bash

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="${PROJECT_ROOT}/scripts"
LIB_DIR="${PROJECT_ROOT}/lib"
DOCS_DIR="${PROJECT_ROOT}/docs"
WORDLISTS_DIR="${PROJECT_ROOT}/wordlists"
LOGS_DIR="${PROJECT_ROOT}/logs"

DEFAULT_THREADS=6
DEFAULT_FTP_PORT=21
DEFAULT_HTTP_PORT=80
DEFAULT_HTTP_FORM='username=^USER^&password=^PASS^&Login=Login'
DEFAULT_HTTP_FAIL='FAIL:Login failed'

if [[ -t 1 ]]; then
    RESET=$'\033[0m'
    BOLD=$'\033[1m'
    DIM=$'\033[2m'
    RED=$'\033[31m'
    GREEN=$'\033[32m'
    YELLOW=$'\033[33m'
    BLUE=$'\033[34m'
    MAGENTA=$'\033[35m'
    CYAN=$'\033[36m'
else
    RESET=""
    BOLD=""
    DIM=""
    RED=""
    GREEN=""
    YELLOW=""
    BLUE=""
    MAGENTA=""
    CYAN=""
fi

INFO_PREFIX="${CYAN}[i]${RESET}"
WARN_PREFIX="${YELLOW}[!]${RESET}"
ERROR_PREFIX="${RED}[x]${RESET}"
OK_PREFIX="${GREEN}[ok]${RESET}"
