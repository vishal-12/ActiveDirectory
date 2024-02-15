<#
    .SYNOPSIS
    This process reports in HTML and XLSX a list of users and the groups they are members of. Currently excludes Exchange mailbox system accounts.

    .DESCRIPTION
    The purpose of this function is to report a list of users and the groups they are members of

    .NOTES
    Author: Kevin McClure

    .PARAMETER Domain
    Optional parameter to specify a search filter for a specific Domain if multiple are available.
    This Parameter will require the Credential if it is not the native domain or ran as a user with read permissions to all of AD.

    .PARAMETER DomainCredential
    This credential object is required when an alternate domain is specified which is not native to the machine it is run from.

    .PARAMETER DeliveryAddress
    The email address to deliver the AD Account Audit Report To.

    .PARAMETER SenderAddress
    The Address to place in the from field.

    .PARAMETER SMTPServer
    The SMTP Relay server to use for relay

    .PARAMETER SMTPCredential
    The SMTP Credentials to use for relay. Needed if the relay

    .EXAMPLE
    Start-ADGroupMemberExport -Domain mcnet.pri -Credential $ADCred -DeliveryAddress TestUser@contoso.com -SenderAddress ADGroups@contoso.com -SMTPServer mail.contoso.com -SMTPCredential $SMTPCreds

#>

function Start-ADGroupMemberExport () {
    [CmdletBinding()]

    Param
    (
        [Parameter(Mandatory = $false)]
        [string]$Domain,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]
        $DomainCredential,

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
    $Subject = "Active_Directory_Group_Export"
    $outloc = Get-Location

    #Import-Modules if Modules are not auto imported
    Import-Module PSExcel
    Import-Module ActiveDirectory

    #Create empty array for report
    $ADGroupMembership = @()

    #Create the Content Library
    Write-Verbose "Starting AD Group Export"

    try {
        $GetADUserSplat = @{
            Verbose = $true
            filter  = "*"
        }

        if ($Domain) {
            $DomainParse = $Domain.Replace(".", ",DC=")
            $SearchBase = "DC=" + $DomainParse
            $GetADUserSplat.SearchBase = $SearchBase
            $GetADUserSplat.Credential = $DomainCredential
        }

        $ADUsers = Get-ADUser @GetADUserSplat |  Where-Object { ($_.Name -notlike "*Mailbox*") -And ($_.Name -notlike "*krbtgt*") -And ($_.Name -notlike "*Federated*")`
        -And ($_.Name -notlike "*Migration*") -And ($_.Name -notlike "*$*") -And ($_.Name -ne "Administrator") -And ($_.Enabled -eq $True)}
        $ADGroupMembership = @()
        Foreach ($ADU in $ADUsers) {
            $ADGroups = @()
            $User = Get-ADUser $ADU.samAccountName -Properties MemberOf
            foreach ($group in $user.MemberOf){
                $obj = "" | Select-Object Name,DistinguishedName
                $Groupobj = Get-ADGroup $group
                $obj.Name = $Groupobj.Name
                $obj.DistinguishedName = $groupobj.DistinguishedName
                $ADGroups += $obj
            }

            #PS 4.0 has a bug in Get-ADPrincipalGroupMembership and cannot be used
            #$ADgroups = Get-ADPrincipalGroupMembership -Identity $ADU
            foreach ($ADG in $ADgroups) {
                $obj = "" | Select-Object Name, Domain, SamAccountName, Group, DistinguishedGroupName
                $obj.Name = $ADU.Name
                $dn = $ADU.DistinguishedName
                $domainobj = $dn -Split "," | Where-Object { $_ -like "DC=*" }
                $domainobj = $domainobj -join "." -replace ("DC=", "")
                #Write-Host "$domainobj set to active domain target for group retrieval"
                $obj.Domain = $domainobj
                $obj.SamAccountName = $ADU.SamAccountName
                $obj.Group = $ADG.name
                $obj.DistinguishedGroupName = $ADG.distinguishedName
                $ADGroupMembership += $obj
            }
        }
        #$ADGroupMembership = $ADGroupMembership | Where-Object { ($_.Name -notlike "*Mailbox*") -And ($_.Name -notlike "*krbtgt*") -And ($_.Name -notlike "*Federated*")`
         #-And ($_.Name -notlike "*Migration*") -And ($_.Name -notlike "*$*") -And ($_.Enabled -eq $True)}
        $ADGroupMemberExportReturn = New-Object PSObject -Property @{
            Status = "SUCCESS"
        }
    }

    catch {
        #Output Errors from AD Command
        $CaughtException = $_
        Write-Verbose $CaughtException
        Write-Verbose "Error querying Active Directory"
        $ErrorCode = 1
        $ADGroupMemberExportReturn = New-Object PSObject -Property @{
            Status = "FAILED"
        }

    }
    if ($ErrorCode -ne 1) {
        #Output report
        $ReportDate = (Get-Date).ToString("MM-dd-yyyy")
        $XLSOut = $Subject + "-" + $ReportDate + ".xlsx"
        $ADGroupMembership | Export-XLSX -Table -Autofit -Force -Path "$outloc\$XLSOut"

        $HTMLOutput = $Subject + "-" + $ReportDate + ".htm"
        $message = New-Object System.Net.Mail.MailMessage $SenderAddress, $DeliveryAddress
        $message.Subject = "$Subject"
        $message.IsBodyHTML = $true #force html

        Set-ADGroupReportHTML -EmailInput $ADGroupMembership -HTMLOutput $HTMLOutput

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
    }

    #OutputStatus
    $ADGroupMemberExportReturn


    #Restore Previous working directory
    Set-Location $curloc

}
