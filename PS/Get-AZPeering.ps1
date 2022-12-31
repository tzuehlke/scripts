[CmdletBinding()]
param (
  [parameter(Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [String]
  $SubscriptionId1,

  [parameter(Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [String]
  $SubscriptionId2,

  [parameter(Mandatory = $false)]
  [ValidateNotNullOrEmpty()]
  [String]
  $Location = "westeurope"
)

$body = @{
    "location" = "$Location"
    "subscriptionIds" = @(
      "subscriptions/$SubscriptionId2" 
    )
}

.\Register-AvailabilityZonePeeringFeature -SubscriptionId $SubscriptionId1

$auth=Get-AzAccessToken
$authHeader= $auth.token 
$url = "https://management.azure.com/subscriptions/$SubscriptionId1/providers/Microsoft.Resources/checkZonePeers/?api-version=2020-01-01"
$res = Invoke-RestMethod `
    -Method Post `
    -Headers @{"Authorization"="Bearer $authHeader"} `
    -ContentType "application/json; charset=utf-8" `
    -ResponseHeadersVariable respHeaders `
    -StatusCodeVariable statusCode `
    -Body (ConvertTo-Json $body -Depth 10) `
    -Uri $url `
    -SkipHttpErrorCheck
if($statusCode -eq 200){
  $azinfo = @()
  $res.availabilityZonePeers | % {
    $azinfo += [pscustomobject] [ordered] @{
      Subscription1 = $res.subscriptionId
      Subscription1AZ = $_.availabilityZone
      Location = $res.location
      Subscription2 = $_.peers.subscriptionId
      Subscription2AZ = $_.peers.availabilityZone
    }
  }
  return ($azinfo | Format-Table)
}
Write-Host -ForegroundColor Red "Error: $($res.error.message)"
return $res.error
