<#
    .SYNOPSIS
    Create a new AD Trust for a target AD Forest

    .DESCRIPTION
    The purpose of this function is to create an AD Trust.

    .PARAMETER TargetADForest
    The target Forest to create the AD Trust with.

    .PARAMETER TargetADCredential
    The target AD Credential to authenticate with the target forest.

    .NOTES
    Author: Kevin McClure

    .EXAMPLE
    New-ADTrust -TargetADForest Contoso.com -TargetADCredential $TargetADCred
#>
function New-ADTrust () {
    [CmdletBinding()]
    Param
    (

        [Parameter(Mandatory = $true)]
        [string]$TargetADForest,
        [ValidateNotNull()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $TargetADCredential
    )

    Add-LogEntry "Received the following parameters:"
    Add-LogEntry "TargetADForest: $TargetADForest"
    Add-LogEntry "TargetADCredential: $TargetADCredential"
    
    #Import Module if not loaded
    Import-Module ActiveDirectory -Verbose:$false | Out-Null

    #Convert Credential to individual parameters.
    $ADTrustUsername = $TargetADCredential.UserName
    $ADTrustPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($TargetADCredential.Password))


    try {
        Add-LogEntry "Evaluating Target AD Forest $TargetADForest"
        $remoteContext = New-Object -TypeName "System.DirectoryServices.ActiveDirectory.DirectoryContext" -ArgumentList @( "Forest", $TargetADForest, $ADTrustUsername, $ADTrustPassword) 
        $remoteForest = [System.DirectoryServices.ActiveDirectory.Forest]::getForest($remoteContext) 
        Add-LogEntry "Target AD Forest evaluation succeeded for $remoteForest"
    }
    catch {
        #Output Errors from AD Command
        $CaughtException = $_
        Add-LogEntry $CaughtException
        Add-LogEntry "Error querying Targbet Active Directory. Is network connectivity established?"
        $ErrorCode = 1
        $ADTrustReturn = New-Object PSObject -Property @{
            Status = "FAILED"
        }
    }

    if ($ErrorCode -ne 1) {
        Add-LogEntry "Connected to Remote forest: $($remoteForest.Name)" 

        $localforest = [System.DirectoryServices.ActiveDirectory.Forest]::getCurrentForest() 
        
        Add-LogEntry "Connected to Local forest: $($localforest.Name)" 
        
        try { 
        
            $localForest.CreateTrustRelationship($remoteForest, "Inbound") 
        
            Add-LogEntry "CreateTrustRelationship: Succeeded for domain $($remoteForest)" 

            $ADTrustReturn = New-Object PSObject -Property @{
                Status = "SUCCESS"
        
            } 
        }
        catch { 
            #Output Errors from AD Command
            $CaughtException = $_
            Add-LogEntry $CaughtException
            Add-LogEntry "CreateTrustRelationship: Failed for domain $($remoteForest)`n`tError: $($($_.Exception).Message)" 
            $ErrorCode = 1
            $ADTrustReturn = New-Object PSObject -Property @{
                Status = "FAILED"
            }
        }

    }
    $ADTrustReturn

}
