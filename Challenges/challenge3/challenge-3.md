# Challenge 3: Implement hybrid networking and resilient authentication

[back](../../README.md)

## Introduction ##
In this challenge you establish a hybrid connectivity between the on-premises datacenter and Azure. It will allow you to establish domain controllers in Azure, making authentication to Active Directory more resilient. Having domain controllers in Azure will also reduce latency for authentication.

## Success criteria ##
- Provide answer to what are the 4 Azure artefacts needed for a S2S VPN connection to onpremise?:  
  
| Resource Type |  Name |
|---|---|
| Item**1** | [naming convention samples](https://docs.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/naming-and-tagging) | 
| Item**2** | _name_ |
| Item**3** | _name_ |
| Item**4** | _name_ |

- Successfully RDP into an Azure VM from onpremise
- Have a domain controller in azure in its own site (e.g. "Azure Site") replicating with onprem.
  
## Start here ##
To **save some time** we will use some **ARM templates to setup** some stuff. 
### 1. <a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FbfrankMS%2FAzureMigrate%2Fmaster%2FArtefacts%2FVNET.json"><img src="deploytoazure.png"/></a> - will create the VNET
### 2. <a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FbfrankMS%2FAzureMigrate%2Fmaster%2FArtefacts%2FNSGs.json"><img src="deploytoazure.png"/></a> - will create the NSGs
### 3. <a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FbfrankMS%2FAzureMigrate%2Fmaster%2FArtefacts%2FVPN.json"><img src="deploytoazure.png"/></a> - will create the VPN in Azure  
->grab yourself a coffee as this will take some time (approx 30 mins)
### 4. Now configure your onpremise firewall to do VPN with Azure. See [here](https://github.com/CSA-OCP-GER/azure-developer-college/blob/master/day1/challenges/Challenge%208/challenge-8.md#onpremise-configure-your-onpremise-vpn-counterpart-eg-ipfire) for details.  

**!! Important !!:** At "_...Select the following algorithms / suites for the connection..._" **use the cipersuites** that were used for **our azure vpn gateway** connection. What are they?  
```
[Azure Portal] -> Resource Groups -> %Your Resource Group% -> Connections -> S2S-cn-azure-to-onprem -> Download configuration

Device vendor :  Generic samples
Device family :  Device parameters
Firmware version :  1.0  
  
->Download configuration. 
```  
**Open the .txt file**. Can you figure out **what algorithm is being used for IKE and ESP ('ipsec')?**  
>**BTW** 'group14' = 'MODP-2048'  
> ;-)

### 5. Only when the firewall reports _green_ for S2S connection to Azure!  
### Do: <a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FbfrankMS%2FAzureMigrate%2Fmaster%2FArtefacts%2FAD.json"><img src="deploytoazure.png"/></a> - it will create the DC in Azure  
  
  
### 6. Can you RDP into the VM ?  
If so make sure the Azure DC is in a different replication site (e.g. using Sites and Services to create an 'Azure Site').  
  

[back](../../README.md)  
