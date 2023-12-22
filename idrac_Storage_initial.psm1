function idrac_Storage_initial ([string]$para1,[string]$para2){
    
    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force;
    Add-Type -AssemblyName System.Windows.Forms
       
    if($PSScriptRoot.length -eq 0){
        $scriptRoot="C:\testing_AI\modules"
    }else{
        $scriptRoot=$PSScriptRoot
    }
   
   $clearvd=$para1       
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
    $results="OK"
    $index="check screenshots"

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

    $nowtime=get-date

    do{
    start-sleep -s 5
     $detailbt=$driver.FindElement([OpenQA.Selenium.By]:: ID("details-button"))
      $timepass= (New-TimeSpan -start $nowtime -end (get-date)).TotalMinutes
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
         $timepass= (New-TimeSpan -start $nowtime -end (get-date)).TotalMinutes

    }until( $usenameinp.TagName -eq "input"  -or $timepass -gt 120)

    
if($usenameinp.TagName -eq "input" ) {

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
      
      $checkalert=$driver.FindElement([OpenQA.Selenium.By]::CssSelector("[translate='RAC0501.Message']"))
      if($checkalert.text -match "There are no physical disks to be displayed"){
      $results="NG"
      $index="iDRAC fail to read the disks"
      }

else{      
    $storage_pdisks=  $driver.FindElement([OpenQA.Selenium.By]::id("pdisks_2"))
    $storage_pdisks.Click()
     start-sleep -s 10

#region screenshot
   $timenow=get-date -format "yyMMdd_HHmmss"
   $savepic=$picpath+"$($timenow)_step$($tcstep)_storageInfo_start.jpg"
   $screenshot = $driver.GetScreenshot()
   $screenshot.SaveAsFile( $savepic, [OpenQA.Selenium.ScreenshotImageFormat]::Jpeg)
#endregion

# check if slot = 8

function checkfr{
  
   $storage_overview=  $driver.FindElement([OpenQA.Selenium.By]::id("storage.overview"))
   $storage_overview.Click()
   start-sleep -s 10
   
    $storage_pdisks=  $driver.FindElement([OpenQA.Selenium.By]::id("pdisks_2"))
    $storage_pdisks.Click()
     start-sleep -s 10

   $pdiskRows = $driver.FindElements([OpenQA.Selenium.By]::CssSelector("table tr"))
   $a=0
   $slotnumbermax=0
   $stateonline=0
   $fr_flag=$false
foreach(  $pdiskRow in  $pdiskRows){
$a++
try{
  $tdElement =$pdiskRow.FindElements([OpenQA.Selenium.By]::CssSelector("td")) 
  $lastslotnumber=$tdElement[5].text
  $slotState=$tdElement[4].text
  write-host "slot: $($lastslotnumber) status: $($slotState) "
  }
  catch{
  write-host "row $a no td"
  }
  if($slotState -match "online"){
  $stateonline++
  }
    if($slotState -match "Foreign"){
  $fr_flag=$true
  }
  if($lastslotnumber -gt $slotnumbermax){
  $slotnumbermax=$lastslotnumber
  }

  }
"$($stateonline),$($slotnumbermax),$fr_flag"
 }

 do{
 $checkdisk_fr=checkfr
 $stateonline=($checkdisk_fr.split(","))[0]
 $slotnumbermax=($checkdisk_fr.split(","))[1]
 $frnflag=($checkdisk_fr.split(","))[2]
 
 if($frnflag -eq $true){
 
   $ctler=$driver.FindElement([OpenQA.Selenium.By]::Id("controllers_1"))
    $ctler.Click()

    start-sleep -s 10


#region check  foreign configurations

    $selectsid=$driver.FindElement([OpenQA.Selenium.By]::TagName("select")).GetAttribute("id")
    $selects=$driver.FindElement([OpenQA.Selenium.By]::id("$selectsid"))
    $optionElements = $selects.FindElements([OpenQA.Selenium.By]::TagName("option"))


     foreach ($option in $optionElements) {
     $option.GetAttribute("label")

    if ($option.GetAttribute("label") -match "Foreign Configuration") {

        $option.Click()
        break  # Exit the loop after selecting the first matching option
    }
}

 start-sleep -s 5


do{
 start-sleep -s 5
$clearfg_button =  $driver.FindElement([OpenQA.Selenium.By]::CssSelector("[ng-click='clearForeignConfig()']"))
  }until($clearfg_button)
   
   #region screenshot
   $timenow=get-date -format "yyMMdd_HHmmss"
   $savepic=$picpath+"$($timenow)_step$($tcstep)_clearForeignConfig.jpg"
   $screenshot = $driver.GetScreenshot()
   $screenshot.SaveAsFile( $savepic, [OpenQA.Selenium.ScreenshotImageFormat]::Jpeg)
#endregion

$clearfg_button.Click()

start-sleep -s 5


do{
 start-sleep -s 5
 $clearfgokbt=  $driver.FindElement([OpenQA.Selenium.By]::CssSelector("button[translate='ok']")) ## ok to delete ##
  }until( $clearfgokbt)
    
   #region screenshot
   $timenow=get-date -format "yyMMdd_HHmmss"
   $savepic=$picpath+"$($timenow)_step$($tcstep)_clearForeignConfig_ok_.jpg"
   $screenshot = $driver.GetScreenshot()
   $screenshot.SaveAsFile( $savepic, [OpenQA.Selenium.ScreenshotImageFormat]::Jpeg)
#endregion
  $clearfgokbt.Click()

  
 do{
 start-sleep -s 5
   $clearfgapply=  $driver.FindElement([OpenQA.Selenium.By]::CssSelector("button[translate='apply_immediately']"))  ## add to pending ##
  }until(  $clearfgapply)

     #region screenshot
   $timenow=get-date -format "yyMMdd_HHmmss"
   $savepic=$picpath+"$($timenow)_step$($tcstep)_clearForeignConfig_apply_.jpg"
   $screenshot = $driver.GetScreenshot()
   $screenshot.SaveAsFile( $savepic, [OpenQA.Selenium.ScreenshotImageFormat]::Jpeg)
#endregion
   $clearfgapply.Click()

     do{
   start-sleep -s 5
   $clearfgquebt=  $driver.FindElement([OpenQA.Selenium.By]::CssSelector("button[translate='menu_jobqueue']")) ## jobqueue ##
   }until($clearfgquebt)
 #region screenshot
   $timenow=get-date -format "yyMMdd_HHmmss"
   $savepic=$picpath+"$($timenow)_step$($tcstep)_clearForeignConfig_jobqueue_.jpg"
   $screenshot = $driver.GetScreenshot()
   $screenshot.SaveAsFile( $savepic, [OpenQA.Selenium.ScreenshotImageFormat]::Jpeg)
#endregion
   $clearfgquebt.Click()
   
   start-sleep -s 10
   
  do{
  start-sleep -s 3
  $queRows = $driver.FindElements([OpenQA.Selenium.By]::CssSelector("table tr"))
  $questatus=$queRows[1].Text
  }until( ($questatus -match "Completed" -and "100") -or ($questatus -match "Failed" -and "100"))

 }

}until($frnflag -eq $false)

#check disk numbers and online status

if($slotnumbermax -ne 7){
  $results="-"
  $index="no slot 7 exist, skip"
  write-host $index
   }
   
elseif($stateonline -le 8 -and $stateonline -gt 1 ){
 
if($clearvd.length -eq 0 -and  $stateonline -eq 8){
  $results="-"
  $index="all slots are online, skip"
  write-host $index
  }
elseif($clearvd.length -ne 0 -and  $stateonline -le 8){
  $results="-"
  $index="some slots are online, need delete VD"
  write-host $index
    
### delete all online disk ##

 #region ## delete VD - change online to ready ##
 
 if($clearvd.Length -gt 0){
  
  ## if $osvd eq $true need collect slot0 name
$slot0_vdname="NA"

 if($osvd -eq $true){

 do{
    
  $storage_overview=  $driver.FindElement([OpenQA.Selenium.By]::id("storage.overview"))
   $storage_overview.Click()
   start-sleep -s 10
   $storage_pdisks=  $driver.FindElement([OpenQA.Selenium.By]::id("pdisks_2"))
    $storage_pdisks.Click()
     start-sleep -s 10
  
   $pdiskRows = $driver.FindElements([OpenQA.Selenium.By]::CssSelector("table tr"))
   $a=0
foreach(  $pdiskRow in  $pdiskRows){
$a++
try{
  $tdElement =$pdiskRow.FindElements([OpenQA.Selenium.By]::CssSelector("td")) }
  catch{
  write-host "row $a no td"
  }
 
  if($tdElement -and $tdElement[5].text -eq "0"){
   
    $selectsid=$tdElement[10].FindElement([OpenQA.Selenium.By]::TagName("select")).GetAttribute("id")
    $selects=$tdElement[10].FindElement([OpenQA.Selenium.By]::id("$selectsid"))
    $optionElements = $selects.FindElements([OpenQA.Selenium.By]::TagName("option"))

 foreach ($option in $optionElements) {
     $option.GetAttribute("label")

    if ($option.GetAttribute("label") -match "View Virtual Disks") {

        $option.Click()
        break  # Exit the loop after selecting the first matching option
    }
}


  }
}

  start-sleep -s 10
 
  $slot0vdRows = $driver.FindElements([OpenQA.Selenium.By]::CssSelector("table tr"))
  $slot0_vdname=foreach( $slot0vdRow in $slot0vdRows){
  $tdElement =$slot0vdRow.FindElements([OpenQA.Selenium.By]::CssSelector("td")) 
    $tdElement[3].text

  }

  $slot0_vdname=($slot0_vdname|out-string).trim()

  }until($slot0_vdname.Length -gt 0)

  write-host "slot0 VD name is $slot0_vdname "
   #&$actionss -para3 nolog -para5 "slot0"
    #region screenshot
   $timenow=get-date -format "yyMMdd_HHmmss"
   $savepic=$picpath+"$($timenow)_step$($tcstep)_slot0_$($slot0_vdname).jpg"
   $screenshot = $driver.GetScreenshot()
   $screenshot.SaveAsFile( $savepic, [OpenQA.Selenium.ScreenshotImageFormat]::Jpeg)
#endregion
  }

  # start delete VD

     $storage_pdisks=  $driver.FindElement([OpenQA.Selenium.By]::id("pdisks_2"))
    $storage_pdisks.Click()
     start-sleep -s 10
  $storage_vdisks=  $driver.FindElement([OpenQA.Selenium.By]::id("vdisks_3"))
    $storage_vdisks.Click()
       start-sleep -s 10
            
#region screenshot
$timenow=get-date -format "yyMMdd_HHmmss"
$savepic=$picpath+"$($timenow)_step$($tcstep)_DeleteVD_start.jpg"
 $screenshot = $driver.GetScreenshot()
 $screenshot.SaveAsFile( $savepic, [OpenQA.Selenium.ScreenshotImageFormat]::Jpeg)
#endregion   

  do{

  try{ $storage_vdisks_check =  $driver.FindElement([OpenQA.Selenium.By]::CssSelector("span[translate='vdisks']")).Text}
  catch{
   $storage_overview=  $driver.FindElement([OpenQA.Selenium.By]::id("storage.overview"))
   $storage_overview.Click()
   start-sleep -s 10
   $storage_pdisks=  $driver.FindElement([OpenQA.Selenium.By]::id("vdisks_3"))
    $storage_pdisks.Click()
     start-sleep -s 10
    }
    
   $pdiskRows = $driver.FindElements([OpenQA.Selenium.By]::CssSelector("table tr"))
   $a=0
   $waitdelete=$null

foreach( $pdiskRow in  $pdiskRows){
      $pdiskRows = $driver.FindElements([OpenQA.Selenium.By]::CssSelector("table tr"))
      $pdiskRow=$pdiskRows[$a]
$a++
try{
   $tdElement =$pdiskRow.FindElements([OpenQA.Selenium.By]::CssSelector("td")) 
   $vdiskname= $tdElement[3].text
   $vdiskstatus=$tdElement[4].text
   #$vdiskWPolicys=$tdElement[8].text
   #write-host "row $a is $($vdiskname), status is $($vdiskstatus)"
  }
  catch{
  write-host "row $a no td"
  }
 
 if($tdElement -and $vdiskname.length -gt 0 -and $vdiskname -ne $slot0_vdname -and $vdiskstatus -match "online"){
  $waitdelete=1
 
    $selectsid=$tdElement[9].FindElement([OpenQA.Selenium.By]::TagName("select")).GetAttribute("id")
    $selects=$tdElement[9].FindElement([OpenQA.Selenium.By]::id("$selectsid"))
    $optionElements = $selects.FindElements([OpenQA.Selenium.By]::TagName("option"))

 foreach ($option in $optionElements) {
       
    if ($option.GetAttribute("label") -match "Delete") {
    write-host "$vdiskname is going to Delete VD"
        $option.Click()
        start-sleep -s 3

          break  # Exit the loop after selecting the first matching option
        }
        }
          break  # Exit the loop after selecting the first matching option
} 
 else{$waitdelete=0}

}

  if($waitdelete -eq 1){

do{
 start-sleep -s 5
 $convertokbt=  $driver.FindElement([OpenQA.Selenium.By]::CssSelector("button[translate='ok']")) ## ok to delete ##
  }until($convertokbt)
  $convertokbt.Click()

        $timenow=get-date -format "yyMMdd_HHmmss"
        $savepic=$picpath+"$($timenow)_step$($tcstep)_DeleteVD_$($vdiskname).jpg"
        $screenshot = $driver.GetScreenshot()
        $screenshot.SaveAsFile( $savepic, [OpenQA.Selenium.ScreenshotImageFormat]::Jpeg)

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
   $storage_pdisks=  $driver.FindElement([OpenQA.Selenium.By]::id("vdisks_3"))
    $storage_pdisks.Click()
     start-sleep -s 10

     }


     }until ($waitdelete -eq 0)


#region screenshot
$timenow=get-date -format "yyMMdd_HHmmss"
$savepic=$picpath+"$($timenow)_step$($tcstep)_DeleteVD_done.jpg"
 $screenshot = $driver.GetScreenshot()
 $screenshot.SaveAsFile( $savepic, [OpenQA.Selenium.ScreenshotImageFormat]::Jpeg)
   
 $storage_pdisks=  $driver.FindElement([OpenQA.Selenium.By]::id("pdisks_2"))
  $storage_pdisks.Click()
    start-sleep -s 10
$timenow=get-date -format "yyMMdd_HHmmss"
$savepic=$picpath+"$($timenow)_step$($tcstep)_DeleteVD_done2.jpg"
 $screenshot = $driver.GetScreenshot()
 $screenshot.SaveAsFile( $savepic, [OpenQA.Selenium.ScreenshotImageFormat]::Jpeg)

#endregion

     $results="OK"
     $index="clear all VD done"
     write-host $index
 
 }

 #endregion

  }
    
   }

else{

   $storage_overview=  $driver.FindElement([OpenQA.Selenium.By]::id("storage.overview"))
   $storage_overview.Click()
   start-sleep -s 10

    $ctler=$driver.FindElement([OpenQA.Selenium.By]::Id("controllers_1"))
    $ctler.Click()

    start-sleep -s 10

#region create vd

    $selectsid=$driver.FindElement([OpenQA.Selenium.By]::TagName("select")).GetAttribute("id")
    $selects=$driver.FindElement([OpenQA.Selenium.By]::id("$selectsid"))
    $optionElements = $selects.FindElements([OpenQA.Selenium.By]::TagName("option"))

 foreach ($option in $optionElements) {
     $option.GetAttribute("label")

    if ($option.GetAttribute("label") -match "Create Virtual Disk") {

        $option.Click()
        start-sleep -s 3
        $timenow=get-date -format "yyMMdd_HHmmss"
        $savepic=$picpath+"$($timenow)_step$($tcstep)_create_VD_start.jpg"
        $screenshot = $driver.GetScreenshot()
        $screenshot.SaveAsFile( $savepic, [OpenQA.Selenium.ScreenshotImageFormat]::Jpeg)

        break  # Exit the loop after selecting the first matching option
    }
}

start-sleep -s 10

#$switch=$driver.SwitchTo().Window(($driver.WindowHandles)[-1])

## check VD creatable ##
$idracalertText2 = ($driver.FindElements([OpenQA.Selenium.By]::TagName("idrac-alert"))|?{($_.text).Length -gt 0}).text

if(-not($idracalertText2 -match "Unable to create virtual disk")){

 #&$actionss -para3 nolog -para5 "create_VD_next"
  
#region screenshot
   $timenow=get-date -format "yyMMdd_HHmmss"
   $savepic=$picpath+"$($timenow)_step$($tcstep)_CreateVD_Next.jpg"
   $screenshot = $driver.GetScreenshot()
   $screenshot.SaveAsFile( $savepic, [OpenQA.Selenium.ScreenshotImageFormat]::Jpeg)
#endregion

$vdnextbutton=  $driver.FindElement([OpenQA.Selenium.By]::CssSelector("button[translate='next']")) ## next ##

$vdnextbutton.Click()

start-sleep -s 10

#select all disks##

#$checkboxes =  $driver.FindElements([OpenQA.Selenium.By]::CssSelector("input[type='checkbox']"))

$checkboxes2 =  $driver.FindElements([OpenQA.Selenium.By]::CssSelector("input[ng-checked='row.checked']"))

foreach ($checkbox in $checkboxes2) {
   $checkbox.Enabled
   $checkbox.Selected

       if (($checkbox.Enabled -eq $true) -and  ($checkbox.Selected -eq $false)) {
        $checkbox.Click()
        start-sleep -s 1
    }


}

start-sleep -s 10

 #&$actionss -para3 nolog -para5 "create_VD_next2"
 #region screenshot
   $timenow=get-date -format "yyMMdd_HHmmss"
   $savepic=$picpath+"$($timenow)_step$($tcstep)_CreateVD_Next2.jpg"
   $screenshot = $driver.GetScreenshot()
   $screenshot.SaveAsFile( $savepic, [OpenQA.Selenium.ScreenshotImageFormat]::Jpeg)
#endregion

$vdnextbutton2=  $driver.FindElement([OpenQA.Selenium.By]::CssSelector("button[translate='next']")) ## next ##
$vdnextbutton2.Click()


start-sleep -s 10

 #&$actionss -para3 nolog -para5 "create_VD_next3"
 #region screenshot
   $timenow=get-date -format "yyMMdd_HHmmss"
   $savepic=$picpath+"$($timenow)_step$($tcstep)_CreateVD_Next3.jpg"
   $screenshot = $driver.GetScreenshot()
   $screenshot.SaveAsFile( $savepic, [OpenQA.Selenium.ScreenshotImageFormat]::Jpeg)
#endregion

$vdnextbutton3=  $driver.FindElement([OpenQA.Selenium.By]::CssSelector("button[translate='next']")) ## next ##
$vdnextbutton3.Click()

start-sleep -s 10
 #&$actionss -para3 nolog -para5 "create_VD_next4"
  #region screenshot
   $timenow=get-date -format "yyMMdd_HHmmss"
   $savepic=$picpath+"$($timenow)_step$($tcstep)_CreateVD_Next4.jpg"
   $screenshot = $driver.GetScreenshot()
   $screenshot.SaveAsFile( $savepic, [OpenQA.Selenium.ScreenshotImageFormat]::Jpeg)
#endregion

$vdnextbutton4=  $driver.FindElement([OpenQA.Selenium.By]::CssSelector("button[translate='Add_to_pending']")) ## add to pending ##
$vdnextbutton4.Click()

start-sleep -s 10
 #&$actionss -para3 nolog -para5 "create_VD_next5"
   #region screenshot
   $timenow=get-date -format "yyMMdd_HHmmss"
   $savepic=$picpath+"$($timenow)_step$($tcstep)_CreateVD_Next5.jpg"
   $screenshot = $driver.GetScreenshot()
   $screenshot.SaveAsFile( $savepic, [OpenQA.Selenium.ScreenshotImageFormat]::Jpeg)
#endregion

#$switch=$driver.SwitchTo().Window(($driver.WindowHandles)[-1])
 start-sleep -s 10

 $vdnextbutton5=  $driver.FindElement([OpenQA.Selenium.By]::CssSelector("button[translate='apply_immediately']")) ## add to pending ##
$vdnextbutton5.Click()

 start-sleep -s 10
 
 #&$actionss -para3 nolog -para5 "create_VD_next6"
   #region screenshot
   $timenow=get-date -format "yyMMdd_HHmmss"
   $savepic=$picpath+"$($timenow)_step$($tcstep)_CreateVD_Next6.jpg"
   $screenshot = $driver.GetScreenshot()
   $screenshot.SaveAsFile( $savepic, [OpenQA.Selenium.ScreenshotImageFormat]::Jpeg)
#endregion

  $vdnextbutton6=  $driver.FindElement([OpenQA.Selenium.By]::CssSelector("button[translate='menu_jobqueue']")) ## add to pending ##
$vdnextbutton6.Click()
 
 #&$actionss -para3 nolog -para5 "create_VD_Job_queue"
    #region screenshot
   $timenow=get-date -format "yyMMdd_HHmmss"
   $savepic=$picpath+"$($timenow)_step$($tcstep)_CreateVD_JobQueue.jpg"
   $screenshot = $driver.GetScreenshot()
   $screenshot.SaveAsFile( $savepic, [OpenQA.Selenium.ScreenshotImageFormat]::Jpeg)
#endregion

  do{
  start-sleep -s 3
  $queRows = $driver.FindElements([OpenQA.Selenium.By]::CssSelector("table tr"))
  $questatus=$queRows[1].Text
  }until( $questatus -match "Completed" -and "100")

    #&$actionss -para3 nolog -para5 "create_VD_Job_queue_complete"
  #region screenshot
   $timenow=get-date -format "yyMMdd_HHmmss"
   $savepic=$picpath+"$($timenow)_step$($tcstep)_CreateVD_JobQueue_Complete.jpg"
   $screenshot = $driver.GetScreenshot()
   $screenshot.SaveAsFile( $savepic, [OpenQA.Selenium.ScreenshotImageFormat]::Jpeg)
#endregion

#region delete VD ###

  $storage_overview=  $driver.FindElement([OpenQA.Selenium.By]::id("storage.overview"))
   $storage_overview.Click()
   
 start-sleep -s 10
 
 #&$actionss -para3 nolog -para5 "overview"
     #region screenshot
   $timenow=get-date -format "yyMMdd_HHmmss"
   $savepic=$picpath+"$($timenow)_step$($tcstep)_StorageOverview.jpg"
   $screenshot = $driver.GetScreenshot()
   $screenshot.SaveAsFile( $savepic, [OpenQA.Selenium.ScreenshotImageFormat]::Jpeg)
#endregion
  start-sleep -s 10
   
  $storage_pdisks=  $driver.FindElement([OpenQA.Selenium.By]::id("pdisks_2"))
    $storage_pdisks.Click()

 
 #$switch=$driver.SwitchTo().Window(($driver.WindowHandles)[-1])

  start-sleep -s 10
  
# &$actionss -para3 nolog -para5 "PhysicalDisks"
 #region screenshot
   $timenow=get-date -format "yyMMdd_HHmmss"
   $savepic=$picpath+"$($timenow)_step$($tcstep)_PhysicalDisks.jpg"
   $screenshot = $driver.GetScreenshot()
   $screenshot.SaveAsFile( $savepic, [OpenQA.Selenium.ScreenshotImageFormat]::Jpeg)
#endregion


## if $osvd eq $true need collect slot0 name
$slot0_vdname="NA"

 if($osvd -eq $true){

 do{
    
  $storage_overview=  $driver.FindElement([OpenQA.Selenium.By]::id("storage.overview"))
   $storage_overview.Click()
   start-sleep -s 10
   $storage_pdisks=  $driver.FindElement([OpenQA.Selenium.By]::id("pdisks_2"))
    $storage_pdisks.Click()
     start-sleep -s 10
  
   $pdiskRows = $driver.FindElements([OpenQA.Selenium.By]::CssSelector("table tr"))
   $a=0
foreach(  $pdiskRow in  $pdiskRows){
$a++
try{
  $tdElement =$pdiskRow.FindElements([OpenQA.Selenium.By]::CssSelector("td")) }
  catch{
  write-host "row $a no td"
  }
 
  if($tdElement -and $tdElement[5].text -eq "0"){
   
    $selectsid=$tdElement[10].FindElement([OpenQA.Selenium.By]::TagName("select")).GetAttribute("id")
    $selects=$tdElement[10].FindElement([OpenQA.Selenium.By]::id("$selectsid"))
    $optionElements = $selects.FindElements([OpenQA.Selenium.By]::TagName("option"))

 foreach ($option in $optionElements) {
     $option.GetAttribute("label")

    if ($option.GetAttribute("label") -match "View Virtual Disks") {

        $option.Click()
        break  # Exit the loop after selecting the first matching option
    }
}


  }
}

  start-sleep -s 10
 
  $slot0vdRows = $driver.FindElements([OpenQA.Selenium.By]::CssSelector("table tr"))
  $slot0_vdname=foreach( $slot0vdRow in $slot0vdRows){
  $tdElement =$slot0vdRow.FindElements([OpenQA.Selenium.By]::CssSelector("td")) 
    $tdElement[3].text

  }

  $slot0_vdname=($slot0_vdname|out-string).trim()

  }until($slot0_vdname.Length -gt 0)

  write-host "slot0 VD name is $slot0_vdname "
   #&$actionss -para3 nolog -para5 "slot0"
    #region screenshot
   $timenow=get-date -format "yyMMdd_HHmmss"
   $savepic=$picpath+"$($timenow)_step$($tcstep)_slot0_$($slot0_vdname).jpg"
   $screenshot = $driver.GetScreenshot()
   $screenshot.SaveAsFile( $savepic, [OpenQA.Selenium.ScreenshotImageFormat]::Jpeg)
#endregion
  }

  ## backto physical Disks
  
 start-sleep -s 10
  
  $storage_pdisks=  $driver.FindElement([OpenQA.Selenium.By]::id("pdisks_2"))
    $storage_pdisks.Click()
       
 ## backto virtual  Disks    
 start-sleep -s 10
 
 $trytime=0
 do{

  $storage_overview=  $driver.FindElement([OpenQA.Selenium.By]::id("storage.overview"))
   $storage_overview.Click()
   start-sleep -s 10
  
  $storage_vdisks=  $driver.FindElement([OpenQA.Selenium.By]::id("vdisks_3"))
    $storage_vdisks.Click()
       start-sleep -s 10

 $slotsvdrows = $driver.FindElements([OpenQA.Selenium.By]::CssSelector("table tr"))
foreach( $slotsvdrow in  $slotsvdrows){

  $tdElement3 = $slotsvdrow.FindElements([OpenQA.Selenium.By]::CssSelector("td")) 
  $waittideletevd=$tdElement3[3].text

    if($waittideletevd.length -gt 0 -and !($waittideletevd -match $slot0_vdname)){   
    
    $selectsid= $tdElement3[9].FindElement([OpenQA.Selenium.By]::TagName("select")).GetAttribute("id")
    $selects= $tdElement3[9].FindElement([OpenQA.Selenium.By]::id("$selectsid"))
    $optionElements = $selects.FindElements([OpenQA.Selenium.By]::TagName("option"))

 if($optionElements){
 foreach ($option in $optionElements) {
     $option.GetAttribute("label")

    if ($option.GetAttribute("label") -match "Delete") {

        $option.Click()
      
        break  # Exit the loop after selecting the first matching option
    }
}
}

    }

  }

  #&$actionss -para3 nolog -para5 "delete_VD"
  #region screenshot
   $timenow=get-date -format "yyMMdd_HHmmss"
   $savepic=$picpath+"$($timenow)_step$($tcstep)_Delete_VD_$($waittideletevd).jpg"
   $screenshot = $driver.GetScreenshot()
   $screenshot.SaveAsFile( $savepic, [OpenQA.Selenium.ScreenshotImageFormat]::Jpeg)
#endregion
 
#$switch=$driver.SwitchTo().Window(($driver.WindowHandles)[-1])
 start-sleep -s 10
  $vddeletebt=  $driver.FindElement([OpenQA.Selenium.By]::CssSelector("button[translate='ok']")) ## ok to delete ##
 $vddeletebt.Click()
 
  start-sleep -s 10
 
   #&$actionss -para3 nolog -para5 "delete_VD_ok"
   
  #region screenshot
   $timenow=get-date -format "yyMMdd_HHmmss"
   $savepic=$picpath+"$($timenow)_step$($tcstep)_Delete_VD_OK.jpg"
   $screenshot = $driver.GetScreenshot()
   $screenshot.SaveAsFile( $savepic, [OpenQA.Selenium.ScreenshotImageFormat]::Jpeg)
#endregion

#$switch=$driver.SwitchTo().Window(($driver.WindowHandles)[-1])

 start-sleep -s 10
 $vddeletebtapply=  $driver.FindElement([OpenQA.Selenium.By]::CssSelector("button[translate='apply_immediately']")) ## add to pending ##
 $vddeletebtapply.Click()
  start-sleep -s 10
 
   #&$actionss -para3 nolog -para5 "delete_VD_apply"

  #region screenshot
   $timenow=get-date -format "yyMMdd_HHmmss"
   $savepic=$picpath+"$($timenow)_step$($tcstep)_Delete_VD_Apply.jpg"
   $screenshot = $driver.GetScreenshot()
   $screenshot.SaveAsFile( $savepic, [OpenQA.Selenium.ScreenshotImageFormat]::Jpeg)
#endregion

#$switch=$driver.SwitchTo().Window(($driver.WindowHandles)[-1])
 start-sleep -s 10

 $vddeletebtjob=  $driver.FindElement([OpenQA.Selenium.By]::CssSelector("button[translate='menu_jobqueue']")) ## add to pending ##
 $vddeletebtjob.Click()
  start-sleep -s 10

#$switch=$driver.SwitchTo().Window(($driver.WindowHandles)[-1])
 start-sleep -s 10

   #&$actionss -para3 nolog -para5 "delete_VD_Job_queue"

#region screenshot
   $timenow=get-date -format "yyMMdd_HHmmss"
   $savepic=$picpath+"$($timenow)_step$($tcstep)_Delete_VD_JobQueue.jpg"
   $screenshot = $driver.GetScreenshot()
   $screenshot.SaveAsFile( $savepic, [OpenQA.Selenium.ScreenshotImageFormat]::Jpeg)
#endregion

  do{
  start-sleep -s 3
  $queRows = $driver.FindElements([OpenQA.Selenium.By]::CssSelector("table tr"))
  $questatus=$queRows[1].Text
  }until( ($questatus -match "Completed" -and "100") -or ($questatus -match "Failed" -and "100"))

  $trytime++

}until( ($questatus -match "Completed" -and "100") -or $trytime -gt 2)

#&$actionss -para3 nolog -para5 "delete_VD_Job_queue_complete"
#region screenshot
$timenow=get-date -format "yyMMdd_HHmmss"
$savepic=$picpath+"$($timenow)_step$($tcstep)_Delete_VD_JobQueue_Fail.jpg"
if($questatus -match "Completed" -and "100"){  $savepic=$picpath+"$($timenow)_step$($tcstep)_Delete_VD_JobQueue_Complete.jpg"}
 $screenshot = $driver.GetScreenshot()
 $screenshot.SaveAsFile( $savepic, [OpenQA.Selenium.ScreenshotImageFormat]::Jpeg)
#endregion

 #endregion   
 
 #region Convert to nonRAID
 
   $storage_overview=  $driver.FindElement([OpenQA.Selenium.By]::id("storage.overview"))
   $storage_overview.Click()
   start-sleep -s 10
   $storage_pdisks=  $driver.FindElement([OpenQA.Selenium.By]::id("pdisks_2"))
    $storage_pdisks.Click()
     start-sleep -s 10
        
#region screenshot
$timenow=get-date -format "yyMMdd_HHmmss"
$savepic=$picpath+"$($timenow)_step$($tcstep)_ConvertnonRAID_start.jpg"
 $screenshot = $driver.GetScreenshot()
 $screenshot.SaveAsFile( $savepic, [OpenQA.Selenium.ScreenshotImageFormat]::Jpeg)
#endregion   

  do{

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
 

 if($tdElement -and $slotnum.length -gt 0 -and $slotnum -ne $slot0index -and $slotstatus -match "ready" -and !($pendings -match "Convert to Non-RAID")){
 
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
           $savepic=$picpath+"$($timenow)_step$($tcstep)_ConverToNonRAID_slot$($slotnum).jpg"
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

   $questart=Get-Date
   start-sleep -s 30
   $quegap=(New-TimeSpan -start $questart -End (get-date)).TotalMinutes
   
  #first verify jobqueue value
  $queRows = $driver.FindElements([OpenQA.Selenium.By]::CssSelector("table tr"))
  $questatus=$queRows[1].Text
  
  if( !(($questatus -match "Completed" -and "100") -or ($questatus -match "Failed" -and "100")) ){
      do{
      #refresh button
      $refreshb = $driver.FindElements([OpenQA.Selenium.By]::TagName("b"))
      $refreshb.Click()
      start-sleep -s 30
      ##Click pending_operations
      $convertquebt=  $driver.FindElement([OpenQA.Selenium.By]::CssSelector("button[translate='pending_operations']")) ## jobqueue ##
      $convertquebt.Click()
      ##Click jobqueue
      $convertquebt=  $driver.FindElement([OpenQA.Selenium.By]::CssSelector("button[translate='menu_jobqueue']")) ## jobqueue ##
      $convertquebt.Click()
      start-sleep -s 30
      $queRows = $driver.FindElements([OpenQA.Selenium.By]::CssSelector("table tr"))
      $questatus=$queRows[1].Text
      $quegap=(New-TimeSpan -start $questart -End (get-date)).TotalMinutes
      #region screenshot
      $timenow=get-date -format "yyMMdd_HHmmss"
      $savepic=$picpath+"$($timenow)_step$($tcstep)_Jobqueuewait.jpg"
      $screenshot = $driver.GetScreenshot()
      $screenshot.SaveAsFile( $savepic, [OpenQA.Selenium.ScreenshotImageFormat]::Jpeg)
      #endregion  
  
      }until( ($questatus -match "Completed" -and "100") -or ($questatus -match "Failed" -and "100") -or $quegap -gt 10)
  }

  
  $timenow=get-date -format "yyMMdd_HHmmss"
  if($quegap -le 10){
  #region screenshot
  $savepic=$picpath+"$($timenow)_step$($tcstep)_JobqueueComplete.jpg"
   }
   else{
    $savepic=$picpath+"$($timenow)_step$($tcstep)_Jobqueuefail.jpg"
    $results="NG"
    $index="jobqueue check fail"
   }
   
  $screenshot = $driver.GetScreenshot()
  $screenshot.SaveAsFile( $savepic, [OpenQA.Selenium.ScreenshotImageFormat]::Jpeg)
  #endregion   
  
   $storage_overview=  $driver.FindElement([OpenQA.Selenium.By]::id("storage.overview"))
   $storage_overview.Click()
   start-sleep -s 10
   $storage_pdisks=  $driver.FindElement([OpenQA.Selenium.By]::id("pdisks_2"))
    $storage_pdisks.Click()
     start-sleep -s 10

     }


     }until ($waitconvert -eq 0)

         #region screenshot
$timenow=get-date -format "yyMMdd_HHmmss"
$savepic=$picpath+"$($timenow)_step$($tcstep)_ConvertnonRAID_end.jpg"
 $screenshot = $driver.GetScreenshot()
 $screenshot.SaveAsFile( $savepic, [OpenQA.Selenium.ScreenshotImageFormat]::Jpeg)
#endregion   

 #endregion
 write-host "all storages initail done"
}

else{
 
# &$actionss -para3 nolog -para5 "create_VD_fail"
  #region screenshot
   $timenow=get-date -format "yyMMdd_HHmmss"
   $savepic=$picpath+"$($timenow)_step$($tcstep)_CreateVD_Fail.jpg"
   $screenshot = $driver.GetScreenshot()
   $screenshot.SaveAsFile( $savepic, [OpenQA.Selenium.ScreenshotImageFormat]::Jpeg)
#endregion

$results="NG"
$index="cannot create create virtual disk"
write-host $index
}

#endregion
 

}

}

}
        
else{
#$timepass -gt 120
         $results="NG"
         $index="fail to connect iDRAC webpage"
        
        }

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

Export-ModuleMember -Function idrac_Storage_initial