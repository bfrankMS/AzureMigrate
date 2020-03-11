#add hyper-v Host to hosts file
"`n192.168.1.1`tcmhost`n" | Out-File -Append  -FilePath 'C:\Windows\System32\drivers\etc\hosts' -Encoding ascii


#toggle IE Enhanced Security Configuration for Admins
$ieESCAdminPath = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}"
$ieESCAdminEnabled = (Get-ItemProperty -Path $ieESCAdminPath).IsInstalled
$ieESCAdminEnabled = [int] (-not ($ieESCAdminEnabled))
Set-ItemProperty -Path $ieESCAdminPath -Name IsInstalled -Value $ieESCAdminEnabled
