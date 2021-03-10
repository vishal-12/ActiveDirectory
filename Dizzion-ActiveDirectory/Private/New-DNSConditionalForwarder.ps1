
<#
    .SYNOPSIS
    Create a new conditional forwarder for a target AD Forest

    .DESCRIPTION
    The purpose of this function is to create a conditional forwarder for a target domain on another AD domain. This is necessary for an AD Trust.

    .PARAMETER Domain
    The target DNS Root Domain to create the conditional forwarder for.

    .PARAMETER PrimaryDNSServer
    The target primary DNS to resolve the target domain records from.

    .PARAMETER SecondaryDNSServer
    The target primary DNS to resolve the target domain records from. Optional, but should be included if present. 

    .NOTES
    Author: Kevin McClure

    .EXAMPLE
    New-DNSConditionalForwarder -Domain Contoso.com -PrimaryDNSServer 192.168.1.1 -SecondaryDNSServer 192.168.1.2
#>
function New-DNSConditionalForwarder () {
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true)]
        [string]$Domain,
        [Parameter(Mandatory = $true)]
        [string]$PrimaryDNSServer,
        [Parameter(Mandatory = $false)]
        [string]$SecondaryDNSServer
    )

    Add-LogEntry "Received the following parameters:"
    Add-LogEntry "Domain: $Domain"
    Add-LogEntry "PrimaryDNSServer: $PrimaryDNSServer"
    Add-LogEntry "SecondaryDNSServer: $SecondaryDNSServer"

    try {

        $ConditionalForwarderSplat = @{
            Verbose          = $true
            Name             = $Domain
            ReplicationScope = "Forest"
        }

        if ($SecondaryDNSServer) {
            $MasterServers = "$PrimaryDNSServer,$SecondaryDNSServer"
        }
        else {
            $MasterServers = $PrimaryDNSServer
        }
        $ConditionalForwarderSplat.MasterServers = $MasterServers
        Add-DnsServerConditionalForwarderZone @ConditionalForwarderSplat
        $ConditionalForwarderReturn = New-Object PSObject -Property @{
            Status = "SUCCESS"
        }
    }

    catch {
        #Output Errors from AD Command
        $CaughtException = $_
        Write-Verbose $CaughtException
        Write-Verbose "Error creating DNS zone. Are you running this from a DNS server?"
        $ErrorCode = 1
        $ConditionalForwarderReturn = New-Object PSObject -Property @{
            Status = "FAILED"
        }
    }
    $ConditionalForwarderReturn
}