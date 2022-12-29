[CmdletBinding()]
param (
  [parameter(Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [String]
  $TenantId,

  [parameter(Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [String]
  $SubscriptionId
)

$body = @{
    "deDuplicationId" = "$SubscriptionId"
    "policy" = @{
      "creatorsCriteria" = @(
        @{
          "typeId" = "DF55FFEA-AD97-49FF-A4C9-42D8341A8527"
          "role" = "Writer"
          "subscriptionId" = "$SubscriptionId"
        }
      )
    }
}

$auth=Get-AzAccessToken
$authHeader= $auth.token 
$url = "https://api.accessreviews.identitygovernance.azure.com/accessReviews/v2.0/approvalWorkflowProviders/9FB60D0C-FC64-4DE9-AD80-22C1B531F505/businessFlows?x-tenantid=$TenantId"
$flowId = $null
  $res = Invoke-RestMethod `
      -Method Post `
      -Headers @{"Authorization"="Bearer $authHeader"} `
      -ContentType "application/json; charset=utf-8" `
      -ResponseHeadersVariable respHeaders `
      -StatusCodeVariable statusCode `
      -Body (ConvertTo-Json $body -Depth 10) `
      -Uri $url `
      -SkipHttpErrorCheck
  if($statusCode -eq 409){
    $detailMsg = $res.error.message
    $pattern = '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}'
    $allMatches = ($detailMsg | Select-String -Pattern $pattern -AllMatches)
    $flowId = $allMatches.Matches.Groups[0].Value
  }
  if($statusCode -eq 201){
    $flowId = $res.id
  }
  if(!$flowId){
    Write-Host -ForegroundColor Red "Error with $statusCode and $($res.error)" 
  }
return $flowId