# Kali Metasploitable Tester

Lightweight shell project for practicing credential testing and user enumeration in a controlled lab with `medusa` and `enum4linux`.

This repository remains a Bash/shell project by design. The goal is to keep the workflow simple, readable, and easy to extend for small security lab scenarios such as Metasploitable 2 and DVWA.

Use only in environments you own or are explicitly authorized to test.

## Structure

```text
.
├── main.sh
├── kali_metasploitable_tester.sh
├── config.sh
├── lib/
│   ├── common.sh
│   ├── executor.sh
│   ├── parser.sh
│   └── reporting.sh
├── scripts/
│   ├── ftp_protocol.sh
│   ├── smb_enum_user.sh
│   ├── smb_protocol.sh
│   └── webform_protocol.sh
├── docs/
└── wordlists/
```

## What Changed

The project was refactored to separate responsibilities more clearly:

- `config.sh`: shared paths, defaults, colors, and constants
- `lib/common.sh`: validation, error handling, logging helpers, directory helpers
- `lib/executor.sh`: command printing, command execution, connectivity checks
- `lib/parser.sh`: result extraction from `enum4linux` and `medusa` output
- `lib/reporting.sh`: banners and summaries
- `main.sh`: clean interactive entrypoint
- `kali_metasploitable_tester.sh`: compatibility wrapper that forwards to `main.sh`

Each protocol script still exists as a standalone shell script, but now uses the shared library functions instead of duplicating logic.

## Requirements

- `bash`
- `medusa`
- `enum4linux` for SMB enumeration
- `nc` is optional for the FTP connectivity check

Typical lab targets:

- Metasploitable 2
- DVWA
- Other intentionally vulnerable lab systems

## Usage

Run the interactive menu:

```bash
./main.sh
```

Backward-compatible entrypoint:

```bash
./kali_metasploitable_tester.sh
```

Run protocol scripts directly if needed:

```bash
./scripts/ftp_protocol.sh -s -t 192.168.56.101 -u admin -P wordlists/passwords.txt
./scripts/ftp_protocol.sh -l -t 192.168.56.101 -U docs/users.txt -P docs/pass.txt
./scripts/smb_protocol.sh -t 192.168.56.101 -U docs/users.txt -P docs/pass.txt
./scripts/smb_enum_user.sh -t 192.168.56.101
./scripts/webform_protocol.sh -l -t 192.168.56.101 -U docs/users.txt -P docs/pass.txt -r /dvwa/login.php
```

## Output

Generated logs go to `logs/` by default.

Examples:

- FTP: session directory with full log and extracted credential hits
- SMB: log file plus extracted result lines
- Web form: log file plus extracted result lines
- SMB enumeration: raw `enum4linux` output plus extracted user list

## Notes

- The refactor keeps the core workflow intact: prompt for target, run the selected tool, save output, show a summary.
- Result extraction is based on common `medusa` success markers such as `ACCOUNT FOUND` and `SUCCESS`.
- The previous FTP script wrote a hardcoded fake credential into the results file. That behavior was removed as a correctness fix; results are now derived from actual command output.

## Follow-Up Ideas

- Add `shellcheck` and a tiny `test` target for syntax validation.
- Standardize language across messages if you want the UI fully in Portuguese or fully in English.
- Add optional defaults for bundled wordlists in `wordlists/`.
- Add a non-interactive mode in `main.sh` for automation.

## Ethics

This project is for educational and lab use only. Do not use it against systems without explicit authorization.
