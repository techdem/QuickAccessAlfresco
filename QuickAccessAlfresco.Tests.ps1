﻿$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"

.".\QuickAccessAlfresco.ps1"

$whoAmI = $env:UserName
$url = "http://localhost:8080/alfresco/service/api/people/$whoAmI/sites/"
$convertedJSON = @{0 = @{"title" = "Benchmark"; "description" = "This site is for bench marking Alfresco"; "shortName" = "benchmark";};1 = @{"title" = "Recruitment"; "description" = "Recruitment site"; "shortName" = "Recruitment";};}
$homeAndShared = @{0 = @{"title" = "Home"; "description" = "My Files"; "shortName" = $env:UserName;};1 = @{"title" = "Shared"; "description" = "Shared Files"; "shortName" = "Shared";};}

function Clean-Up($links) {
    # Clean up after test
    $testLink = "$env:userprofile\Links\"
    foreach($link in $links) {
        if (Test-Path "$($testLink)$($link).lnk") {
            Remove-Item "$($testLink)$($link).lnk"
        } else {
            Write-Host "Can not find $link"
        }
    }
}

Describe 'Build-Url' {
  It "Should build the URL for connecting to Alfresco." {
    Build-Url | Should -Be $url
  }

  It "Should build the URL for connecting to Alfresco with paramaters prepended." {
    $urlWithParams = Build-Url "hello=world"
    $urlWithParams | Should -Be "http://localhost:8080/alfresco/service/api/people/$whoAmI/sites/?hello=world"
  }
}

Describe 'Get-ListOfSites' {
    It "Should retrieve a list of sites for the currently logged in user." {
        $convertedObject = (Get-Content stub\sites.json)
        Get-ListOfSites $url | Should Match $convertedJSON[0].title
    }
}

Describe 'Create-HomeAndSharedLinks' {
    It "Should create links for the user home and shared" {
        $createHomeAndShared = Create-HomeAndSharedLinks 
        $createHomeAndShared[0].Description | Should Match $homeAndShared[0].description
        $createHomeAndShared[0].TargetPath | Should Be "\\localhost\Alfresco\User Homes\$whoAmI"
        $createHomeAndShared[1].Description | Should Match $homeAndShared[1].description
        $createHomeAndShared[1].TargetPath | Should Be "\\localhost\Alfresco\Shared"
    }
}

Describe 'Create-Link' {
    It "Should create Quick Access link to Alfresco." {
        $createLink = Create-Link $convertedJSON[0]
        $result = Test-Path "$env:userprofile\Links\Benchmark.lnk"       
        $createLink | Should be $result
        $createLink.Description | Should Match $convertedJSON[0].description
    }

    It "Should not create Quick Access link to Alfresco because it exists." {
        $createLink = Create-Link $convertedJSON[0]
        $createLink | Should be "False"
    }

    It "Should not create an empty Quick Access link to Alfresco." {
        $createLink = Create-Link @{}
        $createLink | Should be "False"
    }

    Clean-Up @("Home", "Shared", "Benchmark")

    It "Should pepend text to the Quick Access link to Alfresco." {
        $convertedJSON[0]["prepend"] = "Alfresco - "
        $createLink = Create-Link $convertedJSON[0]
        $result = Test-Path "$env:userprofile\Links\Alfresco - Benchmark.lnk"
        $createLink | Should Not Be "False"
        $createLink.Description | Should Match $convertedJSON[0].description

    }    
}

Clean-Up @("Alfresco - Benchmark")
    
Describe 'Create-QuickAccessLinks' {
    It "Should create all Quick Access links to sites within Alfresco" {
        $createLinks = Create-QuickAccessLinks $convertedJSON
        $createLinks[0].Description | Should Match $convertedJSON[0].description
        $createLinks[1].Description | Should Match $convertedJSON[1].description
    }
}

Clean-Up @("Benchmark", "Recruitment")
