function idrac_Storage_check ([string]$para1,[string]$para2){
    
    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force;
    Add-Type -AssemblyName System.Windows.Forms
       
    if($PSScriptRoot.length -eq 0){
        $scriptRoot="C:\testing_AI\modules"
    }else{
        $scriptRoot=$PSScriptRoot
    }
   
   $checktype=$para1
   $nonlog_flag=$para2

    $actionsln ="selenium_prepare"
    Get-Module -name $actionsln|remove-module
    $mdpath=(Get-ChildItem -path $scriptRoot -r -file |Where-Object{$_.name -match "^$actionsln\b" -and $_.name -match "psm1"}).fullname
    Import-Module $mdpath -WarningAction SilentlyContinue -Global

    $action="idrac_Storage_checks"
    $tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
    $tcnumber=((get-content $tcpath).split(","))[0]
    $tcstep=((get-content $tcpath).split(","))[1]
    $picpath=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\"
    if(-not(test-path $picpath)){new-item -ItemType directory -path $picpath |out-null}
    
    &$actionsln  edge nonlog
           
    $idracinfo=(get-content -path "C:\testing_AI\settings\idrac.txt").split(",")
    $idracip=$idracinfo[0]
    $idracuser=$idracinfo[1]
    $idracpwd=$idracinfo[2]


    Get-ChildItem "C:\testing_AI\modules\selenium\*.dll" |Unblock-File 
    
    Add-Type -Path "C:\testing_AI\modules\selenium\Newtonsoft.Json.dll" -ErrorAction SilentlyContinue
    Add-Type -Path "C:\testing_AI\modules\selenium\WebDriver.dll" 

        try{
            $edgeOptions = New-Object OpenQA.Selenium.Edge.EdgeOptions
            $driver = New-Object OpenQA.Selenium.Edge.EdgeDriver("C:\testing_AI\modules\selenium\msedgedriver.exe", $edgeOptions)
        }
            catch{   
               try{$driver = New-Object OpenQA.Selenium.Edge.EdgeDriver
                }
               catch{
                $results="NG"
                $index="fail to install web driver"
            }
            }

    if($results -ne "NG"){
    
    [OpenQA.Selenium.Interactions.Actions]$actions = New-Object OpenQA.Selenium.Interactions.Actions ($driver)
    $actions = New-Object OpenQA.Selenium.Interactions.Actions($driver)

    $driver.Manage().Window.Maximize()
    $driver.Manage().Window.Maximize()
    $driver.Navigate().GoToUrl("https://$idracip")

    start-sleep -s 10

    $detailbt=$driver.FindElement([OpenQA.Selenium.By]::ID("details-button"))
    if($detailbt.Text -eq "Advanced"){ 
        $detailbt.click()
        start-sleep -s 2
        $detailbt2=$driver.FindElement([OpenQA.Selenium.By]::ID("proceed-link"))
        $detailbt2.click()
    }

    do{
        start-sleep -s 2
        $usenameinp=$driver.FindElement([OpenQA.Selenium.By]::ClassName("cui-start-screen-username"))
    }until( $usenameinp.TagName -eq "input")

    start-sleep -s 5
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
      if($findjudge){
    $findjudge.Click()
    start-sleep -s 10
    }



    $idsetby=$driver.FindElement([OpenQA.Selenium.By]::Id("storage"))
    $idsetby.Click()

    start-sleep -s 10

if($checktype -match "PD" -or $checktype.Length -eq 0){

    $storage_pdisks=  $driver.FindElement([OpenQA.Selenium.By]::id("pdisks_2"))
    $storage_pdisks.Click()
     start-sleep -s 10

#region screenshot
   $timenow=get-date -format "yyMMdd_HHmmss"
   $savepic=$picpath+"$($timenow)_step$($tcstep)_storageInfo_PDisks.jpg"
   $screenshot = $driver.GetScreenshot()
   $screenshot.SaveAsFile( $savepic, [OpenQA.Selenium.ScreenshotImageFormat]::Jpeg)
#endregion
    }

if($checktype -match "VD" -or $checktype.Length -eq 0){

  $storage_vdisks=  $driver.FindElement([OpenQA.Selenium.By]::id("vdisks_3"))
    $storage_vdisks.Click()

#region screenshot
   $timenow=get-date -format "yyMMdd_HHmmss"
   $savepic=$picpath+"$($timenow)_step$($tcstep)_storage_VDisks.jpg"
   $screenshot = $driver.GetScreenshot()
   $screenshot.SaveAsFile( $savepic, [OpenQA.Selenium.ScreenshotImageFormat]::Jpeg)
#endregion

}
    $driver.Close()
    $driver.Quit()
    
    if((get-process -Name msedgedriver -ErrorAction SilentlyContinue)){Stop-Process -Name msedgedriver}
}   

    ### write to log ###
    
    if($nonlog_flag.Length -eq 0){
    Get-Module -name "outlog"|remove-module
    $mdpath=(Get-ChildItem -path "C:\testing_AI\modules\" -r -file |Where-Object{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
    Import-Module $mdpath -WarningAction SilentlyContinue -Global

    #write-host "Do $action!"
    outlog $action $results $tcnumber $tcstep $index
    }
    
}

Export-ModuleMember -Function idrac_Storage_check