<#PSScriptInfo
.VERSION 1.2
.GUID 935665dd-8ead-431d-8697-7863edb1f6ec
.AUTHOR Thomas Zuehlke
.COMPANYNAME
.COPYRIGHT
.TAGS AzureAutomation VirtualMachines Utility Stop Sequence
.LICENSEURI
.PROJECTURI https://www.thomas-zuehlke.de/2020/01/start-stop-vms-in-sequence-and-with-delay-via-azure-automation/
.ICONURI
.EXTERNALMODULEDEPENDENCIES
   Az.Account
   Az.Compute
.REQUIREDSCRIPTS
.EXTERNALSCRIPTDEPENDENCIES
.RELEASENOTES
#>

#Requires -Module Az.Account
#Requires -Module Az.Compute

<#
.SYNOPSIS
   Connects to Azure and stops specified VMs in a sequence and including a wait time between the VMs.

.DESCRIPTION
   Connects to Azure and stops specified VMs in a sequence and including a wait time between the VMs. It is based on Stop-AzureV2VMs.
   If you provide the sequence "vm4, 30, vm3, 60, vm2, vm1", then VM4 stops first, then it waits 30 seconds before VM3 stops, then waits again for 60 seconds, then VM2 stops and finally VM4 stops.

.PARAMETER AzureConnectionAssetName
   Optional with default of "AzureRunAsConnection".
   The name of an Automation connection asset that contains an Azure AD service principal with authorization for the subscription
   you want to start VMs in. To use an asset with a different name you can pass the asset name as a runbook input parameter or change
   the default value for this input parameter.

.PARAMETER ResourceGroupName
   Mandatory
   All VMs in the sequence list, must be located in this resource group.

.PARAMETER Sequence
   Mandatory
   A sequence of VM names of a resource group and waiting times in seconds. The informations are separated with commas.
   Example: vm1, vm2, 60, vm3
   This stops vm1, then vm2, then waiting 1 minute and afterwards vm3 will be stopped.

.NOTES
   AUTHOR: Thomas Zuehlke 
   LASTEDIT: Januar, 2020
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
        Write-Host "Stopping VM: $elem"
		$VM = Get-AzVM -ResourceGroupName $ResourceGroupName -Name $elem
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
}