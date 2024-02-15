<#
    .SYNOPSIS
    Get a list of accounts that have passwords older than 90 days.

    .DESCRIPTION
    The purpose of this funciton is to return a list of accounts that have passwords older than 90 days.

    .NOTES
    Author: Kevin McClure

    .EXAMPLE
    Get-ADAccountLegacyPassword
#>
function Get-ADAccountLegacyPassword () {
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $false)]
        [string]$Domain
    )

    try {

        $90Days = (get-date).adddays(-90)
        $SearchDate = $90Days.ToString("yyyy-MM-dd")
        $passwordsNotChangedSince = $([datetime]::parseexact($searchdate, 'yyyy-MM-dd', $null)).ToFileTime()
        $ADLegacyPW = Get-ADUser -Filter * -Properties * | Where-Object { ($_.pwdLastSet -lt $passwordsNotChangedSince -and $_.pwdLastSet -ne 0) -and ($_.Name -notlike "Health*") -and ($_.Name -ne "Administrator")} | Select-Object Name, SamAccountName, DistinguishedName, @{Name="PasswordLastSet";Expression={[datetime]::FromFileTimeUTC($_.pwdLastSet)}}

        #Get Accounts that do not have expiring passwords
        $ADLegacyPWExecution = "SUCCEEDED"
        $ADLegacyPWReturn = New-Object PSObject -Property @{
            AccountList = $ADLegacyPW
            Status      = $ADLegacyPWExecution
        }
    }


    catch {
        #Output Errors from AD Command
        $CaughtException = $_
        $ADLegacyPWExecution = "FAILED"
        Write-Verbose $CaughtException
        Write-Verbose "Error querying Active Directory"

        $ADLegacyPWReturn = New-Object PSObject -Property @{
            AccountList = "Failed retrieval"
            Status      = $ADLegacyPWExecution
        }

    }
    #ReturnResults to Console
    $ADLegacyPWReturn
}
