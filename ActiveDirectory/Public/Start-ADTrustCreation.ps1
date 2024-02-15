<#
    .SYNOPSIS
    Create a new AD Trust for a target AD Forest

    .DESCRIPTION
    The purpose of this function is to create a conditional forwarder and then the AD Trust for a Target Domain. This function should be ran against a DC in the source domain.

    .PARAMETER TargetADForest
    The target Forest to create the AD Trust with.

    .PARAMETER TargetADCredential
    The target AD Credential to authenticate with the target forest.

    .PARAMETER Domain
    The target DNS Root Domain to create the conditional forwarder for.

    .PARAMETER PrimaryDNSServer
    The target primary DNS to resolve the target domain records from.

    .PARAMETER SecondaryDNSServer
    The target primary DNS to resolve the target domain records from. Optional, but should be included if present. 

    .PARAMETER LogFolderPath
    The log folder to store the log in

    .PARAMETER LogFileName
    The log file name to use

    .NOTES
    Author: Kevin McClure

    .EXAMPLE
    Start-ADTrustCreation -Domain Contoso.com -PrimaryDNSServer 192.168.1.1 -SecondaryDNSServer 192.168.1.2 -TargetADforest Contoso.com -TargetADCredential $ADCred
#>
function Start-ADTrustCreation () {
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true)]
        [string]$Domain,
        [Parameter(Mandatory = $true)]
        [string]$PrimaryDNSServer,
        [Parameter(Mandatory = $false)]
        [string]$SecondaryDNSServer,
        [Parameter(Mandatory = $true)]
        [string]$TargetADForest,
        [ValidateNotNull()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $TargetADCredential
    )

    #Create log
    New-Log -FolderPath $LogFolderPath -FileName $LogFileName | Out-Null


    #Report Parameters retrieved to console and log
    Add-LogEntry "Received the following parameters:"
    Add-LogEntry "Domain: $Domain"
    Add-LogEntry "TargetADForest: $TargetADForest"
    Add-LogEntry "TargetADCredential: $TargetADCredential " 
    Add-LogEntry "PrimaryDNSServer: $PrimaryDNSServer"
    Add-LogEntry "SecondaryDNSServer: $SecondaryDNSServer"

    #Create Return object
    $ADTrustCreationReturnObject = New-Object PSObject -Property @{
        Status  = "NA"
        Message = "NA"
    }

    #Set variables
    $ErrorCode = 0

    #Sending conditional forwarder parameters for New-DNSConditionalForwarder function.
    try {
        Add-LogEntry "Starting creation of conditional forwarder specified"
        $ConditionalForwarderSplat = @{
            Verbose          = $true
            Domain           = $Domain
            PrimaryDNSServer = $PrimaryDNSServer
        }
        if ($SecondaryDNSServer) {
            $ConditionalForwarderSplat.SecondaryDNSServer = $SecondaryDNSServer
        }
        $ConditionalForwarderReturn = New-DNSConditionalForwarder @ConditionalForwarderSplat
        if ($ConditionalForwarderReturn.Status -notlike "FAIL*") {
            $ADTrustCreationReturnObject.Status = "SUCCESS"
        }
        else {
            $ADTrustCreationReturnObject.Status = "FAILED"
            $ADTrustCreationReturnObject.Message = "Failed creating conditional forwarder."
            $ErrorCode = 1
        }

    }
    catch {
        #Output Errors from AD Command
        $CaughtException = $_
        Write-Verbose $CaughtException
        Write-Verbose "Error creating DNS zone. Are you running this from a DNS server?"
        $ErrorCode = 1
        $ADTrustCreationReturnObject.Status = "FAILED"
        $ADTrustCreationReturnObject.Message = "Failed creating conditional forwarder."

    }

    #Sending AD Trust parameters for New-ADTrust function.
    if ($ErrorCode -ne 1) {

        try {
            Add-LogEntry "Starting creation of ADTrust specified"
            $ADTrustSplat = @{
                Verbose            = $true
                TargetADForest     = $TargetADForest
                TargetADCredential = $TargetADCredential
            }
            $ADTrustReturn = New-ADTrust @ADTrustSplat
            if ($ADTrustReturn.Status -notlike "FAIL*") {
                $ADTrustCreationReturnObject.Status = "SUCCESS"
                $ADTrustCreationReturnObject.Message = "Successfully completed operations."
            }
            else {
                $ADTrustCreationReturnObject.Status = "FAILED"
                $ADTrustCreationReturnObject.Message = "Failed creating AD Trust forwarder."
                $ErrorCode = 1
            }

        }
        catch {
            #Output Errors from AD Command
            $CaughtException = $_
            Write-Verbose $CaughtException
            Write-Verbose "Failed creating AD Trust forwarder. Are credentials correct?"
            $ErrorCode = 1
            $ADTrustCreationReturnObject.Status = "FAILED"
            $ADTrustCreationReturnObject.Message = "Failed creating ADTrust"

        }
    }

    #Return results to console
    $ADTrustCreationReturnObject

}
