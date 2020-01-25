<#PSScriptInfo
.VERSION 1.0
#>

#Requires -Module Az.Account
#Requires -Module Az.Compute

<#
.SYNOPSIS
  Connects to Azure and starts of all VMs in the specified Azure subscription or resource group on given weekdays

.DESCRIPTION
  Based on Start-AzureV2Vs (https://github.com/azureautomation/runbooks/blob/master/Utility/Start-AzureV2VMs.ps1).

.PARAMETER Sequence    
  A sequence of VM names of a resource group and waiting times in seconds. The informations are separated with commas.
  Example: vm1, vm2, 60, vm3
  This starts vm1, then vm2, then waiting 1 minute and afterward will vm3 be started.

#>

# Returns strings with status messages
[OutputType([String])]

param (
    [Parameter(Mandatory=$false)] 
    [String]  $AzureConnectionAssetName = "AzureRunAsConnection",

    [Parameter(Mandatory=$true)] 
    [String] $ResourceGroupName,
	
    [Parameter(Mandatory=$true)] 
    [String]  $Sequence
)

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

$elems = $Sequence.Split(",")
foreach($elem in $elems){
    $elem = $elem.Trim()
    [int]$seconds = 0
    [bool]$result = [int]::TryParse($elem, [ref]$seconds)
    if($result -eq $true)
    {
        Write-Output "Sleeping $seconds ..."
        Start-Sleep $seconds
    }else
    {
        Write-Host "Starting VM: $elem"
		$VM = Get-AzVM -ResourceGroupName $ResourceGroupName -Name $elem
		$StartRtn = $VM | Start-AzVM -ErrorAction Continue

		if ($StartRtn.Status -ne "Succeeded") {
			# The VM failed to start, so send notice
			Write-Output ($VM.Name + " failed to start")
			Write-Error ($VM.Name + " failed to start. Error was:") -ErrorAction Continue
			Write-Error (ConvertTo-Json $StartRtn) -ErrorAction Continue
		}
		else {
			# The VM started, so send notice
			Write-Output ($VM.Name + " has been started")
		}
    }
}