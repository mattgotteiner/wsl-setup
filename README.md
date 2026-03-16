# WSL SSH/keyring auto-unlock setup

This repository captures the current WSL shell setup that:

- unlocks the GNOME Keyring secrets store from a Windows Credential Manager entry during login shell startup
- starts or reuses a dedicated WSL `ssh-agent`
- auto-loads an SSH private key into that agent by using the stored keyring secret through an `SSH_ASKPASS` helper

The goal is to make the setup easy to reproduce on a new machine without copying secrets or manually retyping shell snippets.

## What gets installed

`./scripts/install.sh` installs:

- `~/.local/bin/wsl-keyring-password`
- `~/.local/bin/ssh-keyring-askpass`
- `~/.config/wsl-setup/profile.d/gnome-keyring-wsl.sh`
- `~/.config/wsl-setup/bashrc.d/ssh-agent-keyring.sh`

It also adds idempotent source lines to:

- `~/.profile`
- `~/.bashrc`

## Prerequisites

Inside WSL, install:

```bash
sudo apt update
sudo apt install -y gnome-keyring openssh-client
```

On Windows, the setup expects:

- `powershell.exe` to be available from WSL
- the PowerShell `CredentialManager` module
- a stored credential target that contains the passphrase used for your keyring and SSH key

## Fresh-machine setup

Clone this repo, then from the repo root:

```bash
./scripts/install.sh
```

Register or update the Windows credential entry:

```bash
powershell.exe -ExecutionPolicy Bypass -File "$PWD/windows/Set-WslKeyringCredential.ps1"
```

The default credential target is `WSL-GNOME-Keyring`.

Start a fresh login shell after installation:

```bash
exec bash -l
```

Then verify the setup:

```bash
./scripts/verify.sh
```

## How it works

Login shells read `~/.profile`, which sources the installed GNOME Keyring snippet. That snippet:

1. checks whether `gnome-keyring-daemon` is available
2. reads a passphrase from Windows Credential Manager by calling `wsl-keyring-password`
3. unlocks the GNOME Keyring secrets component with `gnome-keyring-daemon --unlock`
4. exports the environment variables returned by the daemon

Interactive shells read `~/.bashrc`, which sources the SSH agent snippet. That snippet:

1. uses a dedicated socket path for `ssh-agent`
2. drops a stale `SSH_AUTH_SOCK` if the referenced agent is dead
3. starts `ssh-agent` when needed
4. uses `ssh-keyring-askpass` to feed the stored passphrase to `ssh-add`
5. only adds the key if its public key is not already present in the agent

## Customization

These environment variables can be overridden before the snippets run:

- `WSL_KEYRING_CRED_TARGET` defaults to `WSL-GNOME-Keyring`
- `WSL_SSH_PRIVATE_KEY` defaults to `~/.ssh/id_rsa`
- `WSL_SSH_AGENT_SOCK` defaults to `${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/ssh-agent.socket`
- `WSL_SSH_ASKPASS_HELPER` defaults to `~/.local/bin/ssh-keyring-askpass`

Example:

```bash
export WSL_SSH_PRIVATE_KEY="$HOME/.ssh/id_ed25519"
export WSL_KEYRING_CRED_TARGET="My-WSL-SSH-Key"
```

Put those exports above the sourced snippet in your shell config if you want them to persist.

## Files in this repo

- `scripts/install.sh` installs the repo-managed assets into your home directory
- `scripts/verify.sh` checks that the dependencies and runtime state look healthy
- `scripts/bin/` contains the helper binaries installed into `~/.local/bin`
- `shell/` contains the shell snippets installed into `~/.config/wsl-setup`
- `windows/Set-WslKeyringCredential.ps1` creates or updates the Windows credential entry

## Security notes

- This repo stores only automation and documentation, not private keys or passphrases.
- The Windows credential entry should contain only the passphrase needed to unlock the keyring and SSH key.
- Review the installed shell snippets before using them on another machine.
