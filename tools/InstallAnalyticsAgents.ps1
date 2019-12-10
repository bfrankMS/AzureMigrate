$vms = Get-VM cm*

#easy way to copy from the hyper-v into the VM
$vms | Enable-VMIntegrationService  "Guest Service interface"

foreach ($vm in $vms)
{
    Write-Output "copy to $($vm.VMName)"
    Copy-VMFile $($vm.VMName) -SourcePath "C:\Users\demouser\Downloads\MMASetup-AMD64.exe" -DestinationPath "C:\Temp\MMASetup-AMD64.exe" -CreateFullPath -FileSource Host -Force
    Copy-VMFile $($vm.VMName) -SourcePath "C:\Users\demouser\Downloads\InstallDependencyAgent-Windows.exe" -DestinationPath "C:\Temp\InstallDependencyAgent-Windows.exe" -CreateFullPath -FileSource Host -Force
}

#now we install the 
$IPs = @("192.168.0.6","192.168.0.3","192.168.0.7","192.168.0.4","192.168.0.5","192.168.0.2")

$workspaceID = "<% your workspace ID from the azure portal %>" #e.g. "d8e5aa38..."
$workspaceKey = "<% your workspacekey from the azure portal %>" #  e.g. "Pm1AWj2fc.....=="
$credential = Get-Credential -UserName "contosomortgage\administrator" -Message "The demousers password"

#remote into each VM and install the agents unattended...
foreach ($IP in $IPs)
{
    Write-Output "installing agents on...$IP"
    set-item wsman:\localhost\Client\TrustedHosts -value $IP -Force
    
    Invoke-Command -ComputerName $IP -Credential $credential -ArgumentList $workspaceID,$workspaceKey -ScriptBlock {
        param([string]$workspaceID,
               [string] $workspaceKey)
        Start-Process   "C:\Temp\MMASetup-AMD64.exe" -ArgumentList "/c /t:c:\temp\MMASetup" -Wait
        Start-Process "c:\temp\MMASetup\setup.exe" -ArgumentList "/qn NOAPM=1 ADD_OPINSIGHTS_WORKSPACE=1 OPINSIGHTS_WORKSPACE_AZURE_CLOUD_TYPE=0 OPINSIGHTS_WORKSPACE_ID=""$workspaceID"" OPINSIGHTS_WORKSPACE_KEY=""$workspaceKey"" AcceptEndUserLicenseAgreement=1" -Wait
    
        Start-Process "C:\Temp\InstallDependencyAgent-Windows.exe"  -ArgumentList "/S"  -Wait
    }
   

}


