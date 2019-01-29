Dim WinScriptHost
    Set WinScriptHost = CreateObject("WScript.Shell")
    WinScriptHost.Run("powershell.exe -executionpolicy bypass -command C:\Projects\QuickAccessAlfresco\QuickAccessAlfresco.ps1 -domainName 'documents.i.opw.ie' -disableHomeAndShared '0' -protocol 'sharepoint' -folderName 'Sites' "), 0
    Set WinScriptHost = Nothing
