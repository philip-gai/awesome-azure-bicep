[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
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

$templateParameterFile = "$PSScriptRoot/$Resource/main.parameters.json"
if (-not (Test-Path $templateParameterFile)) {
    throw "Template parameter file '$templateParameterFile' does not exist"
}

Write-Host "Deploying ARM template '$templateFile' with parameters '$templateParameterFile'"


$deploymentName = "$Resource-$(Get-Date -Format "yyyyMMddHHmmss")"
$params = @{
    Name                  = $deploymentName
    ResourceGroupName     = $ResourceGroup
    TemplateFile          = $templateFile
    TemplateParameterFile = $templateParameterFile
}
$params = $params + $TemplateParameterObject

# Log the parameters
Write-Host "Deployment parameters:"
$params.GetEnumerator() | ForEach-Object { Write-Host "$($_.Key) = $($_.Value)" }

New-AzResourceGroupDeployment @params
