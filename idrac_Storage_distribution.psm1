function idrac_Storage_distribution ([string]$para1,[string]$para2,[string]$para3,[string]$para4,[string]$para5){
    
    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force;
    Add-Type -AssemblyName System.Windows.Forms
       
    if($PSScriptRoot.length -eq 0){
        $scriptRoot="C:\testing_AI\modules"
    }else{
        $scriptRoot=$PSScriptRoot
    }
   
   $vdname=$para1
   try{
   $slots=(($para2.split("|")).replace("slot","")).replace(" ","")}
   catch{
   $slots=""
   }
   $slotcount= $slots.count
   $raidtype=$para3
   $checkflag=$para4
   $nonlog_flag=$para5

    $action="idrac_Storage_settings"
    if($checkflag.Length -gt 0){
    $action="idrac_Storage_VD_diskid_checks"
    }
    $tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
    $tcnumber=((get-content $tcpath).split(","))[0]
    $tcstep=((get-content $tcpath).split(","))[1]
    $picpath=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\"
    if(-not(test-path $picpath)){new-item -ItemType directory -path $picpath |out-null}
    $raidmappinglog=$picpath+"raidmapping.txt"
    if(!(test-path $raidmappinglog)){new-item  $raidmappinglog -Force |Out-Null }
   
           
 
 if($checkflag.length -eq 0){

    $actionsln ="selenium_prepare"
    Get-Module -name $actionsln|remove-module
    $mdpath=(gci -path $scriptRoot -r -file |?{$_.name -match "^$actionsln\b" -and $_.name -match "psm1"}).fullname
    Import-Module $mdpath -WarningAction SilentlyContinue -Global
    
    &$actionsln  edge nonlog

    $idracinfo=(get-content -path "C:\testing_AI\settings\idrac.txt").split(",")
    $idracip=$idracinfo[0]
    $idracuser=$idracinfo[1]
    $idracpwd=$idracinfo[2]

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
    if($detailbt -ne $null){ 
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
 
    if($radioButton){
    $findjudge.Click()
    start-sleep -s 10
    }

    $idsetby=$driver.FindElement([OpenQA.Selenium.By]::Id("storage"))
    $idsetby.Click()

    start-sleep -s 10

    $storage_pdisks=  $driver.FindElement([OpenQA.Selenium.By]::id("pdisks_2"))
    $storage_pdisks.Click()
     start-sleep -s 10
     

# check if slot = 8

   $pdiskRows = $driver.FindElements([OpenQA.Selenium.By]::CssSelector("table tr"))
   $a=0
   $slotnumbermax=0
   $stateonline=0
   $stateready=0
   

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
  $onlineslots=$onlineslots+@($lastslotnumber)
  }
  if($slotState -match "ready"){
  $stateready++
   $readyslots=$readyslots+@($lastslotnumber)
  }
  if($lastslotnumber -gt $slotnumbermax){
  $slotnumbermax=$lastslotnumber
  }

  }

$nomeet=$null
 foreach($slot in $slots){
 if(!($slot -in $readyslots)){
 $nomeet+=@("slot$($slot) status is not ready")
 }
 
 }


 if( $nomeet.count -ne 0){
  $results="-"
  $index= $nomeet|Out-String
  write-host $index
  #region screenshot
   $timenow=get-date -format "yyMMdd_HHmmss"
   $savepic=$picpath+"$($timenow)_step$($tcstep)_storageInfo_fail.jpg"
   $screenshot = $driver.GetScreenshot()
   $screenshot.SaveAsFile( $savepic, [OpenQA.Selenium.ScreenshotImageFormat]::Jpeg)
#endregion

   }

else{


if($raidtype -match "non"){
#region create non-raid

#region screenshot
$timenow=get-date -format "yyMMdd_HHmmss"
$savepic=$picpath+"$($timenow)_step$($tcstep)_ConvertnonRAID_start.jpg"
 $screenshot = $driver.GetScreenshot()
 $screenshot.SaveAsFile( $savepic, [OpenQA.Selenium.ScreenshotImageFormat]::Jpeg)
#endregion   

foreach($slota in $slots){
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
 

 if($tdElement -and $slotnum -eq $slota -and $slotstatus -match "ready"){
 
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


     }until ($waitconvert -eq 0)
  }

     $storage_overview=  $driver.FindElement([OpenQA.Selenium.By]::id("storage.overview"))
   $storage_overview.Click()
   start-sleep -s 10
   $storage_pdisks=  $driver.FindElement([OpenQA.Selenium.By]::id("vdisks_3"))
    $storage_pdisks.Click()
     start-sleep -s 10
    
   #region screenshot
   $timenow=get-date -format "yyMMdd_HHmmss"
   $savepic=$picpath+"$($timenow)_step$($tcstep)_CreateVD_Distribution_Complete.jpg"
   $screenshot = $driver.GetScreenshot()
   $screenshot.SaveAsFile( $savepic, [OpenQA.Selenium.ScreenshotImageFormat]::Jpeg)
  #endregion

 $results="OK"
 $index="check screenshots"
 write-host "storages distribution job done"

#endregion
}
else{
#region create vd

    $ctler=$driver.FindElement([OpenQA.Selenium.By]::Id("controllers_1"))
    $ctler.Click()

    start-sleep -s 10

    $selectsid=$driver.FindElement([OpenQA.Selenium.By]::TagName("select")).GetAttribute("id")
    $selects=$driver.FindElement([OpenQA.Selenium.By]::id("$selectsid"))
    $optionElements = $selects.FindElements([OpenQA.Selenium.By]::TagName("option"))

    
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

## check VD creatable ##
$idracalertText2 = ($driver.FindElements([OpenQA.Selenium.By]::TagName("idrac-alert"))|?{($_.text).Length -gt 0}).text

if(-not($idracalertText2 -match "Unable to create virtual disk")){

 #&$actionss -para3 nolog -para5 "create_VD_next"
  
  $vdnameinput=  $driver.FindElement([OpenQA.Selenium.By]::Id("createVD.settings.basic.vdisk_name"))
   $vdnameinput.SendKeys($vdname)

   $vdraidselect =  $driver.FindElement([OpenQA.Selenium.By]::Id("createVD.settings.basic.raidlevel"))
 $optionElements =  $vdraidselect.FindElements([OpenQA.Selenium.By]::TagName("option"))

 foreach ($option in $optionElements) {
     $option.GetAttribute("label")

    if ($option.GetAttribute("label") -match $raidtype) {

        $option.Click()
        start-sleep -s 2
        #region screenshot
           $timenow=get-date -format "yyMMdd_HHmmss"
           $savepic=$picpath+"$($timenow)_step$($tcstep)_CreateVD_$($raidtype)_selected.jpg"
           $screenshot = $driver.GetScreenshot()
           $screenshot.SaveAsFile( $savepic, [OpenQA.Selenium.ScreenshotImageFormat]::Jpeg)
        #endregion

        break  # Exit the loop after selecting the first matching option
    }
}



$vdnextbutton=  $driver.FindElement([OpenQA.Selenium.By]::CssSelector("button[translate='next']")) ## next ##

$vdnextbutton.Click()

start-sleep -s 10

  #region screenshot
           $timenow=get-date -format "yyMMdd_HHmmss"
           $savepic=$picpath+"$($timenow)_step$($tcstep)_CreateVD_$($raidtype)_selected_next.jpg"
           $screenshot = $driver.GetScreenshot()
           $screenshot.SaveAsFile( $savepic, [OpenQA.Selenium.ScreenshotImageFormat]::Jpeg)
        #endregion

#select disks##

   $pdiskRows = $driver.FindElements([OpenQA.Selenium.By]::CssSelector("table tr"))
   $a=0
foreach(  $pdiskRow in  $pdiskRows){
$a++
try{
  $tdElement =$pdiskRow.FindElements([OpenQA.Selenium.By]::CssSelector("td")) 
  $selectsid= $tdElement[3].text
  }
  catch{
  write-host "row $a no td"
  }
 
  if($tdElement -and $selectsid -in $slots){
    $selectsid
    $checkbox=$tdElement.FindElements([OpenQA.Selenium.By]::CssSelector("input[ng-checked='row.checked']"))
    $checkbox.Click()


  }
}

start-sleep -s 10

 #&$actionss -para3 nolog -para5 "create_VD_next2"
 #region screenshot
   $timenow=get-date -format "yyMMdd_HHmmss"
   $savepic=$picpath+"$($timenow)_step$($tcstep)_CreateVD_$($raidtype)_slots_selected.jpg"
   $screenshot = $driver.GetScreenshot()
   $screenshot.SaveAsFile( $savepic, [OpenQA.Selenium.ScreenshotImageFormat]::Jpeg)
#endregion

$vdnextbutton2=  $driver.FindElement([OpenQA.Selenium.By]::CssSelector("button[translate='next']")) ## next ##
$vdnextbutton2.Click()

start-sleep -s 10

 #&$actionss -para3 nolog -para5 "create_VD_next3"
 #region screenshot
   $timenow=get-date -format "yyMMdd_HHmmss"
   $savepic=$picpath+"$($timenow)_step$($tcstep)_CreateVD_$($raidtype)_slots_selected_next.jpg"
   $screenshot = $driver.GetScreenshot()
   $screenshot.SaveAsFile( $savepic, [OpenQA.Selenium.ScreenshotImageFormat]::Jpeg)
#endregion

$vdnextbutton3=  $driver.FindElement([OpenQA.Selenium.By]::CssSelector("button[translate='next']")) ## next ##
$vdnextbutton3.Click()

start-sleep -s 10
 #&$actionss -para3 nolog -para5 "create_VD_next4"
  #region screenshot
   $timenow=get-date -format "yyMMdd_HHmmss"
   $savepic=$picpath+"$($timenow)_step$($tcstep)_CreateVD_$($raidtype)_slots_selected_next2.jpg"
   $screenshot = $driver.GetScreenshot()
   $screenshot.SaveAsFile( $savepic, [OpenQA.Selenium.ScreenshotImageFormat]::Jpeg)
#endregion

$vdnextbutton4=  $driver.FindElement([OpenQA.Selenium.By]::CssSelector("button[translate='Add_to_pending']")) ## add to pending ##
$vdnextbutton4.Click()

start-sleep -s 10
 #&$actionss -para3 nolog -para5 "create_VD_next5"
   #region screenshot
   $timenow=get-date -format "yyMMdd_HHmmss"
   $savepic=$picpath+"$($timenow)_step$($tcstep)_CreateVD_$($raidtype)_AddToPending.jpg"
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
   $savepic=$picpath+"$($timenow)_step$($tcstep)_CreateVD_$($raidtype)_ApplyNow.jpg"
   $screenshot = $driver.GetScreenshot()
   $screenshot.SaveAsFile( $savepic, [OpenQA.Selenium.ScreenshotImageFormat]::Jpeg)
#endregion

  $vdnextbutton6=  $driver.FindElement([OpenQA.Selenium.By]::CssSelector("button[translate='menu_jobqueue']")) ## add to pending ##
$vdnextbutton6.Click()
 
 #&$actionss -para3 nolog -para5 "create_VD_Job_queue"
  #region screenshot
   $timenow=get-date -format "yyMMdd_HHmmss"
   $savepic=$picpath+"$($timenow)_step$($tcstep)_CreateVD_$($raidtype)_JobQueue.jpg"
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
  
   #region screenshot
   $timenow=get-date -format "yyMMdd_HHmmss"
   $savepic=$picpath+"$($timenow)_step$($tcstep)_CreateVD_Distribution_Complete.jpg"
   $screenshot = $driver.GetScreenshot()
   $screenshot.SaveAsFile( $savepic, [OpenQA.Selenium.ScreenshotImageFormat]::Jpeg)
  #endregion

 $results="OK"
 $index="check screenshots"
 write-host "storages distribution job done"
 
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

}
}

 #region check target number #
 
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



 #endregion
  

     

   
   }

     $driver.Close()
    $driver.Quit()
    
    if((get-process -Name msedgedriver -ErrorAction SilentlyContinue)){Stop-Process -Name msedgedriver}


   }

   
  
