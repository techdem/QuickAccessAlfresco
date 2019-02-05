Dim WinScriptHost
    Set WinScriptHost = CreateObject("WScript.Shell")
    WinScriptHost.Run("powershell.exe -executionpolicy bypass -command .\QuickAccessAlfresco.ps1 -domainName 'localhost:8443' -disableHomeAndShared 'False' -mapDomain 'localhost'"), 0
    Set WinScriptHost = Nothing
