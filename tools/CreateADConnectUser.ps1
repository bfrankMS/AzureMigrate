<#

    See: https://docs.microsoft.com/en-us/azure/active-directory/hybrid/how-to-connect-configure-ad-ds-connector-account

#>


Install-WindowsFeature RSAT-AD-Tools

Import-Module "C:\Program Files\Microsoft Azure Active Directory Connect\AdSyncConfig\AdSyncConfig.psm1"
Import-Module ActiveDirectory

New-ADUser -Name "ADAccount" -PasswordNeverExpires $true -SamAccountName "ADAccount" -UserPrincipalName "ADAccount@contosomortgage.local" -AccountPassword(Read-Host -AsSecureString "Input Password") -Enabled $true

Set-ADSyncPasswordHashSyncPermissions -ADConnectorAccountName "ADAccount" -ADConnectorAccountDomain "contosomortgage" -Confirm:$false