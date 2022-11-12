[CmdletBinding()]
[OutputType([PSObject])]
param (
  [parameter(Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [String]
  $ManagementGroupID,

  [parameter(Mandatory = $false)]
  [ValidateNotNullOrEmpty()]
  [String]
  $StartDate = (Get-Date).Date.ToString("yyyy-MM-01T00:00:00+00:00"),

  [parameter(Mandatory = $false)]
  [ValidateNotNullOrEmpty()]
  [String]
  $EndDate = (Get-Date).Date.AddMonths(1).ToString("yyyy-MM-01T00:00:00+00:00")
)

$body = @{
    "type"="ActualCost"
    "dataSet"=@{
        "granularity"= "Daily"
        "aggregation"= @{
            "totalCost"= @{
                "name"= "Cost"
                "function"= "Sum"
            }
        }
        "sorting"= @(
            @{
                "direction"= "ascending"
                "name"= "UsageDate"
            }
        )
        "grouping"= @(
            @{
                "type"= "Dimension"
                "name"= "ReservationName"
            }
        )
    }
    "timeframe"= "Custom"
    "timePeriod"= @{
        "from"= "$StartDate"
        "to"= "$EndDate"
    }
}

$url = "https://management.azure.com/providers/Microsoft.Management/managementGroups/$ManagementGroupID/providers/Microsoft.CostManagement/query?api-version=2021-10-01"

$ris = @()
while($url){
    $costs = Invoke-RestMethod `
        -Method Post `
        -ContentType "application/json; charset=utf-8" `
        -Authentication Bearer `
        -Token (ConvertTo-SecureString -String (Get-AzAccessToken -ResourceUrl "https://management.azure.com").token -AsPlainText) `
        -Body (ConvertTo-Json $body -Depth 10) `
        -Uri $url

    $rows = $costs.properties.rows
    foreach($row in $rows){
        if($row[0] -ne 0 -and $row[2]){
            $ri = [pscustomobject] [ordered] @{
                Cost = $row[0]
                UsageDate = $row[1]
                ReservationName = $row[2]
                Currency = $row[3]
            }
            $ris += $ri
        }
    }
    $url = $costs.properties.nextLink
}

return $ris