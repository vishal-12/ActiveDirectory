<#
    .SYNOPSIS
    Get a list of accounts that are Disabled

    .DESCRIPTION
    The purpose of this funciton is to return a list of accounts that are Disabled.

    .NOTES
    Author: Kevin McClure

    .EXAMPLE
    Get-ADDisabledAccount
#>
function Get-ADDisabledAccount () {
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $false)]
        [string]$Domain
    )

    try {

        $ADDisabledAccount = Search-ADAccount -AccountDisabled -UsersOnly  -resultSetSize $null| Select-Object Name, SamAccountName, DistinguishedName

        #Get Accounts that are Disabled
        $ADDisabledAccountExecution = "SUCCEEDED"
        $ADDisabledReturn = New-Object PSObject -Property @{
            AccountList = $ADDisabledAccount
            Status      = $ADDisabledAccountExecution
        }
    }


    catch {
        #Output Errors from AD Command
        $CaughtException = $_
        $ADDisabledAccountExecution = "FAILED"
        Write-Verbose $CaughtException
        Write-Verbose "Error querying Active Directory"

        $ADDisabledReturn = New-Object PSObject -Property @{
            AccountList = "Failed Retrieval"
            Status      = $ADDisabledAccountExecution
        }

    }
    #ReturnResults to Console
    $ADDisabledReturn
}
