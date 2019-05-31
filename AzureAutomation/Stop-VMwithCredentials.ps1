<#PSScriptInfo
.VERSION 1.0
#>

#Requires -Module Az.Account
#Requires -Module Az.Compute

<#
.SYNOPSIS
  Connects to Azure and stops of all VMs in the specified Azure subscription or resource group

.DESCRIPTION
  Based on Stop-AzureV2Vs (https://github.com/azureautomation/runbooks/blob/master/Utility/Stop-AzureV2VMs.ps1). Uses an Automation Credential
  to connect and to stop the VMs in a Resource Group
#>

# Returns strings with status messages
[OutputType([String])]

param (
    [Parameter(Mandatory=$true)] 
    [String]  $TenantId,
	
    [Parameter(Mandatory=$true)] 
    [String]  $SubscriptionId,

    [Parameter(Mandatory=$true)] 
    [String]  $AzureCredentialName,

    [Parameter(Mandatory=$false)] 
    [String] $ResourceGroupName,

    [Parameter(Mandatory=$false)] 
    [String] $VMName
)

try {
	$Cred = Get-AutomationPSCredential -Name $AzureCredentialName
	$userName = $Cred.UserName
	$securePassword = $Cred.Password
	Write-Output "using user $userName"
	$PsCred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $userName, $securePassword
	Write-Output $myPsCred
	Write-Output "try to connect..."
    Connect-AzAccount -TenantId $TenantId -Subscription $SubscriptionId -Credential $PsCred
    Write-Output "connection succeeded"
    #Write-Output "set subscrioption..."
    #Set-AzContext -SubscriptionId $SubscriptionId -TenantId $TenantId
}
catch {
	Write-Error $_.Exception
    throw $_.Exception
}

# If there is a specific resource group, then get all VMs in the resource group,
# otherwise get all VMs in the subscription.
if ($ResourceGroupName) { 
	$VMs = Get-AzVM -ResourceGroupName $ResourceGroupName
}
else { 
    if ($VMName){
        $VMs = Get-AzVM -Name $VMName
    }else{
	    $VMs = Get-AzVM
    }
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