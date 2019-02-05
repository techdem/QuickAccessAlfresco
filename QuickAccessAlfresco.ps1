Param(
    [String]$domainName = 'localhost:8443',
    [String]$mapDomain = "localhost",
    [String]$prependToLinkTitle = "Site - ",
    [String]$icon,
    [String]$protocol = "",
    [String]$disableHomeAndShared = "0",
    [String]$folderName = "Alfresco"
)
function Build-Url([String] $urlParams="") {
    $whoAmI = WhoAm-I
    $url = "https://$domainName/share/proxy/alfresco/api/people/$whoAmI/sites/"

    if ($urlParams) {
        $url = "$($url)?$($urlParams)"
    }
    return $url
}

function WhoAm-I {
    return SearchAD
}

function SearchAD {
    $user = $env:UserName
    $searchAD = [adsisearcher]"(&(objectCategory=person)(objectClass=user)(samaccountname=$user))"
    $whoAmI = $searchAD.FindOne()
    return $whoAmI.Properties.samaccountname
}

function Get-ListOfSites {
    Param([String] $url)
    Set-SecurityProtocols
    $webclient = new-object System.Net.WebClient
    $webclient.UseDefaultCredentials=$true
    try {
        [array]$response = $webclient.DownloadString($url) | ConvertFrom-Json
    }
    catch {
        [array]$response = @()
    }
    return $response
}

function Set-SecurityProtocols ($protocols="Tls,Tls11,Tls12") {
    $AllProtocols = [System.Net.SecurityProtocolType]$protocols
    [System.Net.ServicePointManager]::SecurityProtocol = $AllProtocols
}
function Create-HomeAndSharedLinks {
    $links = @{}
    $links[0] = Create-Link @{"title" = "Home"; "description" = "My Files"; "shortName" = WhoAm-I;} "User Homes" -protocol $protocol
    $links[1] = Create-Link @{"title" = "Shared"; "description" = "Shared Files"; "shortName" = "Shared";} "Shared" -protocol $protocol
    return $links
}

function CopyIcon($icon="") {
    $testPath = (-Not (Test-Path "$appData\$icon"))

    if ($icon -And $testPath) {
        Copy-Item $icon "$appData\"
        return $true
    }

    return $false
}

