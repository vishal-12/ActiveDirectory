
  
  
  
  

![]( [https://www.dizzion.com/wp-content/uploads/2016/07/dizzion-logo.png "Dizzion Horizon](https://www.google.com/imgres?imgurl=https%3A%2F%2Fmiro.medium.com%2Fv2%2Fresize%3Afit%3A624%2F0*u8lSOsKnxFapY0qO.png&tbnid=Xlr65uXhi9DLjM&vet=12ahUKEwj6hKOb5ayEAxW2TWwGHQaKDsUQMygDegQIARB6..i&imgrefurl=https%3A%2F%2Fmedium.com%2F%40gwenilorac%2Funderstanding-active-directory-8434ecbcf558&docid=6SJThtCXvnbVRM&w=624&h=426&q=Active%20directory&client=safari&ved=2ahUKEwj6hKOb5ayEAxW2TWwGHQaKDsUQMygDegQIARB6)")

  
  
  

------------

  
  
  

# ActiveDirectory**

  
  
  
  
  
  

## ActiveDirectory module enables automation and operations of an Active Directory environment.

  
  
  
  
  

ActiveDirectory is designed to perform reporting, operations and automation of an Active Directory Environment. This version of this module is for compliance reporting and the automation of AD Trust creation.

  
  
  

Version 1.0 will perform the following operations:

  
  
  
  
  

**Account Audit Reporting** This process retrieves values of all active directory accounts and reports on any accounts that have the following issues:

- Password older than 90 days

- Password that does not expire

- Disabled Accounts

- Expired Accounts

  
  
  

**Group Export by Member** This process reports in HTML and XLSX a list of users and the groups they are members of.

  

**AD Trust Creation** This process creates an AD trust from a provided JSON. This process is designed to run from a source domain controller with DNS role isntalled.

  
  
  
  

------------

  
  
  
  
  

### **Public Functions**

  
  
  
  
  

------------

  
  
  

These functions are exposed when the module is imported. They are intended to be executed directly and are responsible for interaction with the private functions.

  
  
  
  
  

**Start-ADAccountAudit**

Starts a AD Audit of problematic Accounts. The follow account problems are currently included:

  

-Users with passwords that do not expire.

  

-Users with passwords older than 90 days.

  

-Users who are expired.

  

-Users who are disabled.

  
  

*PARAMETERS*

**-Domain**

Optional parameter to specify a search filter for a specific Domain

**-DeliveryAddress**

The email address to deliver the AD Account Audit Report To.

**-SenderAddress**

The Address to place in the from field.

**-SMTPServer**

The SMTP Relay server to use for relay

**-SMTPCredential**

The SMTP Credentials to use for relay. Needed if the relay requires authentication.

  

Example with all parameters:

  
  
  

```powershell

  

$SMTPCreds = Get-Credential

Start-ADAccountAudit -Domain contoso.com -DeliveryAddress Test@contoso.com `

-SenderAddress AccountAudit@contoso.com -SMTPServer mail.contoso.com `

-SMTPCredential $SMTPCreds

  
  

```

  
  
  

**Start-ADGroupMemberExport** TThis process reports in HTML and XLSX a list of users and the groups they are members of. Currently excludes Exchange mailbox system accounts.

*PARAMETERS*

**-Domain**

Optional parameter to specify a search filter for a specific Domain if multiple are available.

This Parameter will require the Credential if it is not the native domain or ran as a user with read permissions to all of AD.

**-DomainCredential**

This credential object is required when an alternate domain is specified which is not native to the machine it is run from.

**-DeliveryAddress**

The email address to deliver the AD Account Audit Report To.

**-SenderAddress**

The Address to place in the from field.

**-SMTPServer**

The SMTP Relay server to use for relay

**-SMTPCredential**

The SMTP Credentials to use for relay. Needed if the relay requires authentication.

  
  

Example with all parameters:

  
  
  

```powershell

  

Start-ADGroupMemberExport -Domain mcnet.pri -Credential $ADCred `

-DeliveryAddress TestUser@contoso.com -SenderAddress ADGroups@contoso.com `

-SMTPServer mail.contoso.com -SMTPCredential $SMTPCreds

  

```

  
  

**Start-ADTrustCreation** The purpose of this function is to create a conditional forwarder and then the AD Trust for a Target Domain. This function should be ran against a DC in the source domain..

*PARAMETERS*

**-PrimaryDNSServer**

The primary DNS server of the target domain. This is necessary for creation of the conditional forwarder.

**-SecondaryDNSServer**

The secondary DNS server of the target domain. This is optional for creation of the conditional forwarder. A secondary DNS server should be specified in a production environment.

**-Domain**

The target domain to create the conditional forwarder for.

**-TargetADForest**

The target AD Forest to establish a trust with.

**-TargetADCredential**

The Target AD Credential to authenticate as and establish the trust.

  
  

Example with all parameters:

  
  
  

```powershell

  

Start-ADTrustCreation -Domain Contoso.com -PrimaryDNSServer 192.168.1.1 -SecondaryDNSServer 192.168.1.2 `

-TargetADforest Contoso.com -TargetADCredential $ADCred

  

```

  

**Invoke-ADTrustCreation** The purpose of this function is to enabled automated calls of Start-ADTrustCreation from a source json. There are limited options as the JSON provides the parameters.

*PARAMETERS*

**-ConfigFile**

The source config file for the json based call.

  

Example with all parameters:

  
  
  

```powershell

  

Invoke-ADTrustCreation -ConfigFile "C:\Temp\sample.json"

  

```
This function is fed from a json file. 
A sample JSON is as follows:
```acid
{

"TargetADCredential": {

"ADUsername":"admin",

"ADPassword":"Blahblahblah"

},

"Options": {

"PrimaryDNSServer":"192.168.1.1",

"Domain":"Contoso.com",

"TargetADForest":"Contoso.com",

"LogFolderPath":null,

"LogFileName":null

}

}
```

  
  

------------

  
  

### **Private Functions**

  
  

------------

  
  
  

These functions are not exposed when the module is imported. These functions are executed by calls from the public functions.

  
  
  

**Get-ADAccountLegacyPassword** The purpose of this funciton is to return a list of accounts that have passwords older than 90 days.

  

Example with all parameters:

  

```powershell

Get-ADAccountLegacyPassword

```

  

**Get-ADAccountNonExpiryPassword** The purpose of this funciton is to return a list of accounts that do not have expiring passwords.

  
  
  
  
  

Example with all parameters:

  
  
  

```powershell

Get-ADAccountNonExpiryPassword

```

  

**Get-ADDisabledAccount** Get a list of accounts that are Disabled

  
  
  
  
  

Example

  
  
  

```powershell

Get-ADDisabledAccount

```

  
  
  

**Get-ADExpiredAccount** The purpose of this funciton is to return a list of accounts that are expired.

  
  

Example

  
  
  

```powershell

Get-ADExpiredAccount

```

  

**Set-ADGroupReportHTML** Formats a html file with color code tagging from an array input. This function formats the group input array.

  
  
  

Example

  
  
  

```powershell

Set-ADGroupReportHTML -EmailInput $Array -HTMLOutput $HTMLOutput

```

  
  
  

**Set-HTMLReportTagging** This function formats the input array built by Start-ADAccountAudit. It performs various color formatting and table operations to present a readable report on the status of each operation.

  
  
  

Example

  
  
  

```powershell

Set-HTMLReportTagging -EmailInput $Array -HTMLOutput $HTMLOutput

```

  
  

**New-ADTrust** This function is to create a new AD Trust for a target AD Forest

  
  
  

Example

  
  
  

```powershell

New-ADTrust -TargetADForest Contoso.com -TargetADCredential $TargetADCred

```

  

**New-DNSConditionalForwarder** This function is to create a conditional forwarder for a target domain.

  
  
  

Example

  
  
  

```powershell

New-DNSConditionalForwarder -Domain Contoso.com -PrimaryDNSServer 192.168.1.1 -SecondaryDNSServer 192.168.1.2

```
