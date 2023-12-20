function idrac_Storage_nonraid ([string]$para1,[string]$para2){
    
    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force;
    Add-Type -AssemblyName System.Windows.Forms
       
    if($PSScriptRoot.length -eq 0){
        $scriptRoot="C:\testing_AI\modules"
    }else{
        $scriptRoot=$PSScriptRoot
    }
   
   $slotids=$para1.split("|")
   $nonlog_flag=$para2

    $actionsln ="selenium_prepare"
    Get-Module -name $actionsln|remove-module
    $mdpath=(gci -path $scriptRoot -r -file |?{$_.name -match "^$actionsln\b" -and $_.name -match "psm1"}).fullname
    Import-Module $mdpath -WarningAction SilentlyContinue -Global

    $actionss="screenshot"
    Get-Module -name $actionss |remove-module
    $mdpath=(gci -path $scriptRoot -r -file |?{$_.name -match "^$actionss\b" -and $_.name -match "psm1"}).fullname
    Import-Module $mdpath -WarningAction SilentlyContinue -Global
        
    $action="idrac_Storage_settings"
    $tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
    $tcnumber=((get-content $tcpath).split(","))[0]
    $tcstep=((get-content $tcpath).split(","))[1]
    $picpath=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\"
    if(-not(test-path $picpath)){new-item -ItemType directory -path $picpath |out-null}
    $raidmappinglog=$picpath+"raidmapping.txt"
    if(!(test-path $raidmappinglog)){new-item  $raidmappinglog -Force |Out-Null }
   
    &$actionsln  edge nonlog
           
    $idracinfo=(get-content -path "C:\testing_AI\settings\idrac.txt").split(",")
    $idracip=$idracinfo[0]
    $idracuser=$idracinfo[1]
    $idracpwd=$idracinfo[2]

#check os disk if SSD

$osvd=$true
$slot0index="0"
$osdisk=((Get-partition)|?{$_.DriveLetter -eq "C"}).Disknumber
$osdisktype = (Get-PhysicalDisk | Where-Object { $_.DeviceId -eq $osdisk}).MediaType
if($osdisktype -match "SSD"){
$osvd=$false
$slot0index="na"
}

    gci  "C:\testing_AI\modules\selenium\WebDriver.dll" |Unblock-File 
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
    if($detailbt.Enabled -eq $true){ 
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

    $idsetby=$driver.FindElement([OpenQA.Selenium.By]::Id("storage"))
    $idsetby.Click()

    start-sleep -s 10
   
foreach($slotn in $slotids){

  try{ $storage_pdisks_check =  $driver.FindElement([OpenQA.Selenium.By]::CssSelector("span[translate='disks']")).Text}
  catch{
   $storage_overview=  $driver.FindElement([OpenQA.Selenium.By]::id("storage.overview"))
   $storage_overview.Click()
   start-sleep -s 10
   $storage_pdisks=  $driver.FindElement([OpenQA.Selenium.By]::id("pdisks_2"))
    $storage_pdisks.Click()
     start-sleep -s 10
    }
    

   $pdiskRows = $driver.FindElements([OpenQA.Selenium.By]::CssSelector("table tr"))
   $a=0
   $waitconvert=$null

foreach( $pdiskRow in  $pdiskRows){
      $pdiskRows = $driver.FindElements([OpenQA.Selenium.By]::CssSelector("table tr"))
      $pdiskRow=$pdiskRows[$a]
$a++
try{
  $tdElement =$pdiskRow.FindElements([OpenQA.Selenium.By]::CssSelector("td")) 
   $slotnum= $tdElement[5].text
   $slotstatus=$tdElement[4].text
   $pendings=$tdElement[11].text
   #write-host "row $a slot#$($slotnum), status is $($slotstatus), pending status is $($pendings) "
  }
  catch{
  write-host "row $a no td"
  }
 

 if($tdElement -and $slotnum.length -gt 0 -and $slotnum -eq $slotn -and $slotstatus -match "ready" -and !($pendings -match "Convert to Non-RAID")){
 
   $waitconvert=1
  #write-host "slot #$($slotnum) is going to convert to non-RAID"
    $selectsid=$tdElement[10].FindElement([OpenQA.Selenium.By]::TagName("select")).GetAttribute("id")
    $selects=$tdElement[10].FindElement([OpenQA.Selenium.By]::id("$selectsid"))
    $optionElements = $selects.FindElements([OpenQA.Selenium.By]::TagName("option"))

 foreach ($option in $optionElements) {
       
    if ($option.GetAttribute("label") -match "Convert to Non-RAID") {
    write-host "slot #$($slotnum) is going to convert to non-RAID"
        $option.Click()
        start-sleep -s 3
          #region screenshot
           $timenow=get-date -format "yyMMdd_HHmmss"
           $savepic=$picpath+"$($timenow)_step$($tcstep)_ConverToNonRAID_slot$($slotn).jpg"
           $screenshot = $driver.GetScreenshot()
           $screenshot.SaveAsFile( $savepic, [OpenQA.Selenium.ScreenshotImageFormat]::Jpeg)
        #endregion

         break  # Exit the loop after selecting the first matching option
        }
        }
          break  # Exit the loop after selecting the first matching option
} 
 else{$waitconvert=0}

}

  if($waitconvert -eq 1){

do{
 start-sleep -s 5
 $convertokbt=  $driver.FindElement([OpenQA.Selenium.By]::CssSelector("button[translate='ok']")) ## ok to delete ##
  }until($convertokbt)
  $convertokbt.Click()

 do{
 start-sleep -s 5
  $convertapply=  $driver.FindElement([OpenQA.Selenium.By]::CssSelector("button[translate='apply_immediately']"))  ## add to pending ##
  }until( $convertapply)
  $convertapply.Click()

  do{
   start-sleep -s 5
   $convertquebt=  $driver.FindElement([OpenQA.Selenium.By]::CssSelector("button[translate='menu_jobqueue']")) ## jobqueue ##
   }until($convertquebt)
   $convertquebt.Click()

   start-sleep -s 10
   
  do{
  start-sleep -s 3
  $queRows = $driver.FindElements([OpenQA.Selenium.By]::CssSelector("table tr"))
  $questatus=$queRows[1].Text
  }until( ($questatus -match "Completed" -and "100") -or ($questatus -match "Failed" -and "100"))

  
   $storage_overview=  $driver.FindElement([OpenQA.Selenium.By]::id("storage.overview"))
   $storage_overview.Click()
   start-sleep -s 10
   $storage_pdisks=  $driver.FindElement([OpenQA.Selenium.By]::id("pdisks_2"))
    $storage_pdisks.Click()
     start-sleep -s 10

     }


     }

         #region screenshot
$timenow=get-date -format "yyMMdd_HHmmss"
$savepic=$picpath+"$($timenow)_step$($tcstep)_ConvertnonRAID_end.jpg"
 $screenshot = $driver.GetScreenshot()
 $screenshot.SaveAsFile( $savepic, [OpenQA.Selenium.ScreenshotImageFormat]::Jpeg)
#endregion   

  
 #region check target number #
 

foreach($slotn in $slotids){
   $storage_overview=  $driver.FindElement([OpenQA.Selenium.By]::id("storage.overview"))
   $storage_overview.Click()
   start-sleep -s 10
   $storage_pdisks=  $driver.FindElement([OpenQA.Selenium.By]::id("vdisks_3"))
    $storage_pdisks.Click()
     start-sleep -s 10

  $pdiskRows = $driver.FindElements([OpenQA.Selenium.By]::CssSelector("table tr"))
   $a=0
foreach( $pdiskRow in  $pdiskRows){
$a++
try{
  $tdElement =$pdiskRow.FindElements([OpenQA.Selenium.By]::CssSelector("td")) 
  $selectvdname= $tdElement[3].text
  $selectvdtype= $tdElement[5].text
  }
  catch{
  write-host "row $a no td"
  }
 $vdname="NonRAID Disk "+$slotn
  if($tdElement -and $selectvdname -match $vdname){
    $selectvdname
    
    $expandicon=$tdElement.FindElements([OpenQA.Selenium.By]::CssSelector("span[name='data_expandspan_']"))
     $expandicon.Click()
      Start-Sleep -s 10
       $expandicon=$tdElement.FindElements([OpenQA.Selenium.By]::CssSelector("span[name='data_expandspan_']"))
       
      $pdiskRowsin = $driver.FindElements([OpenQA.Selenium.By]::CssSelector("tr[ng-repeat='column in colInfo.columns']"))
      foreach($pdiskRowsina in $pdiskRowsin){
        $vdclname=$pdiskRowsina.text

       if( $vdclname -match "Virtual Disk" -and  $vdclname -match "Device Description"){
      $vdtagname= $vdclname
      $vdtagname2=((($vdtagname -split "Virtual Disk ")[1]).split(" "))[0]
      
      write-host "VD name:$($selectvdname),VD type: $($selectvdtype), Tagname: $($vdtagname2) - ($($vdtagname))"
     if($vdname -match "non"){
      add-content  $raidmappinglog -Value  "$($selectvdname),$($vdname),$($vdtagname2)"
     }else{
      add-content  $raidmappinglog -Value  "$($selectvdname),$($selectvdtype),$($vdtagname2)"
      }
            #region screenshot
               $timenow=get-date -format "yyMMdd_HHmmss"
               $savepic=$picpath+"$($timenow)_step$($tcstep)_tagname_$($vdtagname2).jpg"
               $screenshot = $driver.GetScreenshot()
               $screenshot.SaveAsFile( $savepic, [OpenQA.Selenium.ScreenshotImageFormat]::Jpeg)
            #endregion
       $expandicon.Click()
      break
      }
      }
  break         
  }
  
}

}

 #endregion
   
    $driver.Close()
    $driver.Quit()
    
    if((get-process -Name msedgedriver -ErrorAction SilentlyContinue)){Stop-Process -Name msedgedriver}
}   

    ### write to log ###
    
    if($nonlog_flag.Length -eq 0){
    Get-Module -name "outlog"|remove-module
    $mdpath=(gci -path "C:\testing_AI\modules\" -r -file |?{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
    Import-Module $mdpath -WarningAction SilentlyContinue -Global

    #write-host "Do $action!"
    outlog $action $results $tcnumber $tcstep $index
    }
    
}

Export-ModuleMember -Function idrac_Storage_nonraid