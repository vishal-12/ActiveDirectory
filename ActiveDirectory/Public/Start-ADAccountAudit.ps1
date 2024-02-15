<#
    .SYNOPSIS
    Starts a AD Audit of problematic Accounts. The follow account problems are currently included:
    -Users with passwords that do not expire.
    -Users with passwords older than 90 days.
    -Users who are expired.
    -Users who are disabled.

    .DESCRIPTION
    The purpose of this function is to audit an AD Domain for Account types that are problematic.

    .NOTES
    Author: Kevin McClure

    .PARAMETER Domain
    Optional parameter to specify a search filter for a specific Domain

    .PARAMETER DeliveryAddress
    The email address to deliver the AD Account Audit Report To.

    .PARAMETER SenderAddress
    The Address to place in the from field.

    .PARAMETER SMTPServer
    The SMTP Relay server to use for relay

    .PARAMETER SMTPCredential
    The SMTP Credentials to use for relay. Needed if the relay requires authentication.

    .EXAMPLE
    Start-ADAccountAudit -Domain mcnet.pri

#>

function Start-ADAccountAudit () {
    [CmdletBinding()]


    Param
    (
        [Parameter(Mandatory = $false)]
        [string]$Domain,

        [Parameter(Mandatory = $true)]
        [string]$DeliveryAddress,

        [Parameter(Mandatory = $true)]
        [string]$SenderAddress,

        [Parameter(Mandatory = $true)]
        [string]$SMTPServer,

        [Parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]$SMTPCredential
    )

    #Set-Variables
    $curloc = Get-Location
    Set-Location -Path $PSScriptRoot
    Set-Location -Path ..\Output
    $StartTimer = (Get-Date)
    $Subject = "Active Directory Account Audit"
    $outloc = Get-Location

    #Import-Modules if Modules are not auto imported
    Import-Module PSExcel
    Import-Module ActiveDirectory

    #Create empty array for report
    $ADAuditReport = @()

    #Create the Content Library
    Write-Verbose "Starting AD Audit"

    #Start Get-ADDisabledAccount
    Write-Verbose "Starting Audit for Disabled Accounts"
    $DisabledAccounts = Get-ADDisabledAccount
    if ($DisabledAccounts.Status -eq "SUCCEEDED") {
        foreach ($User in $DisabledAccounts.AccountList) {
            $obj = " " | Select-Object Domain, User, SAMAccountName, Problem, Details
            $dn = $User.DistinguishedName
            $domain = $dn -Split "," | Where-Object { $_ -like "DC=*" }
            $domain = $domain -join "." -replace ("DC=", "")
            $obj.Domain = $Domain
            $obj.User = $User.Name
            $obj.SAMAccountName = $User.SAMAccountName
            $obj.Problem = "AccountDisabled"
            $obj.Details = "Disabled Account"
            $ADAuditReport += $obj
        }
    }

    else {
        Write-Verbose "Problem with Account Retrieval. Please check Active Directory connection"
    }

    #Start Get-ADAccountLegacyPassword
    Write-Verbose "Starting Audit for Legacy (90+ days old) passwords"
    $LegacyPWAccounts = Get-ADAccountLegacyPassword
    if ($LegacyPWAccounts.Status -eq "SUCCEEDED") {
        foreach ($User in $LegacyPWAccounts.AccountList) {
            $obj = " " | Select-Object Domain, User, SAMAccountName, Problem, Details
            $dn = $User.DistinguishedName
            $domain = $dn -Split "," | Where-Object { $_ -like "DC=*" }
            $domain = $domain -join "." -replace ("DC=", "")
            $obj.Domain = $Domain
            $obj.User = $User.Name
            $obj.SAMAccountName = $User.SAMAccountName
            $obj.Problem = "Password Exceeds 90 Days Age"
            $obj.Details = "Password last changed: $($User.PasswordLastSet)"
            $ADAuditReport += $obj
        }
    }

    else {
        Write-Verbose "Problem with Account Retrieval. Please check Active Directory connection"
    }

    #Start Get-ADAccountExpiryPassword
    Write-Verbose "Starting Audit for Accounts with Non Expiring Passwords"
    $NonExpiryPWAccounts = Get-ADAccountNonExpiryPassword
    if ($NonExpiryPWAccounts.Status -eq "SUCCEEDED") {
        foreach ($User in $NonExpiryPWAccounts.AccountList) {
            $obj = " " | Select-Object Domain, User, SAMAccountName, Problem, Details
            $dn = $User.DistinguishedName
            $domain = $dn -Split "," | Where-Object { $_ -like "DC=*" }
            $domain = $domain -join "." -replace ("DC=", "")
            $obj.Domain = $Domain
            $obj.User = $User.Name
            $obj.SAMAccountName = $User.SAMAccountName
            $obj.Problem = "Password never expires"
            $obj.Details = "Account has no expiring password"
            $ADAuditReport += $obj
        }
    }

    else {
        Write-Verbose "Problem with Account Retrieval. Please check Active Directory connection"
    }

    #Start Get-ADExpiredAccount
    Write-Verbose "Starting Audit for Expired Accounts"
    $ExpiredAccounts = Get-ADExpiredAccount

    if ($ExpiredAccounts.Status -eq "SUCCEEDED") {
        foreach ($User in $ExpiredAccounts.AccountList) {
            $obj = " " | Select-Object Domain, User, SAMAccountName, Problem, Details
            $dn = $User.DistinguishedName
            $domain = $dn -Split "," | Where-Object { $_ -like "DC=*" }
            $domain = $domain -join "." -replace ("DC=", "")
            $obj.Domain = $Domain
            $obj.User = $User.Name
            $obj.SAMAccountName = $User.SAMAccountName
            $obj.Problem = "Account Expired"
            $obj.Details = "Account expired on $($User.AccountExpirationDate)"
            $ADAuditReport += $obj
        }
    }

    else {
        Write-Verbose "Problem with Account Retrieval. Please check Active Directory connection"
    }


    #Output report
    $ReportDate = (Get-Date).ToString("MM-dd-yyyy")
    $XLSOut = $Subject + "-" + $ReportDate + ".xlsx"
    $ADAuditReport | Export-XLSX -Table -Autofit -Force -Path "$outloc\$XLSOut"

    $HTMLOutput = $Subject + "-" + $ReportDate + ".htm"
    $message = New-Object System.Net.Mail.MailMessage $SenderAddress, $DeliveryAddress
    $message.Subject = "$Subject"
    $message.IsBodyHTML = $true #force html

    Set-HTMLReportTagging -EmailInput $ADAuditReport -HTMLOutput $HTMLOutput -TotalsInput $Totals

    #Attach files to email
    $attachment = "$outloc\$HTMLOutput"
    $attach = new-object Net.Mail.Attachment($attachment)

    $attachment2 = "$outloc\$XLSOut"
    $attach2 = new-object Net.Mail.Attachment($attachment2)

    $message.Attachments.Add($attach)
    $message.Attachments.Add($attach2)

    #Insert Total Run Time into html email
    $EndTimer = (Get-Date)
    $message.Body += Get-Content $outloc\$HTMLOutput
    $message.Body += "

    Script Process Time: $(($EndTimer-$StartTimer).totalseconds) seconds"

    #Send
    Write-Verbose "Sending email to $DeliveryAddress"
    Write-Host "Sending email to $DeliveryAddress"
    if ($SMTPCredential) {
        $smtp = New-Object Net.Mail.SmtpClient($smtpServer, $smtpport)
        $smtp.Credentials = $SMTPCredential
        $smtpport = "587"
        $smtp.EnableSsl = $true
    }
    else {
        $smtp = New-Object Net.Mail.SmtpClient($smtpServer)
    }
    $smtp.Send($message)

    #Destroy attachments
    $attach.Dispose()
    $attach2.Dispose()

    #Remove files in output directory
    Remove-Item $outloc\$HTMLOutput -recurse
    Remove-Item $outloc\$XLSOut -Recurse

    #Output script time to host
    Write-Verbose "Elapsed Script Time: $(($EndTimer-$StartTimer).totalseconds) seconds"

    #Restore Previous working directory
    Set-Location $curloc



}
