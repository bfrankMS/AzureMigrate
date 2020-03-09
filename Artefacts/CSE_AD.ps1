param(
    [Parameter(Mandatory=$True,Position=1)]
    [string] $DomainName,

    [Parameter(Mandatory=$True,Position=2)]
    [string] $Password
)

#this will be our temp folder - need it for download / logging

$tmpDir = "c:\temp\" 

#create folder if it doesn't exist
if (!(Test-Path $tmpDir)) { mkdir $tmpDir -force}

#write a log file with the same name of the script
Start-Transcript "$tmpDir\$($SCRIPT:MyInvocation.MyCommand).log"


#To install AD we need PS support for AD first
Install-WindowsFeature AD-Domain-Services -IncludeAllSubFeature -IncludeManagementTools
Import-Module ActiveDirectory


#Do we find Data disks (raw by default) in this VM? 
$RawDisks = Get-Disk | where PartitionStyle -eq "RAW"

$driveLetters = ("f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z")

$i = 0
foreach ($RawDisk in $RawDisks)
{
    $currentDriveLetter = $driveLetters[$i]

    New-Volume -DiskNumber $RawDisk.Number -FriendlyName "Data$i" -FileSystem NTFS -DriveLetter $currentDriveLetter
    $i++
}

$SecurePassword = ConvertTo-SecureString "$Password" -AsPlainText -Force

#Do we have Data Disk? 
$DataDisk0 = Get-Volume -FileSystemLabel "Data0" -ErrorAction SilentlyContinue

switch ($DataDisk0 -ne $null)
{
    'True'      #Active Directory database storage on first Data Disk 
    {
        $drive = "$($DataDisk0.DriveLetter):"
        #Install-ADDSForest -DomainName "$DomainName" -DatabasePath "$drive\NTDS" -SysvolPath "$drive\SYSVOL" -LogPath "$drive\Logs" -ForestMode Default -DomainMode Default -InstallDns:$true -SafeModeAdministratorPassword $SecurePassword -CreateDnsDelegation:$false -NoRebootOnCompletion:$true -Force:$true
    }
    
    #nope - not recommended 
    Default 
    {
        #Install-ADDSForest -DomainName "$DomainName" -ForestMode Default -DomainMode Default -InstallDns:$true -SafeModeAdministratorPassword $SecurePassword -CreateDnsDelegation:$false -NoRebootOnCompletion:$true -Force:$true
    }
}

#add some DNS forwarders to our DNS server to enable external name resolution
Add-DnsServerForwarder -IPAddress 168.63.129.16  #add azure intrinsic Name server - this works when VM is in Azure / when onprem you need DNS proxy in azure
Add-DnsServerForwarder -IPAddress 8.8.8.8        #allow external name resolution
Add-DnsServerForwarder -IPAddress 208.67.222.222 #add another public dns server

#download the AD connect tool to synch with AAD
$Downloads = @( `
    "https://download.microsoft.com/download/B/0/0/B00291D0-5A83-4DE7-86F5-980BC00DE05A/AzureADConnect.msi")

    foreach ($download in $Downloads)
    {
        $downloadPath = $tmpDir + "\$(Split-Path $download -Leaf)"
        if (!(Test-Path $downloadPath ))    #download if not there
        {
            $bitsJob = start-bitstransfer "$download" "$downloadPath" -Priority High -RetryInterval 60 -Verbose -TransferType Download #wait until downloaded.
            Get-BitsTransfer -Verbose -AllUsers
        }
    }

stop-transcript