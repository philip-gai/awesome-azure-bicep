[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$Resource,
    [Parameter(Mandatory = $false)]
    [string]$Subscription,
    [Parameter(Mandatory = $false)]
    [string]$ResourceGroup = "awesome-azure-bicep",
    [Parameter(Mandatory = $false)]
    [string]$Location = "centralus",
    [Parameter(Mandatory = $false)]
    [hashtable]$TemplateParameterObject = @{}
)

$ErrorActionPreference = "Stop"

# Make sure the folder exists
if (-not (Test-Path $Resource)) {
    throw "Resource folder '$Resource' does not exist"
}

Write-Host "Deploying resources from '$Resource' to resource group '$ResourceGroup'"

if ($Subscription) {
    Write-Host "Setting subscription to '$Subscription'"
    Set-AzContext -Subscription $Subscription
}

# Create the resource group if it doesn't exist
if (-not (Get-AzResourceGroup -Name $ResourceGroup -ErrorAction SilentlyContinue)) {
    Write-Host "Creating resource group '$ResourceGroup'"
    New-AzResourceGroup -Name $ResourceGroup -Location $Location
}
else {
    Write-Host "Using existing resource group '$ResourceGroup'"
}

# Deploy the ARM template
$templateFile = "$PSScriptRoot/$Resource/main.bicep"
if (-not (Test-Path $templateFile)) {
    throw "Template file '$templateFile' does not exist"
}

$deploymentName = "$Resource-$(Get-Date -Format "yyyyMMddHHmmss")"
$params = @{
    Name                  = $deploymentName
    ResourceGroupName     = $ResourceGroup
    TemplateFile          = $templateFile
}
$params = $params + $TemplateParameterObject

$templateParameterFile = "$PSScriptRoot/$Resource/main.parameters.json"
if (Test-Path $templateParameterFile) {
    Write-Host "Using template parameter file '$templateParameterFile'"
    $params.TemplateParameterFile = $templateParameterFile
}

# Log the parameters
Write-Host "Deployment parameters:"
$params.GetEnumerator() | ForEach-Object { Write-Host "$($_.Key) = $($_.Value)" }

Write-Host "Starting deployment"
New-AzResourceGroupDeployment @params
Write-Host "Deployment complete"
