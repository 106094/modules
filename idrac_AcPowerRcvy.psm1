function idrac_AcPowerRcvy ([string]$para1,[string]$para2,[string]$para3){

    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force;
    Add-Type -AssemblyName System.Windows.Forms
    $wshell=New-Object -ComObject wscript.shell

    if($PSScriptRoot.length -eq 0){
        $scriptRoot="C:\testing_AI\modules"
    }else{
        $scriptRoot=$PSScriptRoot
    }

    $results="OK"
    $index="change settings ok"

    $rcytype="last"

        if($para1 -match "on"){
            $rcytype="on"
        }
        if($para1 -match "off"){
            $rcytype="off"
        }    

        $rcydly="Immediate"

        if($para2 -match "random"){
            $rcydly="random"
            $rcydlytime=""
        }
        if($para2 -match "user"){
            $rcydly="user defined"
            $rcydlytime=[int64](($para2.split("-"))[1])
            if($rcydlytime -eq 0){
                $rcydlytime=120                
            }
            elseif($rcydlytime -lt 120 -or $rcydlytime -gt 600){
              $results="NG"  
              $index="user defined time should be between 120 and 600"
            }
        }    

   $nonlog_flag=$para3

    $actionsln ="selenium_prepare"
    Get-Module -name $actionsln|remove-module
    $mdpath=(get-childitem -path $scriptRoot -r -file |where-object{$_.name -match "^$actionsln\b" -and $_.name -match "psm1"}).fullname
    Import-Module $mdpath -WarningAction SilentlyContinue -Global
        
    $action="idrac_AC Power Recovery setting - $($switches)"
    $tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
    $tcnumber=((get-content $tcpath).split(","))[0]
    $tcstep=((get-content $tcpath).split(","))[1]
    $picpath=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\"
    if(-not(test-path $picpath)){new-item -ItemType directory -path $picpath |out-null}

    if($results -ne "NG"){
             
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
        start-sleep -s 5
        $configbtn=$driver.FindElement([OpenQA.Selenium.By]::Id("configuration"))
        $configbtn.Click()
        start-sleep -s 5
        $biosbtn = $driver.FindElement([OpenQA.Selenium.By]::Name("menu_biossettings"))
        $biosbtn.Click()
        start-sleep -s 5
        $sysecbtn=$driver.FindElement([OpenQA.Selenium.By]::Id("SysSecurityRef"))
        $sysecbtn.Click()
        start-sleep -s 5
        $driver.ExecuteScript("window.scrollTo(0, document.body.scrollHeight);")
        start-sleep -s 5
        #region screenshot
        $timenow=get-date -format "yyMMdd_HHmmss"
        $savepic=$picpath+"$($timenow)_step$($tcstep)_currentsettings.jpg"
        $screenshot = $driver.GetScreenshot()
        $screenshot.SaveAsFile( $savepic, [OpenQA.Selenium.ScreenshotImageFormat]::Jpeg)
        #endregion

        $acpwrrcvy = $driver.FindElement([OpenQA.Selenium.By]::Id("SysSecurityRef.AcPwrRcvry"))
        $acpwrrcvy_option = $acpwrrcvy.GetAttribute("value")
        
        $acpwrrcvydly = $driver.FindElement([OpenQA.Selenium.By]::Id("SysSecurityRef.AcPwrRcvryDelay"))
        $acpwrrcvydly_option = $acpwrrcvydly.GetAttribute("value")
        
        $acpwrrcvydly2 = $driver.FindElement([OpenQA.Selenium.By]::Id("SysSecurityRef.AcPwrRcvryUserDelay"))
        $acpwrrcvydly2_option = $acpwrrcvydly2.GetAttribute("value")
       

        #$acpwrrcvy_option =$acpwrrcvy_option.replace("string:","")
        if($acpwrrcvy_option -match $rcytype -and !($rcydly -match "user") -and $acpwrrcvydly_option -match $rcydly -or `
           ($acpwrrcvy_option -match $rcytype -and $rcydly -match "user" -and $acpwrrcvydly_option -match $rcydly -and $acpwrrcvydly2_option -eq $rcydlytime)){
            $index="no need to change settings"
        }
        else{
                if(! ($acpwrrcvy_option -match $rcytype )){
                    $acpwrrcvy.SendKeys($rcytype)
                }
                if(! ($acpwrrcvydly_option -match $rcydly)){
                    $acpwrrcvydly.SendKeys($rcydly)
                    if($rcydly -match "user"){
                        $acpwrrcvydly2.Click()
                        Start-Sleep -s 3
                        $wshell.SendKeys("{bs 10}")
                        Set-Clipboard -Value $rcydlytime
                        Start-Sleep -s 5
                        $wshell.SendKeys("^v")
                        Start-Sleep -s 2
                        }

                    }
               
                    #region screenshot
                    $timenow=get-date -format "yyMMdd_HHmmss"
                    $savepic=$picpath+"$($timenow)_step$($tcstep)_changeAcPwrRcvrySetting-$($rcytype)-$($rcydly).jpg"
                    $screenshot = $driver.GetScreenshot()
                    $screenshot.SaveAsFile( $savepic, [OpenQA.Selenium.ScreenshotImageFormat]::Jpeg)
                    #endregion
                    start-sleep -s 5
                    
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
                    $okbutton.Click() 
                    Start-Sleep -s 5
                    #region screenshot
                    $timenow=get-date -format "yyMMdd_HHmmss"
                    $savepic=$picpath+"$($timenow)_step$($tcstep)_okbutton.jpg"
                    $screenshot = $driver.GetScreenshot()
                    $screenshot.SaveAsFile( $savepic, [OpenQA.Selenium.ScreenshotImageFormat]::Jpeg)
                    #endregion
                    }
                    }catch{
                    $results="NG"
                    $index="fail to apply settings"
                    }
                    Start-Sleep -s 2
                    try {
                    $applyandrebootbt=$driver.FindElement([OpenQA.Selenium.By]::CssSelector("button[translate='apply_reboot']"))
                    if($applyandrebootbt.Displayed -eq $true){
                        if($nonlog_flag.Length -eq 0){
                            Get-Module -name "outlog"|remove-module
                            $mdpath=(get-childitem -path "C:\testing_AI\modules\" -r -file |where-object{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
                            Import-Module $mdpath -WarningAction SilentlyContinue -Global
                            outlog $action $results $tcnumber $tcstep $index
                            $writelog=$true
                            }
                    $applyandrebootbt.Click()
                    #region screenshot
                    $timenow=get-date -format "yyMMdd_HHmmss"
                    $savepic=$picpath+"$($timenow)_step$($tcstep)_applyandreboot.jpg"
                    $screenshot = $driver.GetScreenshot()
                    $screenshot.SaveAsFile( $savepic, [OpenQA.Selenium.ScreenshotImageFormat]::Jpeg)
                    #endregion 
                     Start-Sleep -s 5
                    }        
                    }
                    catch {
                        $results="NG"
                        $index="fail to change settings"
                    }
                    
        }
        
        
        #logout        
        $logout1=$driver.FindElement([OpenQA.Selenium.By]::XPath("//*[@id=""scrollArea""]/div[1]/header/div/ul/li[2]/a/i"))
        $logout1.click()
        start-sleep -s 5
        $logout2=$driver.FindElement([OpenQA.Selenium.By]::XPath("//*[@id=""scrollArea""]/div[1]/header/div/ul/li[2]/ul/li[2]/a"))
        $logout2.click()
        }
                           
    $driver.Close()
    $driver.Quit()
    
    if((get-process -Name msedgedriver -ErrorAction SilentlyContinue)){Stop-Process -Name msedgedriver}

    }
    }
    ### write to log ###
    
    if($writelog){
        Write-Output "ERROR-fail to reboot idrac"
    }
    if($nonlog_flag.Length -eq 0 -and !$writelog){
    Get-Module -name "outlog"|remove-module
    $mdpath=(get-childitem -path "C:\testing_AI\modules\" -r -file |where-object{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
    Import-Module $mdpath -WarningAction SilentlyContinue -Global

    #write-host "Do $action!"
    outlog $action $results $tcnumber $tcstep $index
    }
    
 }
  
  export-modulemember -Function idrac_AcPowerRcvy