# Use a dedicated ssh-agent in WSL and load the private key from the already
# unlocked keyring password helper.
wsl_ssh_private_key="${WSL_SSH_PRIVATE_KEY:-${HOME}/.ssh/id_rsa}"
wsl_ssh_public_key="${wsl_ssh_private_key}.pub"
wsl_ssh_agent_sock="${WSL_SSH_AGENT_SOCK:-${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/ssh-agent.socket}"
wsl_ssh_askpass_helper="${WSL_SSH_ASKPASS_HELPER:-${HOME}/.local/bin/ssh-keyring-askpass}"

if [ -n "${SSH_AUTH_SOCK:-}" ]; then
    ssh-add -l >/dev/null 2>&1
    wsl_ssh_agent_status=$?
    if [ "${wsl_ssh_agent_status}" -eq 2 ]; then
        unset SSH_AUTH_SOCK
    fi
    unset wsl_ssh_agent_status
fi

if [ -z "${SSH_AUTH_SOCK:-}" ]; then
    export SSH_AUTH_SOCK="${wsl_ssh_agent_sock}"
fi

ssh-add -l >/dev/null 2>&1
wsl_ssh_agent_status=$?
if [ "${wsl_ssh_agent_status}" -eq 2 ]; then
    eval "$(ssh-agent -s -a "${wsl_ssh_agent_sock}")" >/dev/null
    export SSH_AUTH_SOCK="${wsl_ssh_agent_sock}"
fi
unset wsl_ssh_agent_status

if [ -f "${wsl_ssh_private_key}" ] && [ -f "${wsl_ssh_public_key}" ] && [ -x "${wsl_ssh_askpass_helper}" ]; then
    if ! ssh-add -L 2>/dev/null | grep -Fqx "$(cat "${wsl_ssh_public_key}")"; then
        DISPLAY="${DISPLAY:-dummy:0}" \
        SSH_ASKPASS="${wsl_ssh_askpass_helper}" \
        SSH_ASKPASS_REQUIRE=force \
        setsid ssh-add "${wsl_ssh_private_key}" </dev/null >/dev/null 2>&1
    fi
fi

unset wsl_ssh_private_key
unset wsl_ssh_public_key
unset wsl_ssh_agent_sock
unset wsl_ssh_askpass_helper
