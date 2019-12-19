#Requires -Module Az.Account
#Requires -Module Az.Network
#Requires -Module Az.Monitor

[OutputType([String])]

param (
    [Parameter(Mandatory=$false)] 
    [String]  $AzureConnectionAssetName = "AzureRunAsConnection",

    [Parameter(Mandatory=$true)] 
    [String] $ResourceGroupName,

    [Parameter(Mandatory=$true)] 
    [String] $VpnGwName

)

Write-Output "start resetting VPN..."

try {
    # Connect to Azure using service principal auth
    $ServicePrincipalConnection = Get-AutomationConnection -Name $AzureConnectionAssetName         
    Write-Output $ServicePrincipalConnection
    Write-Output "Logging in to Azure..."
    #$Null = Add-AzAccount -ServicePrincipal -TenantId $ServicePrincipalConnection.TenantId -ApplicationId $ServicePrincipalConnection.ApplicationId -CertificateThumbprint $ServicePrincipalConnection.CertificateThumbprint
    $Null = Connect-AzAccount -ServicePrincipal -TenantId $ServicePrincipalConnection.TenantId -ApplicationId $ServicePrincipalConnection.ApplicationId -CertificateThumbprint $ServicePrincipalConnection.CertificateThumbprint
    Write-Output "Logged in to Azure..."
}catch {
    if(!$ServicePrincipalConnection) {
        throw "Connection $AzureConnectionAssetName not found."
    } else {
        throw $_.Exception
    }
}

$subid = $ServicePrincipalConnection.SubscriptionId
$resourceid = "/subscriptions/$subid/resourceGroups/$ResourceGroupName/providers/Microsoft.Network/virtualNetworkGateways/$VpnGwName";
#Write-Output $resourceid
Write-Output "Getting Logs for $resourceid"
$logs = Get-AzLog -ResourceId $resourceid -StartTime (Get-Date).AddHours(-1)

if($logs.Count -ge 1 -and $logs[0].OperationName.value -eq "Microsoft.Network/virtualNetworkGateways/reset/action" -and $logs[0].Status.value -eq "Accepted")
{
    Write-Output "Gateway is currently resetting..."    
}
else
{
    # no log entry since an hour,
    # or last log entry was something else
    # or last log entry with reset was "failed" or "succeded"
    Write-Output "Get Gateway..."
    $gw = Get-AzVirtualNetworkGateway -Name $VpnGwName -ResourceGroupName $ResourceGroupName
    Write-Output "Reset Gateway..."
    Reset-AzVirtualNetworkGateway -VirtualNetworkGateway $gw
}

Write-Output "...finished"