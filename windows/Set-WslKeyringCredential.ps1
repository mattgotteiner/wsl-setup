param(
    [string]$Target = "WSL-GNOME-Keyring",
    [string]$UserName = "wsl"
)

$module = Get-Module -ListAvailable CredentialManager | Select-Object -First 1
if (-not $module) {
    Install-Module CredentialManager -Scope CurrentUser -Force
}

Import-Module CredentialManager

$existing = Get-StoredCredential -Target $Target
if ($existing) {
    Remove-StoredCredential -Target $Target | Out-Null
}

$password = Read-Host -AsSecureString "Enter the passphrase to store for $Target"

New-StoredCredential `
    -Target $Target `
    -UserName $UserName `
    -SecurePassword $password `
    -Persist LocalMachine `
    -Comment "WSL GNOME Keyring / SSH passphrase" | Out-Null

Write-Host "Stored credential for target '$Target'."
