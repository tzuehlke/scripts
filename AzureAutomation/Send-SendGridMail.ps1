<#PSScriptInfo
.VERSION 1.0
.GUID 100d942e-7cb9-4ba3-afba-33b87c036e2b
.AUTHOR Thomas Zuehlke
.COMPANYNAME
.COPYRIGHT
.TAGS AzureAutomation Mail SendGrid
.LICENSEURI
.PROJECTURI https://blog.zuehlke.cloud/2020/07/send-mails-with-sendgrid-via-azure-automation/
.ICONURI
.EXTERNALMODULEDEPENDENCIES
.REQUIREDSCRIPTS
.EXTERNALSCRIPTDEPENDENCIES
.RELEASENOTES
#>

<#
.SYNOPSIS
   Send Mails by using the SendGrid service in Azure.

.DESCRIPTION
   Loads the SendGrid API-Key from Azure Automation secrets and creates a body for a post message by using the parameter. Sends the message via post.

.PARAMETER SendGridApiCredentialName
   Mandatory
   The name of the credentials, where the SendGrid-API Key is stored.

.PARAMETER To
   Mandatory
   Mail receiver.

.PARAMETER From
   Mandatory
   Mail sender

.PARAMETER Subject
   Mandatory
   Mail subject

.PARAMETER Body
   Mandatory
   Mail body

.PARAMETER SendGridApiUrl
   Optional
   REST URL

.NOTES
   AUTHOR: Thomas Zuehlke 
   LASTEDIT: July, 2020
#>

# Returns strings with status messages
[OutputType([String])]

param (
    [Parameter(Mandatory=$true)] 
    [String]  $SendGridApiCredentialName,

    [Parameter(Mandatory=$true)] 
    [String] $To,
	
    [Parameter(Mandatory=$true)] 
    [String]  $From,

    [Parameter(Mandatory=$true)] 
    [String]  $Subject,

    [Parameter(Mandatory=$true)] 
    [String]  $Body,
	
	[Parameter(Mandatory=$false)] 
    [String]  $SendGridApiUrl = "https://api.sendgrid.com/v3/mail/send"
)

$Cred = Get-AutomationPSCredential -Name $SendGridApiCredentialName
$userName = $Cred.UserName
$securePassword = $Cred.Password
$ApiCred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $userName, $securePassword
$ApiKey = $ApiCred.GetNetworkCredential().Password

$Config = '{"personalizations": [ { "to": [ { "email": "'+$To+'" } ], "subject": "'+$Subject+'" } ], "from": { "email": "'+$From+'" }, "content": [ { "type": "text/html", "value": "'+$Body+'" } ] }'

$Headers = @{"Authorization" = "Bearer " + $ApiKey}
$Result = Invoke-WebRequest -Uri $SendGridApiUrl -Method Post -ContentType "application/json" -Body $Config -Headers $Headers -UseBasicParsing

return $Result