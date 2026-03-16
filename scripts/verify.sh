#!/usr/bin/env bash
set -euo pipefail

status=0

check_command() {
    local name="$1"
    if command -v "${name}" >/dev/null 2>&1; then
        printf '[ok] command available: %s\n' "${name}"
    else
        printf '[missing] command not found: %s\n' "${name}"
        status=1
    fi
}

check_file() {
    local path="$1"
    if [ -f "${path}" ]; then
        printf '[ok] file exists: %s\n' "${path}"
    else
        printf '[missing] file not found: %s\n' "${path}"
        status=1
    fi
}

check_command gnome-keyring-daemon
check_command ssh-agent
check_command ssh-add
check_command powershell.exe
check_command wsl-keyring-password
check_command ssh-keyring-askpass

check_file "${HOME}/.config/wsl-setup/profile.d/gnome-keyring-wsl.sh"
check_file "${HOME}/.config/wsl-setup/bashrc.d/ssh-agent-keyring.sh"

if grep -Fq '.config/wsl-setup/profile.d/gnome-keyring-wsl.sh' "${HOME}/.profile" 2>/dev/null; then
    printf '[ok] ~/.profile sources the installed keyring snippet\n'
else
    printf '[missing] ~/.profile does not source the installed keyring snippet\n'
    status=1
fi

if grep -Fq '.config/wsl-setup/bashrc.d/ssh-agent-keyring.sh' "${HOME}/.bashrc" 2>/dev/null; then
    printf '[ok] ~/.bashrc sources the installed SSH snippet\n'
else
    printf '[missing] ~/.bashrc does not source the installed SSH snippet\n'
    status=1
fi

if command -v powershell.exe >/dev/null 2>&1; then
    if powershell.exe -NoProfile -Command 'Import-Module CredentialManager -ErrorAction Stop; $cred = Get-StoredCredential -Target "${env:WSL_KEYRING_CRED_TARGET}"; if (-not $cred) { $cred = Get-StoredCredential -Target "WSL-GNOME-Keyring" }; if ($cred) { exit 0 } else { exit 1 }' >/dev/null 2>&1; then
        printf '[ok] Windows credential entry is available\n'
    else
        printf '[missing] Windows credential entry or CredentialManager module is unavailable\n'
        status=1
    fi
fi

if ssh-add -l >/dev/null 2>&1; then
    printf '[ok] ssh-agent is reachable via SSH_AUTH_SOCK=%s\n' "${SSH_AUTH_SOCK:-unset}"
else
    ssh_status=$?
    if [ "${ssh_status}" -eq 2 ]; then
        printf '[missing] ssh-agent is not reachable via SSH_AUTH_SOCK=%s\n' "${SSH_AUTH_SOCK:-unset}"
    else
        printf '[warn] ssh-agent is reachable, but no identities are currently loaded\n'
    fi
fi

exit "${status}"
