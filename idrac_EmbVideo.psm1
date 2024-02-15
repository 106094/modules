function idrac_EmbVideo ([string]$para1){
    
    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force;
    Add-Type -AssemblyName System.Windows.Forms
           
    $paracheck1=$PSBoundParameters.ContainsKey('para1')

    if($paracheck1 -eq $false -or $para1.Length -eq 0){
        $para1="Enabled-check"
    }
    
    $settins1=($para1.Split("-"))[0]
    $check = $para1 -match "-"

    if($PSScriptRoot.length -eq 0){
        $scriptRoot="C:\testing_AI\modules"
    }else{
        $scriptRoot=$PSScriptRoot
    }

    Get-Module -name "screenshot" |remove-module
    $mdpath=(Get-ChildItem -path $scriptRoot -r -file |Where-object{$_.name -match "^screenshot\b" -and $_.name -match "psm1"}).fullname
    Import-Module $mdpath -WarningAction SilentlyContinue -Global

    #$changeto=$para1

    $idracinfo=(get-content -path "C:\testing_AI\settings\idrac.txt").split(",")
    $idracip=$idracinfo[0]
    $idracuser=$idracinfo[1]
    $idracpwd=$idracinfo[2]

    ## import edge driver #
    $actionsln ="selenium_prepare"
    Get-Module -name $actionsln|remove-module
    $mdpath=(Get-ChildItem -path $scriptRoot -r -file |Where-object{$_.name -match "^$actionsln\b" -and $_.name -match "psm1"}).fullname
    Import-Module $mdpath -WarningAction SilentlyContinue -Global

    &$actionsln  edge nonlog
    
    ## import dll
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
    if($detailbt){ 
        $detailbt.click()
        start-sleep -s 2
        $detailbt2=$driver.FindElement([OpenQA.Selenium.By]:: ID("proceed-link"))
        $detailbt2.click()
    }

    do{
        start-sleep -s 2
        $usenameinp=$driver.FindElement([OpenQA.Selenium.By]::ClassName("cui-start-screen-username"))
    }until( $usenameinp.TagName -eq "input")

    start-sleep -s 5
    $usenameinp.SendKeys($idracuser)
    start-sleep -s 5
    $passwordinp=$driver.FindElement([OpenQA.Selenium.By]::ClassName("cui-start-screen-password"))
    $passwordinp.SendKeys($idracpwd)
    start-sleep -s 5
    $sumitbt=$driver.FindElement([OpenQA.Selenium.By]::CssSelector("button[ng-click='onButtonAction(\'login\')']"))
    $sumitbt.Click()
    Start-Sleep -s 10          

    $radioButton=$driver.FindElement([OpenQA.Selenium.By]::CssSelector("input[type='radio'][name='pwd_option'][value='1']"))
    if($radioButton){
        $radioButton.Click()
  
        $checkButton=$driver.FindElement([OpenQA.Selenium.By]::CssSelector("input[type='checkbox'][ng-model='config.disableDCW']"))
        $checkButton.Click()

        $submitBt2=$driver.FindElement([OpenQA.Selenium.By]::CssSelector("button[ng-click='onButtonAction(\'dcw\')']"))
        $submitBt2.Click()
        Start-Sleep -s 10
    }
  

    #if small screen,check the website control
    $findjudge = $driver.FindElement([OpenQA.Selenium.By]::XPath("//button[@class='navbar-toggle mobileMenu']"))
    $findjudge.Click()
    start-sleep -s 10

    $idsetby=$driver.FindElement([OpenQA.Selenium.By]::Id("configuration"))
    $idsetby.Click()
    #$idsetby=$driver.FindElement([OpenQA.Selenium.By]::XPath( "//*[@id=""scrollArea""]/div[1]/div[2]/nav/div/ul[1]/li[6]"))
    #$idsetby.Click()

    start-sleep -s 20
 

    $idsetconn=$driver.FindElement([OpenQA.Selenium.By]::Id( "configuration.biossettings"))
    $idsetconn.Click()

    start-sleep -s 10

    $idsetconn2=$driver.FindElement([OpenQA.Selenium.By]::Id("IntegratedDevicesRef"))
    $idsetconn2.Click()

    start-sleep -s 5

    screenshot -para3 nolog -para5 "$($para1)_original"

    start-sleep -s 5
    
    $idtpmsec=$driver.FindElement([OpenQA.Selenium.By]::Id( "IntegratedDevicesRef.EmbVideo"))
    $results="OK"

    if(!$check){          
        #Embedded NIC1 and NIC2	
                
        if($settins1 -match "Enabled"){
            $idtpmsec.SendKeys("Enabled")
        }
                    
        if($settins1 -match "disabled"){
            $idtpmsec.SendKeys("disabled")
        }
        
       start-sleep -s 5        
    }

    $selected_option = $idtpmsec.GetAttribute("value").split(":")[1]
    screenshot -para3 nolog -para5 "$($para1)_EmbVideosetting"

 
      if($selected_option -match $settins1){      
         $index ="EmbVideo settings OK" 
      }     
      else{
         $results="NG"
         $index ="EmbVideo settings Fail" 
      }

   }   

   
    ### write to log ###

    $action="idrac_EmbeddedVideoController_$para1"
    
    $tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
    $tcnumber=((get-content $tcpath).split(","))[0]
    $tcstep=((get-content $tcpath).split(","))[1]
 
    Get-Module -name "outlog"|remove-module
    $mdpath=(Get-ChildItem -path "C:\testing_AI\modules\" -r -file |Where-object{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
    Import-Module $mdpath -WarningAction SilentlyContinue -Global

    #write-host "Do $action!"
    outlog $action $results $tcnumber $tcstep $index

## Apply and reboot ##

 if(!$check -and $results -ne "NG" ){
start-sleep -s 10
   $idtpmappy=$driver.FindElement([OpenQA.Selenium.By]::XPath("//*[@id='module-div']/div[2]/div/div[9]/table-bios-inputs/div/form/div/table/tfoot/tr/td[2]/span/button[1]"))
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

    ### close web if fail ###

    $driver.Close()
    $driver.Quit()
    if((get-process -Name msedgedriver -ErrorAction SilentlyContinue)){Stop-Process -Name msedgedriver}
    write-host "fail to reboot after IntegratedDevices setting apply"

    }


}

Export-ModuleMember -Function idrac_EmbVideo
