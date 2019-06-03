<#PSScriptInfo
.VERSION 1.0
#>

#Requires -Module Az.Account
#Requires -Module Az.Compute

<#
.SYNOPSIS
  Connects to Azure and stops of all VMs in the specified Azure subscription or resource group on given weekdays

.DESCRIPTION
  Based on Stop-AzureV2Vs (https://github.com/azureautomation/runbooks/blob/master/Utility/Stop-AzureV2VMs.ps1).
#>

# Returns strings with status messages
[OutputType([String])]

param (
    [Parameter(Mandatory=$false)] 
    [String]  $AzureConnectionAssetName = "AzureRunAsConnection",

    [Parameter(Mandatory=$false)] 
    [String] $ResourceGroupName,
	
    [Parameter(Mandatory=$false)] 
    [String]  $Weekdays = "Monday, Tuesday, Wednesday, Thursday, Friday, Saturday, Sunday"
)

Write-Output "checking weekday:"
$now = Get-Date
$weekday = $now.DayOfWeek
Write-Output "today is $weekday"
If (-Not ($Weekdays -like -join("*",$weekday,"*")))
{
	Write-Output "stop, not the requested weekday"
	return
}
Write-Output "start... (weekday check passed)"

try {
    # Connect to Azure using service principal auth
    $ServicePrincipalConnection = Get-AutomationConnection -Name $AzureConnectionAssetName         

    Write-Output "Logging in to Azure..."

    $Null = Add-AzAccount `
        -ServicePrincipal `
        -TenantId $ServicePrincipalConnection.TenantId `
        -ApplicationId $ServicePrincipalConnection.ApplicationId `
        -CertificateThumbprint $ServicePrincipalConnection.CertificateThumbprint 
}
catch {
    if(!$ServicePrincipalConnection) {
        throw "Connection $AzureConnectionAssetName not found."
    }
    else {
        throw $_.Exception
    }
}

if ($ResourceGroupName) { 
	$VMs = Get-AzVM -ResourceGroupName $ResourceGroupName
}
else { 
    $VMs = Get-AzVM
}

# Start each of the VMs
foreach ($VM in $VMs) {
	$StopRtn = $VM | Stop-AzVM -Force -ErrorAction Continue

	if ($StopRtn.Status -ne "Succeeded") {
		# The VM failed to stop, so send notice
        Write-Output ($VM.Name + " failed to stop")
        Write-Error ($VM.Name + " failed to stop. Error was:") -ErrorAction Continue
		Write-Error (ConvertTo-Json $StopRtn) -ErrorAction Continue
	}
	else {
		# The VM stoped, so send notice
		Write-Output ($VM.Name + " has been stoped")
	}
}