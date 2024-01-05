function idrac_TPM ([string]$para1,[string]$para2,[string]$para3){
    
    function login(){
        $checkcount = 1

        $driver.Navigate().GoToUrl("https://$idracip")

        start-sleep -s 10

        $detailbt=$driver.FindElement([OpenQA.Selenium.By]:: ID("details-button"))
        if($detailbt -ne $null){ 
            $detailbt.click()
            start-sleep -s 5
            $detailbt2=$driver.FindElement([OpenQA.Selenium.By]:: ID("proceed-link"))
            $detailbt2.click()
        }

        do{
            start-sleep -s 5
            $driver.Navigate().GoToUrl("https://$idracip")
            echo "Try to find usernameControl $checkcount times."
            $checkcount += 1
            $usenameinp=$driver.FindElement([OpenQA.Selenium.By]::ClassName("cui-start-screen-username"))
        }until( $usenameinp.TagName -eq "input")

        start-sleep -s 10
        $usenameinp.SendKeys($idracuser)
         start-sleep -s 2
        $passwordinp=$driver.FindElement([OpenQA.Selenium.By]::ClassName("cui-start-screen-password"))
        $passwordinp.SendKeys($idracpwd)
         start-sleep -s 2
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
        }
    }

    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force;
    Add-Type -AssemblyName System.Windows.Forms
       
    $paracheck1=$PSBoundParameters.ContainsKey('para1')
    $paracheck2=$PSBoundParameters.ContainsKey('para2')
    $paracheck3=$PSBoundParameters.ContainsKey('para3')

    #TPMSecurity
    if($paracheck1 -eq $false -or $para1.Length -eq 0){
        $para1="-check"
    }
    #TPM Hierarchy
    if($paracheck2 -eq $false -or $para2.Length -eq 0){
        $para2="-check"
    }
    #TPMPPI
    if($paracheck3 -eq $false -or $para3.Length -eq 0){
        $para3="-check"
    }
    
    $settins1=($para1.Split("-"))[0]
    $settins2=($para2.Split("-"))[0]
    $settins3=($para3.Split("-"))[0]
    
    $check = $para1 -match "-"
    $check2 = $para2 -match "-"
    $check3 = $para3 -match "-"

    if($PSScriptRoot.length -eq 0){
        $scriptRoot="C:\testing_AI\modules"
    }else{
        $scriptRoot=$PSScriptRoot
    }

    Get-Module -name "screenshot" |remove-module
    $mdpath=(Get-ChildItem -path $scriptRoot -r -file |?{$_.name -match "^screenshot\b" -and $_.name -match "psm1"}).fullname
    Import-Module $mdpath -WarningAction SilentlyContinue -Global

    #$changeto=$para1

    $idracinfo=(get-content -path "C:\testing_AI\settings\idrac.txt").split(",")
    $idracip=$idracinfo[0]
    $idracuser=$idracinfo[1]
    $idracpwd=$idracinfo[2]

    ## import edge driver #
    $actionsln ="selenium_prepare"
    Get-Module -name $actionsln|remove-module
    $mdpath=(Get-ChildItem -path $scriptRoot -r -file |?{$_.name -match "^$actionsln\b" -and $_.name -match "psm1"}).fullname
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
    
    &login

    #----------click to bios settings page------------
    Start-Sleep -s 10

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

    $idsetconn2=$driver.FindElement([OpenQA.Selenium.By]::Id("SysSecurityRef"))
    $idsetconn2.Click()

    start-sleep -s 5
    
    $TPMAdv = $driver.FindElement([OpenQA.Selenium.By]::XPath("//*[@id='module-div']/div[2]/div/div[12]/table-bios-inputs/div/form/div/table/tbody/tr[18]/td/table-bios-inputs1/div/div/span[2]/label"))
    $TPMAdv.Click()
    #$ipmiset=$driver.FindElement([OpenQA.Selenium.By]::Name( "acc_settings.connectivity.network.ipmilan"))
    #$ipmiset.Click()

    start-sleep -s 5
    
    $idtpmsec=$driver.FindElement([OpenQA.Selenium.By]::Id( "SysSecurityRef.TpmSecurity"))

    #------if not catch value , reboot idrac----------------------------
    if( $idtpmsec.GetAttribute("value").Length -eq 0 ){
        
        &login

        $moreoperation = $driver.FindElement([OpenQA.Selenium.By]::XPath("/html/body/div[2]/div[2]/div[2]/div/div[1]/div/div[3]/idrac-simple-dropdown/div/button"))
        $moreoperation.Click()

        start-sleep -s 5

        $reidrac = $driver.FindElement([OpenQA.Selenium.By]::XPath("/html/body/div[2]/div[2]/div[2]/div/div[1]/div/div[3]/idrac-simple-dropdown/div/ul/li/a"))
        $reidrac.Click()

        start-sleep -s 5

        $reidracSure = $driver.FindElement([OpenQA.Selenium.By]::XPath("/html/body/div[4]/div/div/div/div[3]/span/button[2]"))
        $reidracSure.Click()

        start-sleep -s 25

        &login
    }
    #-------------------------------------------------------------------


    #----------click to bios settings page------------
    Start-Sleep -s 10

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

    $idsetconn2=$driver.FindElement([OpenQA.Selenium.By]::Id("SysSecurityRef"))
    $idsetconn2.Click()

    start-sleep -s 5
    
    $TPMAdv = $driver.FindElement([OpenQA.Selenium.By]::XPath("//*[@id='module-div']/div[2]/div/div[12]/table-bios-inputs/div/form/div/table/tbody/tr[18]/td/table-bios-inputs1/div/div/span[2]/label"))
    $TPMAdv.Click()
    #$ipmiset=$driver.FindElement([OpenQA.Selenium.By]::Name( "acc_settings.connectivity.network.ipmilan"))
    #$ipmiset.Click()

    start-sleep -s 5
    
    $idtpmsec=$driver.FindElement([OpenQA.Selenium.By]::Id( "SysSecurityRef.TpmSecurity"))




