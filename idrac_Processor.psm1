function idrac_Processor {
    
    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force;
    Add-Type -AssemblyName System.Windows.Forms
  
   
    if($PSScriptRoot.length -eq 0){
        $scriptRoot="C:\testing_AI\modules"
    }else{
        $scriptRoot=$PSScriptRoot
    }
        
    
    $actionsln ="selenium_prepare"
    Get-Module -name $actionsln|remove-module
    $mdpath=(Get-ChildItem -path $scriptRoot -r -file |Where-object{$_.name -match "^$actionsln\b" -and $_.name -match "psm1"}).fullname
    Import-Module $mdpath -WarningAction SilentlyContinue -Global

    $actionss="screenshot"
    Get-Module -name $actionss |remove-module
    $mdpath=(Get-ChildItem -path $scriptRoot -r -file |Where-object{$_.name -match "^$actionss\b" -and $_.name -match "psm1"}).fullname
    Import-Module $mdpath -WarningAction SilentlyContinue -Global
        
    $action="idrac_Processor_settings"
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

    Get-ChildItem  "C:\testing_AI\modules\selenium\WebDriver.dll" |Unblock-File 
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

    start-sleep -s 10

    $detailbt=$driver.FindElement([OpenQA.Selenium.By]:: ID("details-button"))
    if($detailbt -ne $null){ 
        $detailbt.click()
        start-sleep -s 2
        $detailbt2=$driver.FindElement([OpenQA.Selenium.By]:: ID("proceed-link"))
        $detailbt2.click()
    }

    do{
        start-sleep -s 2
        $driver.navigate().refresh()
         start-sleep -s 2
        $usenameinp=$driver.FindElement([OpenQA.Selenium.By]::ClassName("cui-start-screen-username"))
        $usenameinpenable=$usenameinp.Enabled
        
    }until($usenameinp.TagName -eq "input")

    start-sleep -s 2
    $usenameinp.click()
    start-sleep -s 2
    $usenameinp.SendKeys($idracuser)

    $passwordinp=$driver.FindElement([OpenQA.Selenium.By]::ClassName("cui-start-screen-password"))
    $passwordinp.SendKeys($idracpwd)

    start-sleep -s 5

    $sumitbt=$driver.FindElement([OpenQA.Selenium.By]::CssSelector("button[ng-click='onButtonAction(\'login\')']"))
    $sumitbt.Click()

    
    screenshot -para3 nolog -para5 "login_check"
          

    $radioButton=$driver.FindElement([OpenQA.Selenium.By]::CssSelector("input[type='radio'][name='pwd_option'][value='1']"))
    if($radioButton.enable){
        $radioButton.Click()
  
        $checkButton=$driver.FindElement([OpenQA.Selenium.By]::CssSelector("input[type='checkbox'][ng-model='config.disableDCW']"))
        $checkButton.Click()

        $submitBt2=$driver.FindElement([OpenQA.Selenium.By]::CssSelector("button[ng-click='onButtonAction(\'dcw\')']"))
        $submitBt2.Click()
    }
 
    Start-Sleep -s 10

    #if small screen,check the website control
    $findjudge = $driver.FindElement([OpenQA.Selenium.By]::XPath("//button[@class='navbar-toggle mobileMenu']"))
    $findjudge.Click()
    start-sleep -s 10

    $idsetby=$driver.FindElement([OpenQA.Selenium.By]::Id("configuration"))
    $idsetby.Click()

    start-sleep -s 20
 

    $idsetconn=$driver.FindElement([OpenQA.Selenium.By]::Id( "configuration.biossettings"))
    $idsetconn.Click()

    start-sleep -s 10

    $idsetconn2=$driver.FindElement([OpenQA.Selenium.By]::Id("ProcSettingsRef"))
    $idsetconn2.Click()
    
    start-sleep -s 10
    
    $idtpmsec=$driver.FindElement([OpenQA.Selenium.By]::Id( "ProcSettingsRef.LogicalProc"))
   
     #Processor	
                                
    $selected_option = $idtpmsec.GetAttribute("value").split(":")[1]
       $setcount=0

   if($selected_option -eq "Enabled"){
    screenshot -para3 nolog -para5 "original_Enable"
    }
    else{
         
    screenshot -para3 nolog -para5 "original_Disable"
          

   do{
    $setcount++
   start-sleep -s 5
     $idtpmsec.SendKeys("Enabled")
     start-sleep -s 5
    $selected_option2 = $idtpmsec.GetAttribute("value").split(":")[1]
    if($selected_option2 -match "enable"){
     screenshot -para3 nolog -para5 "ProcessorSetting_Enable_Pass"
       }
       else{
         screenshot -para3 nolog -para5 "Processorsetting_Enable_Fail"
       }

       }until($selected_option2 -match "enable" -or  $setcount -gt 3)

     }
     


    ## check settings of Brand##
     
$labelText = "Number of Cores per Processor"
$labelClass = "ng-binding"

$labelXPath = "//label[@class='$labelClass' and text()='$labelText']"
$labelCoreSpeed = $driver.FindElement([OpenQA.Selenium.By]::XPath($labelXPath))
start-sleep -s 5  
$driver.ExecuteScript("arguments[0].scrollIntoView(true);", $labelCoreSpeed)

screenshot -para3 nolog -para5 "Brandsettings"
        
 
 $results="OK"
 $index="check screen shots"
       if($setcount -gt 3){
        $results="OK"
        $index="fail to change settings"
       }

}
    ### write to log ###

    Get-Module -name "outlog"|remove-module
    $mdpath=(Get-ChildItem -path "C:\testing_AI\modules\" -r -file |Where-object{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
    Import-Module $mdpath -WarningAction SilentlyContinue -Global

    #write-host "Do $action!"
    outlog $action $results $tcnumber $tcstep $index

## Apply and reboot ##

if($results -ne "NG"){

 if($selected_option2 -and $setcount -le 3 ){
start-sleep -s 10
   $idtpmappy=$driver.FindElement([OpenQA.Selenium.By]::XPath("//*[@id='module-div']/div[2]/div/div[4]/table-bios-inputs/div/form/div/table/tfoot/tr/td[2]/span/button[1]"))
   $idtpmappy.Click()
   start-sleep -s 5
   $idtpmappyok=$driver.FindElement([OpenQA.Selenium.By]::XPath("/html/body/div[4]/div/div/div/div[3]/span/button"))
   $idtpmappyok.Click()
      start-sleep -s 5
    $idtpmappy_reboot=$driver.FindElement([OpenQA.Selenium.By]::XPath("//*[@id='module-div']/div[2]/div/div[16]/button[1]"))
       $idtpmappy_reboot.Click()
         start-sleep -s 5
     $idtpmappy_rebootok=$driver.FindElement([OpenQA.Selenium.By]::XPath("/html/body/div[4]/div/div/div/div[3]/span[2]/button"))
     $idtpmappy_rebootok.Click()
     
    Start-Sleep -s 30

      write-host "fail to reboot after Processor setting apply"

    }


    $driver.Close()
    $driver.Quit()
    
    if((get-process -Name msedgedriver -ErrorAction SilentlyContinue)){Stop-Process -Name msedgedriver}
   
   }


}

Export-ModuleMember -Function idrac_Processor