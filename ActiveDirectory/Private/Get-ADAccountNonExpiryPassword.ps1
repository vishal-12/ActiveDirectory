<#
    .SYNOPSIS
    Get a list of accounts that do not have expiring passwords

    .DESCRIPTION
    The purpose of this funciton is to return a list of accounts that do not have expiring passwords.

    .NOTES
    Author: Kevin McClure

    .EXAMPLE
    Get-ADAccountNonExpiryPassword
#>
function Get-ADAccountNonExpiryPassword () {
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $false)]
        [string]$Domain
    )

    try {
        #Get Accounts that do not have expiring passwords
        $ADNonExpiry = get-aduser -filter * -properties Name, PasswordNeverExpires | Where-Object { ($_.passwordNeverExpires -eq "true" ) -and ($_.Name -notlike "HealthMail*") -and ($_.Name -ne "Administrator") } | Select-Object Name, DistinguishedName, SamAccountName, PasswordNeverExpires
        $ADNonExpiryExecution = "SUCCEEDED"
        $ADNonExpiryReturn = New-Object PSObject -Property @{
            AccountList = $ADNonExpiry
            Status      = $ADNonExpiryExecution
        }
    }


    catch {
        $CaughtException = $_
        $ADNonExpiryExecution = "FAILED"
        Write-Verbose $CaughtException
        Write-Verbose "Error querying Active Directory"

        $ADNonExpiryReturn = New-Object PSObject -Property @{
            AccountList = "Failed retrieval"
            Status      = $ADNonExpiryExecution
        }

    }

    $ADNonExpiryReturn
}
