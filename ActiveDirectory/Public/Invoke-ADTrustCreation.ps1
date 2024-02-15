<#
    .SYNOPSIS
    Invoke a ADTrust Creation from a valid json configuration file. The invoke function is for  automation of the Start-ADTrustCreation function.

    .DESCRIPTION
    The purpose of this function is to automate the Start-ADTrustCreation process.  A json file is used for input of most values.

    .NOTES
    Author: Kevin McClure

    .PARAMETER ConfigFile
    The json formatted configuration file to pull from.

    .PARAMETER LogFolderPath
    The log folder to store the log in

    .PARAMETER LogFileName
    The log file name to use

    .EXAMPLE
    Invoke-ADTrustCreation -ConfigFile "C:\Temp\Config.json" 

#>

function Invoke-ADTrustCreation () {
    [CmdletBinding()]

    param
    (
        [Parameter(Mandatory = $True)]
        [ValidateScript( { Test-Path -Path $_ -PathType Leaf })]
        [ValidatePattern( '\.json$' )]
        [string]$ConfigFile,

        [Parameter(Mandatory = $false)]
        [string]$LogFolderPath = 'C:\Temp',

        [Parameter(Mandatory = $false)]
        [string]$LogFileName = 'NSXVipsecVPNCreation.log'
    )
    New-Log -FileName $LogFileName -FolderPath $LogFolderPath

    $ErrorCode = 0

    #Create Splat 
    $InvokeADTrustCreationsplat = @{
        Verbose = $true
    }
    
    #Create log
    New-Log -FolderPath $LogFolderPath -FileName $LogFileName | Out-Null

    Add-LogEntry "Importing configuraton file"

    try {
        $Config = Get-Content $configFile | ConvertFrom-Json
    }

    catch {
        $ErrorCode = 1
        $CaughtException = $_
        Add-LogEntry $CaughtException
        Add-LogEntry 'Error importing json file. Check source config.'
    }

    if ($ErrorCode -ne 1) {
        Add-LogEntry "Importing Credentials for ADTrust"
        try {
            $ADUserName = $config.TargetADCredential.ADUserName
            $ADPassword = $config.TargetADCredential.ADPassword 
            $TADPassword = ConvertTo-SecureString $ADPassword -AsPlainText -Force
            $ADCredential = New-Object System.Management.Automation.PSCredential ($ADUserName, $TADpassword)
            $InvokeADTrustCreationsplat.TargetADCredential = $ADCredential
        }
        catch {
            $ErrorCode = 1
            $CaughtException = $_
            Add-LogEntry $CaughtException
            Add-LogEntry 'Error importing credentials. Check the source JSON that the proper credentials are specified.'
        }
    }

    if ($ErrorCode -ne 1) {
        Add-LogEntry "Importing DNS Servers from JSON source"
        try {
            $InvokeADTrustCreationsplat.PrimaryDNSServer = $config.Options.PrimaryDNSServer
            if ($config.Options.SecondaryDNSServer){
                $InvokeADTrustCreationsplat.SecondaryDNSServer = $config.Options.SecondaryDNSServer
            }
            
        }
        catch {
            $ErrorCode = 1
            $CaughtException = $_
            Add-LogEntry $CaughtException
            Add-LogEntry 'Error importing DNS Values. Check source config file for correct values.'
        }
    }

    if ($ErrorCode -ne 1) {
        Add-LogEntry "Importing AD Forest and Domain "
        try {
            $InvokeADTrustCreationsplat.Domain = $config.Options.Domain
            $InvokeADTrustCreationsplat.TargetADForest = $config.Options.TargetADForest

        }
        catch {
            $ErrorCode = 1
            $CaughtException = $_
            Add-LogEntry $CaughtException
            Add-LogEntry 'Error importing Forest and Domain Values. Check source config file for correct values.'
        }
    }

   if ($ErrorCode -ne 1){
       Add-LogEntry "All values successfully imported. Calling Start-ADTrustCreation function"
       Start-ADTrustCreation @InvokeADTrustCreationsplat
   } 

}