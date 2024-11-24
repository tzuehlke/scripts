[CmdletBinding()]
param (
  [parameter(Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [String]
  $SubscriptionId,

  [parameter(Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [String]
  $alertRuleName,

  [parameter(Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [String]
  $alertRuleActionGroupId,

  [parameter(Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [String]
  $alertRuleRegion,

  [parameter(Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [String]
  $alertRuleResourceGroup,

  [parameter(Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [String]
  $logSearchQuery
)

$scope = "/subscriptions/$SubscriptionId"
Set-AzContext -Subscription $SubscriptionId  | Out-Null
$query = $logSearchQuery
$body = @{
  "location"=$alertRuleRegion
  "identity"=@{"type"="systemassigned"}
  "properties"=@{
    "displayName"=$alertRuleName
    "actions"=@{
      "actionGroups"=@($alertRuleActionGroupId)
      "customProperties"=@{}
      "actionProperties"=@{}
    }
    "criteria"=@{
      "allOf"=@(@{
        "operator"="GreaterThanOrEqual"
        "query"=$query
        "threshold"=1
        "timeAggregation"="Count"
        "failingPeriods"=@{
          "minFailingPeriodsToAlert"=1
          "numberOfEvaluationPeriods"=1
        }
      })
    }
    "description"=""
    "enabled"=$true
    "autoMitigate"=$false
    "evaluationFrequency"="PT15M"
    "scopes"=@($scope)
    "severity"=1
    "windowSize"="PT15M"
  }
}

$auth=Get-AzAccessToken
$authHeader= $auth.token 
$url = "https://management.azure.com/$scope/resourceGroups/$alertRuleResourceGroup/providers/microsoft.insights/scheduledqueryrules/$alertRuleName" + "?api-version=2023-03-15-preview"
$result = Invoke-RestMethod `
  -Method Put `
  -Headers @{"Authorization"="Bearer $authHeader"} `
  -ContentType "application/json; charset=utf-8" `
  -Body (ConvertTo-Json $body -Depth 10) `
  -Uri $url
$identity = $result.identity.principalId
Write-Output "Rule Created, Assigning System Idenity $identity to Alert Rule"
Start-Sleep -Seconds (15)
New-AzRoleAssignment -Scope $scope -ObjectId $identity -RoleDefinitionName Reader | Out-Null
