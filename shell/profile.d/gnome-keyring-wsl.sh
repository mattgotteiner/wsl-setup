# Auto-unlock the GNOME Keyring secrets store for WSL login shells using
# Windows Credential Manager.
if command -v gnome-keyring-daemon >/dev/null 2>&1; then
    wsl_keyring_cred_target="${WSL_KEYRING_CRED_TARGET:-WSL-GNOME-Keyring}"
    if [ -z "${GNOME_KEYRING_CONTROL:-}" ] || ! pgrep -u "$USER" -x gnome-keyring-daemon >/dev/null 2>&1; then
        keyring_pass=""
        keyring_env=""
        if command -v wsl-keyring-password >/dev/null 2>&1; then
            keyring_pass="$(wsl-keyring-password "${wsl_keyring_cred_target}" 2>/dev/null || true)"
        fi
        if [ -n "${keyring_pass}" ]; then
            keyring_env="$(printf '%s' "${keyring_pass}" | gnome-keyring-daemon --unlock --components=secrets)"
        fi
        if [ -n "${keyring_env}" ]; then
            eval "${keyring_env}"
        fi
        unset keyring_pass
        unset keyring_env
    fi
    unset wsl_keyring_cred_target
fi