function Create-Link($link, [String] $whatPath = "Sites", $protocol="") {

    if ($link.Count -eq 0) {
        return $false
    }

    $path = "$linkBaseDir\$($link.title).lnk"

    if($link.prepend){
        $path = "$linkBaseDir\$($link.prepend)$($link.title).lnk"
    }

    $findPath = @{
        "Sites" = "\\$mapDomain\Alfresco\$whatPath\" + $link.shortName + "\documentLibrary"; 
        "User Homes" = "\\$mapDomain\Alfresco\$whatPath\" + $link.shortName;
        "Shared" = "\\$mapDomain\Alfresco\$whatPath";
    }

    if ($protocol -eq "ftps") {
        $findPath = @{
            "Sites" = "ftps://$mapDomain/alfresco/$whatPath/" + $link.shortName + "/documentLibrary"; 
            "User Homes" = "ftps://$mapDomain/alfresco/$whatPath/" + $link.shortName;
            "Shared" = "ftps://$mapDomain/alfresco/$whatPath";
        }
    }

    if ($protocol -eq "webdav") {
        $pathToLower = $whatPath.ToLower()
        $findPath = @{
            "Sites" = "\\$domainName@SSL\alfresco\webdav\$pathToLower\" + $link.shortName + "\documentLibrary"; 
            "User Homes" = "\\$domainName@SSL\alfresco\webdav\$pathToLower\" + $link.shortName;
            "Shared" = "\\$domainName@SSL\alfresco\webdav\Shared";
        }
    }

    if ($protocol -eq "sharepoint") {
        $pathToLower = $whatPath.ToLower()
        $findPath = @{
            "Sites" = "\\$domainName@SSL\alfresco\aos\$pathToLower\" + $link.shortName + "\documentLibrary"; 
            "User Homes" = "\\$domainName@SSL\alfresco\aos\$pathToLower\" + $link.shortName;
            "Shared" = "\\$domainName@SSL\alfresco\aos\Shared";
        }
    }

    $targetPath = $findPath.Get_Item($whatPath)

    if ($targetPath.length -eq 0) {
        return $false
    }

    $wshShell = New-Object -ComObject WScript.Shell
    $shortcut = $wshShell.CreateShortcut("$path")

    $shortcut.TargetPath = $targetPath
    $shortcut.Description = $link.description

    if($link.icon){
        $iconLocation = "$appData\{0}" -f $link.icon.Split('\')[-1]
        $shortcut.IconLocation = $iconLocation
    }
    
    $shortcut.Save()
    return $shortcut
}

function Create-QuickAccessLinks([array]$links, $prepend="", $icon="", $protocol="") {
    $createdLinks = @()

    if($links.Count -gt 0) {
        Delete-Links > $null
    }

    Write-Host $createdLinks
    if (![string]::IsNullOrEmpty($icon)) {
        CopyIcon -icon $icon
        $icon = "$appData\$icon"
    }

    for($i = 0; $i -lt $links.Count; $i++) {
        if (![string]::IsNullOrEmpty($prepend)) {
            Add-Member -InputObject $links[$i] -MemberType NoteProperty -Name prepend -Value $prepend -Force
        }
        if (![string]::IsNullOrEmpty($icon)) {
            Add-Member -InputObject $links[$i] -MemberType NoteProperty -Name icon -Value $icon -Force
        }
        $addLink = Create-Link $links[$i] -protocol $protocol
            if ($addLink -ne $false) {
                $createdLinks += $addLink
            }
    }

    return $createdLinks
}

function Delete-Links {
    $shortcuts = @{}
    $shortcuts.Total = Get-ChildItem -Recurse $linkBaseDir -Include *.lnk
    $shell = New-Object -ComObject WScript.Shell

    foreach ($shortcut in $shortcuts.Total) {
        if ($shell.CreateShortcut($shortcut).targetpath -like "*\*lfresco\*") {
            $shortcuts.Removed++
            Remove-Item $shortcut
        }
        else {
            $shortcuts.User++
        }
    }

    [Runtime.InteropServices.Marshal]::ReleaseComObject($shell) | Out-Null

    return $shortcuts
}
function CopyIcon($icon="") {
    $testPath = (-Not (Test-Path "$appData\$icon"))
    if ($icon -And $testPath) {
        Copy-Item $icon "$appData\"
        return $true
    }
    return $false
}
function Generate-Config ($fromParams=@{}) {
    $doesConfigExist = Test-Path "$appData\config.json"
    $fromParams | ConvertTo-Json | Set-Content "$appData\config.json"
    if(!$doesConfigExist) {
        $fromParams | ConvertTo-Json | Set-Content "$appData\config.json"
        return $true
    }
    return $false
}

function Read-Config {
    $getConfigContent = Get-Content -Path "$appData\config.json" | Out-String | ConvertFrom-Json
    return $getConfigContent
}

function Parse-Config {
    $getConfigContent = Read-Config
    $switches = $getConfigContent.switches
    $parseSwitches = ""
    $switches.psobject.properties.name | ForEach-Object{
        $parseSwitches += "-{0} '{1}' " -f $_, $switches.$_
    }

    $sites = $getConfigContent.sites
    $parseSites = @(0) * $sites.Count
    for ($i = 0; $i -lt $sites.Count; $i++) {
        if ($sites[$i].title) {
            $parseSites[$i] = $sites[$i].title
        }
    }
    return @{"switches" = $parseSwitches; "sites" = $parseSites;}
}
function Create-ScheduledTask($taskName) {
    $config = Parse-Config
    $taskPath = ".\runQAA.vbs"

    Set-Content $taskPath "Dim WinScriptHost
    Set WinScriptHost = CreateObject(`"WScript.Shell`")
    WinScriptHost.Run(`"powershell.exe -executionpolicy bypass -command .\QuickAccessAlfresco.ps1 $($config[`"switches`"])`"), 0
    Set WinScriptHost = Nothing"

    $taskIsRunning = Start-Process schtasks.exe -ArgumentList "/query /tn $taskName" -WindowStyle hidden -ErrorAction SilentlyContinue

    if($taskIsRunning) {
        schtasks.exe /end /tn $taskName
        schtasks.exe /delete /tn $taskName /f
    }

    $createTask = schtasks.exe /create /tn "$taskName" /sc HOURLY /tr $taskPath /f

    return $createTask
}
function Check-System {
    
    $systemCheck = @{}

    $systemCheck["PS"] = if($PSVersionTable.PSVersion.Major -gt 2) {$true} else {$false}

    $systemCheck["OS"] = if([System.Environment]::OSVersion.Version.Major -gt 6) {$true} else {$false}

    return $systemCheck
}

function Create-Win10Folder {

    New-Item -ItemType directory -Path "$env:userprofile\$folderName" -Force
    $shell = New-Object -ComObject shell.application
    $shell.Namespace("$env:userprofile\$folderName").Self.InvokeVerb("pintohome")

    return $shell
}

$systemCheck = Check-System

if ($domainName -inotmatch 'localhost' -and $systemCheck["PS"]) {

    if ($systemCheck["OS"]) {

        Create-Win10Folder
        $linkBaseDir = "$env:userprofile\$folderName"
    }
    else {
    
        $linkBaseDir = "$env:userprofile\Links"
    }
    
    $appData = "$env:APPDATA\QuickAccessAlfresco"
    $fromUrl = Build-Url
    $listOfSites = Get-ListOfSites $fromUrl
    Generate-Config @{"switches" = $PsBoundParameters; "sites" = $listOfSites}
    
    Create-ScheduledTask "QuickAccessAlfresco"

    Create-QuickAccessLinks $listOfSites -prepend $prependToLinkTitle -icon $icon -protocol $protocol

    if ($disableHomeAndShared -eq 0) {
        Create-HomeAndSharedLinks
    }
}
