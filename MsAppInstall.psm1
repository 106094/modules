
Function MsAppInstall([string]$para1,[string]$para2){

    Add-Type -AssemblyName System.Windows.Forms
    #Start-Process ms-windows-store://search/?query=AV1%20Video%20Extension%20App

    $nonlog_flag=$para2

    if($PSScriptRoot.length -eq 0){
        $scriptRoot="C:\testing_AI\modules\"
    }else{
        $scriptRoot=$PSScriptRoot
    }

    $action="MSAppInstall_$($para1)"
    $tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
    $tcnumber=((get-content $tcpath).split(","))[0]
    $tcstep=((get-content $tcpath).split(","))[1]
    $picpath=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\"
    if(-not(test-path $picpath)){new-item -ItemType directory -path $picpath |out-null}

    $actionss ="screenshot"
    Get-Module -name $actionss|remove-module
    $mdpath=(Get-ChildItem -path $scriptRoot -r -file |?{$_.name -match "^$actionss\b" -and $_.name -match "psm1"}).fullname
    Import-Module $mdpath -WarningAction SilentlyContinue -Global
    
    #Find AppID
    
    #region old method 
    <#selenium
    $actionse ="selenium_prepare"

    Get-Module -name $actionse|remove-module
    $mdpath=(Get-ChildItem -path $scriptRoot -r -file |?{$_.name -match "^$actionse\b" -and $_.name -match "psm1"}).fullname
    Import-Module $mdpath -WarningAction SilentlyContinue -Global

    &$actionse -para1 "edge" -para2 "nonlog"

    Get-ChildItem  "C:\testing_AI\modules\selenium\WebDriver.dll" |Unblock-File 
    Add-Type -Path "C:\testing_AI\modules\selenium\WebDriver.dll"
    $driver = New-Object OpenQA.Selenium.Edge.EdgeDriver
    $driver.Manage().Window.Maximize()
    $driver.Navigate().GoToUrl("https://www.microsoft.com/en-us")

    Start-Sleep -Seconds 60

    [System.Windows.Forms.SendKeys]::SendWait("{ESC}")
    $jscommand = "var searchb = document.getElementById('search');"
    $jscommand += "searchb.click()"
    $driver.ExecuteScript($jscommand)
    
    Set-Clipboard -value $para1
    Start-Sleep -Seconds 5
    [System.Windows.Forms.SendKeys]::SendWait("^v")
    #$jscommand = "var searchtext = document.getElementById('cli_shellHeaderSearchInput');"
    #$jscommand += "searchtext.value = '" + $para1 +"';"
    #$jscommand += "searchtext.click();"
    #$driver.ExecuteScript($jscommand)
    #[System.Windows.Forms.SendKeys]::SendWait($para1)


    #------  
    $keyword = "AV1"

    do{

     Write-Host "waitting to get MSApp id"

    Start-Sleep -Seconds 10

    $webtext = $driver.PageSource  

    $pattern = 'href="(.*?)"'
    $matches = [regex]::Matches($webtext, $pattern)
    $urllist = @()
    if ($matches.Count -gt 0) {
        foreach ($match in $matches) {
            $urllist += $match.Groups[1].Value
        }
    }
    else {
        Write-Host "not find href"
    }
    $urljudge = $para1.Replace(" ","-")

    foreach($list in $urllist){
        if($list -match "/$urljudge/"){
           $Appid = $list.Split("/")[$list.Split("/").length-1]
        }
    }
    
   } until ($Appid)

   Write-Host "get MSApp id $Appid"



   # if ($webtext -match $keyword) {
   #     $index = $webtext.IndexOf($keyword)
   #     $result = $webtext.Substring($index + $keyword.Length)
   #     Write-Host "find: $result"
   # }
   # else {
   #     Write-Host "not find"
   # }

    #------

    #Start-Sleep -Seconds 10
    #[System.Windows.Forms.SendKeys]::SendWait("{DOWN}")
    #Start-Sleep -Seconds 10
    #[System.Windows.Forms.SendKeys]::SendWait("{ENTER}")
    #Start-Sleep -Seconds 10
    #$currenturl = $driver.Url
    #$Appid = [regex]::Match($currenturl, "/([A-Za-z0-9]+)\?").Groups[1].Value
   
    $driver.Close()
    $driver.Dispose()

   #selenium#>
   #endregion old method     
        
    ### start wu ###

    $actionmd="enable_wu"
    Get-Module -name $actionmd|remove-module
    $mdpath=(Get-ChildItem -path $scriptRoot\* -r -file |?{$_.name -match "^$actionmd\b" -and $_.name -match "psm1"}).fullname
    Import-Module $mdpath -WarningAction SilentlyContinue -Global

    &$actionmd -para1 nonlog

    
     ###  search app ###

    $srch= winget search $para1 --source=msstore --accept-source-agreements
    $Appid=$srch[-1].Replace($para1,"").split("")[1]
   
     ###  install app ###

    $installmsapp=`
    winget install `
            --id $Appid `
            --accept-package-agreements `
            --accept-source-agreements `
            --silent
   
   $results=$installmsapp[-1]
   
  #region old method 
   <### open msstore ## check if fail open

    Start-Process ms-windows-store://pdp/?ProductId=$Appid   
    Start-Sleep -Seconds 25
           
        [System.Windows.Forms.SendKeys]::SendWait("{tab}")
        Start-Sleep -Seconds 2
        [System.Windows.Forms.SendKeys]::SendWait("+{tab}")
        Start-Sleep -Seconds 2
        [System.Windows.Forms.SendKeys]::SendWait(" ")
          
    Start-Sleep -Seconds 10

    [System.Windows.Forms.SendKeys]::SendWait("%{F4}") ## close once for fail open login window

    Start-Sleep -Seconds 2

    if((Get-Process -Name "*WinStore*") -eq $null){
        Start-Process ms-windows-store://pdp/?ProductId=$Appid   
        Start-Sleep -Seconds 25
      
        [System.Windows.Forms.SendKeys]::SendWait("{tab}")
        Start-Sleep -Seconds 2
        [System.Windows.Forms.SendKeys]::SendWait("+{tab}")
        Start-Sleep -Seconds 2
        [System.Windows.Forms.SendKeys]::SendWait(" ")
          
    }


    $judge = "*" + $para1.Replace(" ","") + "*"
    $runbefore = Get-Date
   # $running = Get-Date
    $flag = 0
  
    do{       
     
     echo "Waiting for app installation to complete..."
      Start-Sleep -Seconds 20
       $running = Get-Date

        if(($running - $runbefore).TotalMinutes -gt 5){ 
        
            $runbefore = Get-Date
           #$running = Get-Date
            $flag += 1
         if($flag -gt 3){
                break
                 echo "App installation fail 3 times."
            }
    else{
            Stop-Process -Name "*WinStore*"
            Start-Sleep -Seconds 5
            Start-Process ms-windows-store://pdp/?ProductId=$Appid   
            Start-Sleep -Seconds 25    
            [System.Windows.Forms.SendKeys]::SendWait("{tab}")
            Start-Sleep -Seconds 2
            [System.Windows.Forms.SendKeys]::SendWait("+{tab}")
            Start-Sleep -Seconds 2
            [System.Windows.Forms.SendKeys]::SendWait(" ")
          

          }

        }
        
    }until(Get-AppxPackage -Name $judge -ErrorAction SilentlyContinue)


    ##screenshot##
   &$actionss  -para3 nonlog -para5 $para1

    if(Get-AppxPackage -Name $judge){
       echo "App installation has completed."
        $results="OK"
        $appinfo = Get-AppxPackage -Name $judge
        $infolog = @()
        $infolog += "Successful Install App"
        $infolog += "AppVersion:" + $appinfo.Version
        $infolog += "PackageFullName:" + $appinfo.PackageFullName
        Set-Content -Path "$picpath\$($para1).txt" -Value $infolog
    }else{
        $results="Instsll Failed"
    }
       
    $Index="check windowsupdate & appinstall"

    Stop-Process -Name WinStore.App

    ###> 
  #endregion

    ### disable wu ###

    $actionmd="disable_wu"
    Get-Module -name $actionmd|remove-module
    $mdpath=(Get-ChildItem -path $scriptRoot\* -r -file |?{$_.name -match "^$actionmd\b" -and $_.name -match "psm1"}).fullname
    Import-Module $mdpath -WarningAction SilentlyContinue -Global

    &$actionmd -para1 nonlog


  ### save logs ##  

    if($nonlog_flag.Length -eq 0){
        Get-Module -name "outlog"|remove-module
        $mdpath=(Get-ChildItem -path "C:\testing_AI\modules\"  -r -file |?{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
        Import-Module $mdpath -WarningAction SilentlyContinue -Global

        #write-host "Do $action!"
        outlog $action $results  $tcnumber $tcstep $index
    }


}


# 匯出模絁E�E�E�E�E�E�E�E�E�E�E�E�E�E�E�E�E員
Export-ModuleMember -Function MsAppInstall