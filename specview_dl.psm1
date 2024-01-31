function specview_dl ([string]$para1,[string]$para2){

    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force;
     
    if($PSScriptRoot.length -eq 0){
        $scriptRoot="C:\testing_AI\modules"
    }else{
        $scriptRoot=$PSScriptRoot
    }

    $spectype="SPECviewperf2020"

        if( $para1 -match "work"){
            $spectype="SPECworkstation"
        }
  
    $nonlog_flag=$para2

    $actionsln ="selenium_prepare"
    Get-Module -name $actionsln|remove-module
    $mdpath=(get-childitem -path $scriptRoot -r -file |where-object{$_.name -match "^$actionsln\b" -and $_.name -match "psm1"}).fullname
    Import-Module $mdpath -WarningAction SilentlyContinue -Global
        
    
    $actionsfe ="filexplorer"
    Get-Module -name $actionsfe|remove-module
    $mdpath=(get-childitem -path $scriptRoot -r -file |where-object{$_.name -match "^$actionsfe\b" -and $_.name -match "psm1"}).fullname
    Import-Module $mdpath -WarningAction SilentlyContinue -Global
        
    $action="$spectype Download from website"
    $tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
    $tcnumber=((get-content $tcpath).split(","))[0]
    $tcstep=((get-content $tcpath).split(","))[1]
    $picpath=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\"
    if(-not(test-path $picpath)){new-item -ItemType directory -path $picpath |out-null}

    $results="OK"
    $index="download ok"
             
    &$actionsln  edge nonlog
           
    get-childitem  "C:\testing_AI\modules\selenium\WebDriver.dll" |Unblock-File 
    Add-Type -Path "C:\testing_AI\modules\selenium\WebDriver.dll"

    try{$driver = New-Object OpenQA.Selenium.Edge.EdgeDriver}
    catch{
    $results="NG"
    $index="fail to install web driver"
    }

    if($results -ne "NG"){

        $website="https://gwpg.spec.org/benchmarks/benchmark/specviewperf-2020-v3-1/"
        $filename="$spectype*.exe"
        if($spectype -eq "SPECworkstation"){
            $website="https://gwpg.spec.org/benchmarks/benchmark/specworkstation-3_1/"
            $filename="$spectype*.zip"
        }

    [OpenQA.Selenium.Interactions.Actions]$actions = New-Object OpenQA.Selenium.Interactions.Actions ($driver)
    $actions = New-Object OpenQA.Selenium.Interactions.Actions($driver)

    $driver.Manage().Window.Maximize()
    $driver.Navigate().GoToUrl("$website")
    $nowtime =Get-Date
    do{
    start-sleep -s 5
     $downloadbt=$driver.FindElement([OpenQA.Selenium.By]:: ID("jet-tabs-control-5272"))
      $timepass= (New-TimeSpan -start $nowtime -end (get-date)).TotalSeconds
         }until($downloadbt.Enabled -eq $true -or $timepass -gt 120)
    if($timepass -gt 120){
        $results="NG"
        $index="fail to open download page of $spectype"
    }
    elseif($downloadbt.Enabled -eq $true){
        $downloadbt.click()
        start-sleep -s 5
        $downloadbt2=$driver.FindElement([OpenQA.Selenium.By]::XPath("//*[@id=""freeDownloadBTN""]/div/div/a/span/span"))
        $downloadbt2.click()
        start-sleep -s 5
        $downloadbt3=$driver.FindElement([OpenQA.Selenium.By]::Id("form-field-name-1"))
        $downloadbt3.Click()
        start-sleep -s 5
        $downloadbt4=$driver.FindElement([OpenQA.Selenium.By]::Id("form-field-field_33b22f6"))
        if(!($downloadbt4.Selected)){
            $downloadbt4.Click()
        }
        start-sleep -s 5
        $downloadbt5=$driver.FindElement([OpenQA.Selenium.By]::XPath("//*[@id=""freeDownloadsForm""]/div/div[8]/button/span/span[2]"))
        $downloadbt5.Click()
        $starttime=get-date
        write-output " $spectype start downloading: $starttime"
        start-sleep -s 10
        #region screenshot
        $timenow=get-date -format "yyMMdd_HHmmss"
        $savepic=$picpath+"$($timenow)_step$($tcstep)_startdownloading.jpg"
        $screenshot = $driver.GetScreenshot()
        $screenshot.SaveAsFile( $savepic, [OpenQA.Selenium.ScreenshotImageFormat]::Jpeg)
        #endregion
        
        do{
          Start-Sleep -s 60
          $timepassed= (New-TimeSpan -start $starttime -end (get-date)).TotalMinutes
         $checkdownload=test-path -Path "$env:USERPROFILE\Downloads\$filename"
         #https://spec.cs.miami.edu/downloads/gpc/opc/viewperf/SPECviewperf2020.3.1.exe
        }until ($checkdownload -or $timepassed -gt 180)
         if($checkdownload){
        write-output "$spectype download complete: $(get-date)"
        Move-Item "$env:USERPROFILE\Downloads\$filename" -Destination "$env:USERPROFILE\desktop" -Force
        &$actionsfe -para1 "$env:USERPROFILE\desktop\" -para2 "nolog"
        Move-Item "$env:USERPROFILE\desktop\$filename" -Destination $picpath -Force
        }
        else{
         $results="NG"
         $index="fail to download $spectype in $($timepassed) minites"
         }

        }
        
    $driver.Close()
    $driver.Quit()
    
    if((get-process -Name msedgedriver -ErrorAction SilentlyContinue)){Stop-Process -Name msedgedriver}

    }
    
    ### write to log ###
    
    if($nonlog_flag.Length -eq 0 -and !$writelog){
    Get-Module -name "outlog"|remove-module
    $mdpath=(get-childitem -path "C:\testing_AI\modules\" -r -file |where-object{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
    Import-Module $mdpath -WarningAction SilentlyContinue -Global

    #write-host "Do $action!"
    outlog $action $results $tcnumber $tcstep $index
    }
    
 }
  
  export-modulemember -Function specview_dl