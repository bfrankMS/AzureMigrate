<#################################

    This script downloads and installs the Azure Log analytics agents for Azure Migrate
    author: bfrank
    date: 10.3.2020

    run this on the hyper-v machine

##################################>

#region Helper Functions
  
function WorkspaceInfo () {
    [void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") 
    [void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") 
    $objForm = New-Object System.Windows.Forms.Form 
    $objForm.Text = "Your Azure Log Analytics workspaceID & workspaceKey"
    $objForm.Size = New-Object System.Drawing.Size(300, 300) 
    $objForm.StartPosition = "CenterScreen"

    $objForm.KeyPreview = $True
    $objForm.Add_KeyDown( { if ($_.KeyCode -eq "Enter") 
            { $x = $objTextBox.Text; $objForm.Close() } })
    $objForm.Add_KeyDown( { if ($_.KeyCode -eq "Escape") 
            { $objForm.Close() } })

    $OKButton = New-Object System.Windows.Forms.Button
    $OKButton.Location = New-Object System.Drawing.Size(75, 180)
    $OKButton.Size = New-Object System.Drawing.Size(75, 23)
    $OKButton.Text = "OK"
    $OKButton.Add_Click( { $x = $objTextBox.Text; $objForm.Close() })
    $objForm.Controls.Add($OKButton)

    $CancelButton = New-Object System.Windows.Forms.Button
    $CancelButton.Location = New-Object System.Drawing.Size(150, 180)
    $CancelButton.Size = New-Object System.Drawing.Size(75, 23)
    $CancelButton.Text = "Cancel"
    $CancelButton.Add_Click( { $objForm.Close() })
    $objForm.Controls.Add($CancelButton)

    $objLabelGroup = New-Object System.Windows.Forms.Label
    $objLabelGroup.Location = New-Object System.Drawing.Size(10, 20) 
    $objLabelGroup.Size = New-Object System.Drawing.Size(280, 20) 
    $objLabelGroup.Text = "Your workspaceID?"
    $objForm.Controls.Add($objLabelGroup) 

    $objTextBoxGroupNumber = New-Object System.Windows.Forms.TextBox 
    $objTextBoxGroupNumber.Location = New-Object System.Drawing.Size(10, 40) 
    $objTextBoxGroupNumber.Size = New-Object System.Drawing.Size(260, 20) 
    $objForm.Controls.Add($objTextBoxGroupNumber) 

    $objLabelHost = New-Object System.Windows.Forms.Label
    $objLabelHost.Location = New-Object System.Drawing.Size(10, 80) 
    $objLabelHost.Size = New-Object System.Drawing.Size(280, 20) 
    $objLabelHost.Text = "Your workspaceKey"
    $objForm.Controls.Add($objLabelHost) 

    $objTextBoxHostNumber = New-Object System.Windows.Forms.TextBox 
    $objTextBoxHostNumber.Location = New-Object System.Drawing.Size(10, 100) 
    $objTextBoxHostNumber.Size = New-Object System.Drawing.Size(260, 20) 
    $objForm.Controls.Add($objTextBoxHostNumber) 

    $objForm.Topmost = $True

    $objForm.Add_Shown( { $objForm.Activate() })
    [void] $objForm.ShowDialog()

    $workspaceID = $objTextBoxGroupNumber.Text
    $workspaceKey = $objTextBoxHostNumber.Text
    return $workspaceID, $workspaceKey
}

function Show-Message ($message) {
    [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
    [System.Windows.Forms.MessageBox]::Show($message)
}

set-variable -name returnvalues -value $(WorkspaceInfo) -Scope global
if ($returnvalues[0] -notmatch '^[A-Za-z0-9]{8}-[A-Za-z0-9]{4}-[A-Za-z0-9]{4}-[A-Za-z0-9]{4}-[A-Za-z0-9]{12}$') {
    Show-Message "passt nicht & darf nicht leer sein"
    exit
}
if ($returnvalues[1] -notmatch '^.{88}$') {
    Show-Message "passt nicht & darf nicht leer sein"
    exit
}

#endregion

#this will be our temp folder - need it for download / logging

$tmpDir = "c:\temp\" 

#create folder if it doesn't exist
if (!(Test-Path $tmpDir)) { mkdir $tmpDir -force }

#download the Monitoring and dependency agent
$downloadURIs = @{
    'InstallDependencyAgent-Windows.exe' = 'http://aka.ms/dependencyagentwindows'
    'MMASetup-AMD64.exe'                 = "https://go.microsoft.com/fwlink/?LinkId=828603"
}
foreach ($downloadURI in $downloadURIs.GetEnumerator()) {
    Invoke-WebRequest -Uri "$($downloadURI.Value)" -OutFile "$tmpDir\$($downloadURI.Name)"
}


$vms = Get-VM cm*

#easy way to copy from the hyper-v into the VM
$vms | Enable-VMIntegrationService  "Guest Service interface"
Start-Sleep -Seconds 15
foreach ($vm in $vms) {
    foreach ($downloadURI in $downloadURIs.GetEnumerator()) {
        Write-Output "copy file $($downloadURI.Name) to $($vm.VMName)"
        Copy-VMFile $($vm.VMName) -SourcePath "$tmpDir\$($downloadURI.Name)" -DestinationPath "C:\Temp\$($downloadURI.Name)" -CreateFullPath -FileSource Host -Force
    }
}

#now we install the agents on the vms
$IPs = @("192.168.0.6", "192.168.0.3", "192.168.0.7", "192.168.0.4", "192.168.0.5", "192.168.0.2")

$workspaceID = $returnvalues[0]
$workspaceKey = $returnvalues[1]

#$workspaceID = "<% your workspace ID from the azure portal %>" #e.g. "d8e5aa38..."
#$workspaceKey = "<% your workspacekey from the azure portal %>" #  e.g. "Pm1AWj2fc.....=="
$credential = Get-Credential -UserName "contosomortgage\administrator" -Message "The demousers password"

#remote into each VM and install the agents unattended...
foreach ($IP in $IPs) {
    Write-Output "installing agents on...$IP"
    set-item wsman:\localhost\Client\TrustedHosts -value $IP -Force

    Invoke-Command -ComputerName $IP -Credential $credential -ArgumentList $workspaceID, $workspaceKey -ScriptBlock {
        param([string]$workspaceID,
            [string] $workspaceKey)
        Start-Process   "C:\Temp\MMASetup-AMD64.exe" -ArgumentList "/c /t:c:\temp\MMASetup" -Wait
        Start-Process "c:\temp\MMASetup\setup.exe" -ArgumentList "/qn NOAPM=1 ADD_OPINSIGHTS_WORKSPACE=1 OPINSIGHTS_WORKSPACE_AZURE_CLOUD_TYPE=0 OPINSIGHTS_WORKSPACE_ID=""$workspaceID"" OPINSIGHTS_WORKSPACE_KEY=""$workspaceKey"" AcceptEndUserLicenseAgreement=1" -Wait

        Start-Process "C:\Temp\InstallDependencyAgent-Windows.exe"  -ArgumentList "/S"  -Wait
    }
}