#endregion
}

#region check diskname of raid #
 if($checkflag.length -gt 0){
    $actiondpart="diskpart_cmdline"
    Get-Module -name $actiondpart |remove-module
    $mdpath=(gci -path $scriptRoot -r -file |?{$_.name -match "^$actiondpart\b" -and $_.name -match "psm1"}).fullname
    Import-Module $mdpath -WarningAction SilentlyContinue -Global
        
&$actiondpart -para1 "det" -para5 "nolog"
$diskpout=(gci -path $picpath -Filter "*_diskpart.txt"|sort lastwritetime|select -Last 1).fullname
$contentdet=get-content $diskpout
$raidcontent=get-content $raidmappinglog

$newcontent=foreach($raidct in $raidcontent){
$raidtarget=($raidct.split(","))[2]
$raiddisk=($raidct.split(","))[3]
if($raiddisk.length -eq 0){
foreach($det in $contentdet){
if($det -match "is now the selected disk"){
$det -match "DISK \d{1,2}"|out-null
$currentdiskid= $matches[0]
}
if($det -match "target" -and $det -match $raidtarget){
$raidct=$raidct+",$currentdiskid"
}
}
}
$raidct
}

write-host "raidmapping updated:"
$newcontent

set-content $raidmappinglog -Value $newcontent -Force


$raidcontent2=get-content $raidmappinglog
 $results="fail"
if($raidcontent2.length -gt $raidcontent.Length){
 $results="OK"
}
 $index="check $raidmappinglog"

}

#endregion

write-host "$results,$index"

    ### write to log ###
    
    if($nonlog_flag.Length -eq 0){
    Get-Module -name "outlog"|remove-module
    $mdpath=(gci -path "C:\testing_AI\modules\" -r -file |?{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
    Import-Module $mdpath -WarningAction SilentlyContinue -Global

    #write-host "Do $action!"
    outlog $action $results $tcnumber $tcstep $index
    }
    
}

Export-ModuleMember -Function idrac_Storage_distribution