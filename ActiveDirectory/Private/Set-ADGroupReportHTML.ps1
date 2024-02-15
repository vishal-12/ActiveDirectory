<#
.SYNOPSIS
Formats a html file with color code tagging from an array input

.DESCRIPTION
The purpose of this script is to format HTML from an input array.

.NOTES
Author: Kevin McClure

.PARAMETER EmailInput
Input of the email report.

.PARAMETER HTMLOutput
The name of the html file to export.

.EXAMPLE
Set-ADGroupReportHTML -EmailInput $Array -HTMLOutput $HTMLOutput
#>

Function Set-ADGroupReportHTML () {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $True)]
        [array]$EmailInput,
        [Parameter(Mandatory = $True)]
        [string]$HTMLOutput
    )

    #Define Style of HTML Output
    $htmlvar = @"
<table style="width:100%">
<style>
body { background-color:#FFFFFF;
font-family:Arial;
font-size:16pt; }
table, th, td {
  border: 1px solid black;
  border-collapse: collapse;
}
th { color:black;
background-color:#8DB4E2; }
th {
    background: #8DB4E2;
    position: sticky;
    top: 0;
    box-shadow: 0 4px 4px 1px rgba(0, 0, 0, 0.4);
  }
</style>
  <tr>
    <th>Name</th>
    <th>samAccountName</th>
    <th>Domain</th>
    <th>Groups Member of</th>
	<th>Distinguished Group Name</th>
  </tr>
"@
    $htmlvarend = @"
    <tr>

    </tr>
  </table>
"@

    Set-Location -Path $PSScriptRoot
    Set-Location -Path ..\Output
    $outloc = Get-Location
    $HTMLFile = "$outloc\$HTMLOutput"

    #Set standard HTML variables
    $trinserta = "<tr bgcolor='#E5E8E8'>"
    $trinsertb = "<tr bgcolor='#FBFCFC'>"
    $trend = '</tr>'
    $trinsert = $trinserta
    #Establish a list of Unique users for building the table
    $ADUniqueUsers = $EmailInput | Select-Object Name,Domain,SamAccountName -Unique
    $ui = 0
    #Loop through each unique
    foreach ($ADUU in $ADUniqueUsers) {
        $UserADGroups = $EmailInput | Where-Object { $_.Name -eq $ADUU.Name }
        $Count = $UserADGroups.Count
        $i = 0

        $userinsert = "<td rowspan='$Count'>$($ADUU.Name)</td>"
        $domaininsert = "<td rowspan='$Count'>$($ADUU.Domain)</td>"
        #Write-Host "$($ADUU.Domain) is the active domain"
        $saminsert = "<td rowspan='$Count'>$($ADUU.SamAccountName)</td>"

        #Loop through each Unique user and add each user to table with expanded groups and dns in one column
        foreach ($UADG in $UserADGroups) {
            $groupinsert = "<td>$($UADG.Group)</td>"
            $groupdninsert = "<td>$($UADG.DistinguishedGroupName)</td>"

            #Add html code to html variable
            if ($i -eq 0) {
                $htmlvar = $htmlvar + $trinsert + "`n" + $userinsert + "`n" + $saminsert + "`n" + $domaininsert + "`n" + $groupinsert + "`n" + $groupdninsert + "`n" + $trend + "`n"
            }
            else {
                $htmlvar = $htmlvar + $trinsert + "`n" + $groupinsert + "`n" + $groupdninsert + "`n" + $trend + "`n"
            }

            #Add to i for rotation of row colors
            $i = $i + 1
            #Change color of row according to even or odd

        }
        $ui = $ui + 1
        if (($ui%2) -eq 0 ) {
            $trinsert = $trinserta
        }
        else {
            $trinsert = $trinsertb
        }
    }

    #Ending the HTML code
    $htmlvar = $htmlvar + $htmlvarend

    #Finally output the html file
    $htmlvar | Out-file $HTMLFile

}
