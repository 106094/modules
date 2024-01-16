function idrac_ResizableBAR ([string]$para1,[string]$para2){

    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force;
    Add-Type -AssemblyName System.Windows.Forms
       
    if($PSScriptRoot.length -eq 0){
        $scriptRoot="C:\testing_AI\modules"
    }else{
        $scriptRoot=$PSScriptRoot
    }
   
    $switches="Disabled"
    if($para1.length -eq 0){
        $switches="Enabled"
    }
 
   $nonlog_flag=$para2

    $actionsln ="selenium_prepare"
    Get-Module -name $actionsln|remove-module
    $mdpath=(get-childitem -path $scriptRoot -r -file |where-object{$_.name -match "^$actionsln\b" -and $_.name -match "psm1"}).fullname
    Import-Module $mdpath -WarningAction SilentlyContinue -Global
        
    $action="idrac_ResizableBAR-$($switches)"
    $tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
    $tcnumber=((get-content $tcpath).split(","))[0]
    $tcstep=((get-content $tcpath).split(","))[1]
    $picpath=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\"
    if(-not(test-path $picpath)){new-item -ItemType directory -path $picpath |out-null}
    $results="OK"
    $index="check screenshots"

    &$actionsln  edge nonlog
           
    $idracinfo=(get-content -path "C:\testing_AI\settings\idrac.txt").split(",")
    $idracip=$idracinfo[0]
    $idracuser=$idracinfo[1]
    $idracpwd=$idracinfo[2]

    get-childitem  "C:\testing_AI\modules\selenium\WebDriver.dll" |Unblock-File 
    Add-Type -Path "C:\testing_AI\modules\selenium\WebDriver.dll"

    try{$driver = New-Object OpenQA.Selenium.Edge.EdgeDriver}
    catch{
    $results="NG"
    $index="fail to install web driver"
    }

    if($results -ne "NG"){
    
    [OpenQA.Selenium.Interactions.Actions]$actions = New-Object OpenQA.Selenium.Interactions.Actions ($driver)
    $actions = New-Object OpenQA.Selenium.Interactions.Actions($driver)

    $driver.Manage().Window.Maximize()
    $driver.Navigate().GoToUrl("https://$idracip")

    $nowtime=get-date

    do{
    start-sleep -s 5
     $detailbt=$driver.FindElement([OpenQA.Selenium.By]:: ID("details-button"))
      $timepass= (New-TimeSpan -start $nowtime -end (get-date)).TotalSeconds
         }until($detailbt.Enabled -eq $true -or $timepass -gt 120)

    if($detailbt.Enabled -eq $true){
        $detailbt.click()
        start-sleep -s 2
        $detailbt2=$driver.FindElement([OpenQA.Selenium.By]:: ID("proceed-link"))
        $detailbt2.click()
        }


    $nowtime=get-date

    do{
        start-sleep -s 2
        $usenameinp=$driver.FindElement([OpenQA.Selenium.By]::ClassName("cui-start-screen-username"))
         $timepass= (New-TimeSpan -start $nowtime -end (get-date)).TotalSeconds

    }until( $usenameinp.TagName -eq "input"  -or $timepass -gt 120)

    
if($usenameinp.TagName -eq "input" ) {
    start-sleep -s 5    
    $usenameinp.click()
    start-sleep -s 2
    $usenameinp.SendKeys($idracuser)
     start-sleep -s 2
    $passwordinp=$driver.FindElement([OpenQA.Selenium.By]::ClassName("cui-start-screen-password"))
    $passwordinp.SendKeys($idracpwd)
     start-sleep -s 2
    $sumitbt=$driver.FindElement([OpenQA.Selenium.By]::CssSelector("button[ng-click='onButtonAction(\'login\')']"))
    $sumitbt.Click()

    Start-Sleep -s 5          

      try{ $radioButton=$driver.FindElement([OpenQA.Selenium.By]::CssSelector("input[type='radio'][name='pwd_option'][value='1']"))}
      catch{ write-host "This is Matagorda"}

      if($radioButton){
        $radioButton.Click()
  
        $checkButton=$driver.FindElement([OpenQA.Selenium.By]::CssSelector("input[type='checkbox'][ng-model='config.disableDCW']"))
        $checkButton.Click()

        $submitBt2=$driver.FindElement([OpenQA.Selenium.By]::CssSelector("button[ng-click='onButtonAction(\'dcw\')']"))
        $submitBt2.Click()
      }
 
     Start-Sleep -s 10


     #if small screen,check the website control
      $findjudge = $driver.FindElement([OpenQA.Selenium.By]::XPath("//button[@class='navbar-toggle mobileMenu']"))
      if($findjudge.Displayed -eq $true){
        $findjudge.Click()
        start-sleep -s 10
        }  
        $searchbox = $driver.FindElement([OpenQA.Selenium.By]::Id("searchInputId"))
        $searchbox.SendKeys("Resizable BAR")
        start-sleep -s 5
        $searchbox.SendKeys([OpenQA.Selenium.Keys]::Enter)
        start-sleep -s 5
        $serchresult=$driver.FindElement([OpenQA.Selenium.By]::CssSelector("span[translate='menu_configuration']"))
        $serchresult.Click()
        start-sleep -s 5
        $intselection = $driver.FindElement([OpenQA.Selenium.By]::Id("IntegratedDevicesRef"))
        $intselection.Click()
        start-sleep -s 5
        try{
        $resselection = $driver.FindElement([OpenQA.Selenium.By]::Id("IntegratedDevicesRef.PcieResizBar"))
        $resselection_option = $resselection.GetAttribute("value")
        }
        catch{
         #region screenshot
        $timenow=get-date -format "yyMMdd_HHmmss"
        $savepic=$picpath+"$($timenow)_step$($tcstep)_noPcieResizBarSetting.jpg"
        $screenshot = $driver.GetScreenshot()
        $screenshot.SaveAsFile( $savepic, [OpenQA.Selenium.ScreenshotImageFormat]::Jpeg)
        #endregion
        $results="NG"
        $index="no ResizBar settings"
        }

        start-sleep -s 5
        if($resselection_option){
        if($resselection_option -match $changeto){
          
        #region screenshot
        $timenow=get-date -format "yyMMdd_HHmmss"
        $savepic=$picpath+"$($timenow)_step$($tcstep)_current_settings.jpg"
        $screenshot = $driver.GetScreenshot()
        $screenshot.SaveAsFile( $savepic, [OpenQA.Selenium.ScreenshotImageFormat]::Jpeg)
        #endregion
        $index="no need to change settings"
        }
        
        else{
                
        Start-Sleep -s 5
        if($changeto -eq "enable"){
            $resselection.SendKeys("e")
        }
        if($changeto -eq "disable"){
            $resselection.SendKeys("d")
        }
        Start-Sleep -s 5        
        
        #region screenshot
        $timenow=get-date -format "yyMMdd_HHmmss"
        $savepic=$picpath+"$($timenow)_step$($tcstep)_changesettings.jpg"
        $screenshot = $driver.GetScreenshot()
        $screenshot.SaveAsFile( $savepic, [OpenQA.Selenium.ScreenshotImageFormat]::Jpeg)
        #endregion

        $applybutton=$driver.FindElement([OpenQA.Selenium.By]::CssSelector("button[ng-click='onApplyAction()']"))
        $applybutton.Click()
        Start-Sleep -s 5
        #region screenshot
        $timenow=get-date -format "yyMMdd_HHmmss"
        $savepic=$picpath+"$($timenow)_step$($tcstep)_apply.jpg"
        $screenshot = $driver.GetScreenshot()
        $screenshot.SaveAsFile( $savepic, [OpenQA.Selenium.ScreenshotImageFormat]::Jpeg)
        #endregion

        try{
        $okbutton=$driver.FindElement([OpenQA.Selenium.By]::CssSelector("button[translate='ok']"))
         if($okbutton.Displayed -eq $true){     
        #region screenshot
        $timenow=get-date -format "yyMMdd_HHmmss"
        $savepic=$picpath+"$($timenow)_step$($tcstep)_okbutton.jpg"
        $screenshot = $driver.GetScreenshot()
        $screenshot.SaveAsFile( $savepic, [OpenQA.Selenium.ScreenshotImageFormat]::Jpeg)
        #endregion
        $okbutton.Click()
         }
        }catch{
          $results="NG"
          $index="fail to change settings"
        }
        }
        }
                
    }
    
    $driver.Close()
    $driver.Quit()
    
    if((get-process -Name msedgedriver -ErrorAction SilentlyContinue)){Stop-Process -Name msedgedriver}

    }
    ### write to log ###
    
    if($nonlog_flag.Length -eq 0){
    Get-Module -name "outlog"|remove-module
    $mdpath=(get-childitem -path "C:\testing_AI\modules\" -r -file |where-object{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
    Import-Module $mdpath -WarningAction SilentlyContinue -Global

    #write-host "Do $action!"
    outlog $action $results $tcnumber $tcstep $index
    }
    
 }
  
  export-modulemember -Function idrac_ResizableBAR