[CmdletBinding()]
param (
  [parameter(Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [String]
  $SubscriptionId
)

Write-Host -NoNewline "Checking and Registering AvailabilityZonePeering-Feature at $SubscriptionId..." 
Select-AzSubscription $SubscriptionId | Out-Null
$featureStatus = Get-AzProviderFeature -ProviderNamespace "Microsoft.Resources" -FeatureName "AvailabilityZonePeering"
if($featureStatus.RegistrationState -eq "Registered"){
  Write-Host "already registered"
  exit
}
if($featureStatus.RegistrationState -eq "NotRegistered"){
  Register-AzProviderFeature -ProviderNamespace "Microsoft.Resources" -FeatureName "AvailabilityZonePeering" | Out-Null
  $runs = 0
  do{
    Write-Host -NoNewline "."
    Start-Sleep -Seconds (15)
    $featureStatus = Get-AzProviderFeature -ProviderNamespace "Microsoft.Resources" -FeatureName "AvailabilityZonePeering"
    $state = $featureStatus.RegistrationState
    $runs++
  }while($state -ne "Registered" -and $runs -lt 20)
  Write-Host -ForegroundColor Green "now registered" 
  exit
}
Write-Host -ForegroundColor Red "Error $($featureStatus.RegistrationState)" 