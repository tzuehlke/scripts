[CmdletBinding()]
[OutputType([PSObject])]
param (
  [parameter(Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [String]
  $Query
)

$result=@()
$pagetoken = $null
do {
    $partialresult = Search-AzGraph -UseTenantScope -AllowPartialScope -Query $Query -SkipToken $pagetoken
    $pagetoken = $partialresult.SkipToken
    $result += $partialresult.Data
} while ($null -ne $pagetoken)
return $result
