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
