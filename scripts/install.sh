#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
config_root="${HOME}/.config/wsl-setup"
bin_root="${HOME}/.local/bin"
profile_target="${config_root}/profile.d/gnome-keyring-wsl.sh"
bashrc_target="${config_root}/bashrc.d/ssh-agent-keyring.sh"

mkdir -p "${bin_root}" "${config_root}/profile.d" "${config_root}/bashrc.d"

install -m 700 "${repo_root}/scripts/bin/wsl-keyring-password" "${bin_root}/wsl-keyring-password"
install -m 700 "${repo_root}/scripts/bin/ssh-keyring-askpass" "${bin_root}/ssh-keyring-askpass"
install -m 644 "${repo_root}/shell/profile.d/gnome-keyring-wsl.sh" "${profile_target}"
install -m 644 "${repo_root}/shell/bashrc.d/ssh-agent-keyring.sh" "${bashrc_target}"

ensure_source_line() {
    local file="$1"
    local line="$2"

    touch "${file}"
    if ! grep -Fqx "${line}" "${file}"; then
        printf '\n%s\n' "${line}" >> "${file}"
    fi
}

ensure_source_line "${HOME}/.profile" '[ -f "$HOME/.config/wsl-setup/profile.d/gnome-keyring-wsl.sh" ] && . "$HOME/.config/wsl-setup/profile.d/gnome-keyring-wsl.sh"'
ensure_source_line "${HOME}/.bashrc" '[ -f "$HOME/.config/wsl-setup/bashrc.d/ssh-agent-keyring.sh" ] && . "$HOME/.config/wsl-setup/bashrc.d/ssh-agent-keyring.sh"'

cat <<EOF
Installed WSL SSH/keyring setup assets.

Next steps:
  1. Store the passphrase in Windows Credential Manager:
     powershell.exe -ExecutionPolicy Bypass -File "${repo_root}/windows/Set-WslKeyringCredential.ps1"
  2. Start a fresh login shell:
     exec bash -l
  3. Verify:
     ${repo_root}/scripts/verify.sh
EOF
