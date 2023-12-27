[CmdletBinding()]
param (
  [parameter(Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [String]
  $PolicySetJsonUrl
)

Write-Host "Getting PolicySet..."
$set = Invoke-WebRequest $PolicySetJsonUrl
$jsonset = $set.Content | ConvertFrom-Json -Depth 20
$neededPolicies = $jsonset.properties.policyDefinitions.policyDefinitionId.Replace('${root_scope_resource_id}', '')
Write-Host "Found $($neededPolicies.Count) Policies in PolicySet"

Write-Host -NoNewline "Determine installed Policies in Tenant and Subscriptions..."
$installedPolicies = ./Get-AzGraphResult.ps1 -Query 'policyresources | where type == "microsoft.authorization/policydefinitions" or type == "microsoft.authorization/policysetdefinitions"'
$installedPolicies = $installedPolicies.id
Write-Host "$($installedPolicies.Count)"

$missingPolicies = $neededPolicies | ?{-not ($installedPolicies -match $_)}
Write-Host "Found $($missingPolicies.Count) not installed Policies that are needed in PolicySet"
if($missingPolicies.Count -eq 0){
  exit
}

Write-Host "Downloading missing Policies from GitHub..."
$gitresp = Invoke-WebRequest https://api.github.com/repos/Azure/terraform-azurerm-caf-enterprise-scale/git/trees/main?recursive=1
$gitfiles = ($gitresp.Content | ConvertFrom-Json -Depth 20).tree
$gitpolicies = $gitfiles | ? {$_.path.contains("/lib/policy_definitions/")}
$gitpolicies | % {
  $url = $_.path
  $resp = Invoke-WebRequest "https://raw.githubusercontent.com/Azure/terraform-azurerm-caf-enterprise-scale/main/$url"
  $plcy = $resp.Content
  $plcyObj = $plcy | ConvertFrom-Json -Depth 20
  Write-Host "$($plcyObj.Name)..." -ForegroundColor Gray -NoNewline
  if($missingPolicies -match $plcyObj.Name){
    Write-Host -ForegroundColor Green "INSTALLING"
    $plcyDef = New-AzPolicyDefinition -Name ($plcy | ConvertFrom-Json).Name -Policy $plcy
  }else{
    Write-Host -ForegroundColor Yellow "SKIP"
  }
}