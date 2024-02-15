<#
    .SYNOPSIS
    Get a list of accounts that are expired

    .DESCRIPTION
    The purpose of this funciton is to return a list of accounts that are expired.

    .NOTES
    Author: Kevin McClure

    .EXAMPLE
    Get-ADExpiredAccount
#>
function Get-ADExpiredAccount () {
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $false)]
        [string]$Domain
    )

    try {

        $ADExpiredAccount = Search-ADAccount -AccountExpired -UsersOnly  -resultSetSize $null| Select-Object Name, DistinguishedName, SamAccountName, AccountExpirationDate

        #Get Accounts that are expired
        $ADExpiredAccountExecution = "SUCCEEDED"
        $ADExpiredReturn = New-Object PSObject -Property @{
            AccountList = $ADExpiredAccount
            Status      = $ADExpiredAccountExecution
        }
    }


    catch {
        #Output Errors from AD Command
        $CaughtException = $_
        $ADExpiredAccountExecution = "FAILED"
        Write-Verbose $CaughtException
        Write-Verbose "Error querying Active Directory"

        $ADExpiredReturn = New-Object PSObject -Property @{
            AccountList = "Failed Retrieval"
            Status      = $ADExpiredAccountExecution
        }

    }
    #ReturnResults to Console
    $ADExpiredReturn
}
