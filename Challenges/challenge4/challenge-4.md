# Challenge 4: Test migration

[back](../../README.md)

## Introduction ##
In this challenge you will replicate the vms to azure and test if the apps are functional. 

## Requirements: ##
- Tested servers must be fully operational
- You can logon to the servers via onprem (RDP)
- Both web apps are functional & working.
- Tested servers are sandbox'ed - and cannot confuse onpremise resources.

## Questions ## 
- What can you do / use to make the servers accessable using domain credentials even without connectivity to any onpremises?
- What can you do that no public IPs can be associated with Azure-hosted servers?

>**Tip**: To achieve the requirements you would:  
> Setup replication using [Azure Portal] -> Azure Migrate -> ...  
> Configure the which servers should be replicated (which sizes, which disks, .... )  
> When being asked use subnet _snet-testing_ as target subnet for replicated servers.  
> Do a test failover & login to your vms via from onprem.  
  
[back](../../README.md)