#--------------------------------------------------------------------------------------------------
    $idtpmsec.Click()
    $idtpmsec.Click()

    $resultstpm="OK"

 if(!$check){
          
        #TPMSecurity
                
        if($settins1 -match "on"){
            $idtpmsec.SendKeys("ON")
            }
                    
        if($settins1 -match "off"){
            $idtpmsec.SendKeys("OFF")
            }
  
       start-sleep -s 5
        
}

      screenshot -para3 nolog -para5 $para1

      ## check settings of TPM security##
       
       $idtpmsec=$driver.FindElement([OpenQA.Selenium.By]::Id( "SysSecurityRef.TpmSecurity"))
       $selected_option = $idtpmsec.GetAttribute("value")

 
      if($selected_option -match $settins1){
        
        $indextpm= $indextpm+@("TPM security settings OK")      
      }     
      else{
         $resultstpm="NG"
         $indextpm= $indextpm+@("TPM security settings Fail")  
      }

       #TPMHierarchy

   $idtpmHierarchy=$driver.FindElement([OpenQA.Selenium.By]::Id( "SysSecurityRef.Tpm2Hierarchy"))
   $idtpmHierarchy.click()
   $idtpmHierarchy.click()

    if(!$check2){
   
           if($settins2 -match "clear"){
            $idtpmHierarchy.SendKeys("Clear")
            }
                    
        if($settins2 -match "enable"){
            $idtpmHierarchy.SendKeys("Enabled")
            }
         if($settins2 -match "Disable"){
            $idtpmHierarchy.SendKeys("Disabled")
            }
        start-sleep -s 5
}

  screenshot -para3 nolog -para5 $para2

   ## check settings of TPM Hierarchy##
       
   $idtpmHierarchy=$driver.FindElement([OpenQA.Selenium.By]::Id( "SysSecurityRef.Tpm2Hierarchy"))
     $selected_option2 = $idtpmHierarchy.GetAttribute("value")

 
      if($selected_option2 -match $settins2){
       $indextpm= $indextpm+@("TPM Hierarch settings OK")      
      }
      else{
       $result="NG"
        $indextpm = $indextpm +@("TPM Hierarch settings Fail")  
      }

     
            #TPM PPI Bypass Clear
            $idtpmPpiBypass=$driver.FindElement([OpenQA.Selenium.By]::Id( "TpmAdvancedSettingsRef.TpmPpiBypassClear"))
            $idtpmPpiBypass.Click()
            $idtpmPpiBypass.Click()

           
    if(!$check3){
                       
        if($settins3 -match "enable"){
           $idtpmPpiBypass.SendKeys("Enabled")
            }
         if($settins3 -match "Disable"){
            $idtpmPpiBypass.SendKeys("Disabled")
            }
        start-sleep -s 5
}

  screenshot -para3 nolog -para5 $para3

   ## check settings of TPM PPI Bypass Clear##

    $idtpmPpiBypass=$driver.FindElement([OpenQA.Selenium.By]::Id( "TpmAdvancedSettingsRef.TpmPpiBypassClear"))
      $selected_option3 = $idtpmPpiBypass.GetAttribute("value")

 if($selected_option2 -match $settins2){
      $indextpm= $indextpm+@("TPM Hierarch settings OK")      
      }
      else{
      $resultstpm="NG"
      $indextpm= $indextpm+@("TPM Hierarch settings Fail")  
      }

}

    ### write to log ###

    #$indextpm="check screenshot"
    $results=$resultstpm -join ";"
    $index=$indextpm
    $action="ipmisettings_$para1_$para2_$para3"
    
    $tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
    $tcnumber=((get-content $tcpath).split(","))[0]
    $tcstep=((get-content $tcpath).split(","))[1]
 
    Get-Module -name "outlog"|remove-module
    $mdpath=(Get-ChildItem -path "C:\testing_AI\modules\" -r -file |?{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
    Import-Module $mdpath -WarningAction SilentlyContinue -Global

    #write-host "Do $action!"
    outlog $action $resultstpm  $tcnumber $tcstep $indextpm

## Apply and reboot ##
 if($results -ne "NG"){
 if(!$check -or !$check2 -or !$check3){
start-sleep -s 10
   $idtpmappy=$driver.FindElement([OpenQA.Selenium.By]::XPath("//*[@id='module-div']/div[2]/div/div[12]/table-bios-inputs/div/form/div/table/tfoot/tr/td[2]/span/button[1]"))
   $idtpmappy.Click()
   start-sleep -s 5
   $idtpmappyok=$driver.FindElement([OpenQA.Selenium.By]::XPath("/html/body/div[4]/div/div/div/div[3]/span/button"))
   $idtpmappyok.Click()
      start-sleep -s 5
    $idtpmappy_reboot=$driver.FindElement([OpenQA.Selenium.By]::XPath("//*[@id='module-div']/div[2]/div/div[15]/button[1]"))
       $idtpmappy_reboot.Click()
         start-sleep -s 5
     $idtpmappy_rebootok=$driver.FindElement([OpenQA.Selenium.By]::XPath("/html/body/div[4]/div/div/div/div[3]/span[2]/button"))
     $idtpmappy_rebootok.Click()
     
Start-Sleep -s 30

    ### close web if fail ###

    $driver.Close()
    $driver.Quit()
    if((get-process -Name msedgedriver -ErrorAction SilentlyContinue)){Stop-Process -Name msedgedriver}
    write-host "fail to reboot after TPM setting apply"


    }
    }

### finish ##


}

Export-ModuleMember -Function idrac_TPM