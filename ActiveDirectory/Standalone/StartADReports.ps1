#Unblock Modules copied
Get-ChildItem 'C:\Program Files\WindowsPowerShell\Modules' -Recurse | Unblock-File

#Import Modules for PS4.0
Import-Module 'C:\Program Files\WindowsPowerShell\Modules\PSExcel\1.0.2\PSExcel.psm1'
Import-Module "C:\Program Files\WindowsPowerShell\Modules\Dizzion-ActiveDirectory\Dizzion-ActiveDirectory.psm1"


#Build SMTP Credential
$SMTPUserName = "security.portal@dizzion.com"
$SMTPPassword = "Wahu0759"
$SMPassword = ConvertTo-SecureString $SMTPPassword -AsPlainText -Force
$SMTPCredential = New-Object System.Management.Automation.PSCredential ($SMTPUserName, $SMpassword)

#Start Compliance Reports
Start-ADGroupMemberExport -DeliveryAddress "Kevin.McClure@Dizzion.com" -SenderAddress "Security.Portal@Dizzion.com" -SMTPServer "smtp.office365.com" -SMTPCredential $SMTPCredential -Verbose
Start-ADAccountAudit -DeliveryAddress "Kevin.McClure@Dizzion.com" -SenderAddress "Security.Portal@dizzion.com" -SMTPServer "smtp.office365.com" -SMTPCredential $SMTPCredential -Verbose