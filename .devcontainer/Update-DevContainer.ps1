$ErrorActionPreference = "Stop"

Write-Host "Installing Az Powershell modules"
Install-Module -Name Az -Scope CurrentUser -Repository PSGallery -Force
