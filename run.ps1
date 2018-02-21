$whoAmI = $env:UserName
$webDir = "share\proxy\alfresco\api\people\$whoAmI\sites\"
New-Item -ItemType Directory -Force -Path $webDir
Copy-Item "stub\sites.json" "$webDir\index.json"
Copy-Item "stub\sites.json" "$webDir\sites.json"
New-Item -Name quickaccess_icon.ico  -Force -ItemType File
Start-Process -FilePath "powershell.exe" -ArgumentList "-NoExit", "$pwd\server.ps1" -Verb runas
Invoke-Pester .\QuickAccessAlfresco.Tests.ps1 -CodeCoverage .\QuickAccessAlfresco.ps1
