[CmdletBinding()]
param (
[parameter(Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [String]
  $LogFile
)

$fileContent = Get-Content $LogFile
$regexresults = [regex]::Matches($fileContent, '(?<=ERROR..vertex \")[a-zA-Z\d\-\/\|_\.]+|[a-zA-Z\d\-\/\|_\.]+(?=\" already exists)')
for($i=0; $i -le $regexresults.Count-1; $i+=2){
    Write-Output "terraform import $($regexresults[$i].Value) $($regexresults[$i+1].Value)"
}
