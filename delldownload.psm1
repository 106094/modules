
function delldownload([string]$para1,[int]$para2,[string]$para3){
    
    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force;
    $wshell=New-Object -ComObject wscript.shell
      Add-Type -AssemblyName Microsoft.VisualBasic
      Add-Type -AssemblyName System.Windows.Forms
  
$paracheck=$PSBoundParameters.ContainsKey('para1')
$paracheck2=$PSBoundParameters.ContainsKey('para2')
$paracheck3=$PSBoundParameters.ContainsKey('para3')

if( $paracheck -eq $false -or $para1.length -eq 0 ){
#write-host "no defined, setting 1 min after login"
$para1="R167233.exe"
}
if($paracheck2 -eq $false -or $para2 -eq 0){
$para2=2250584
}
if($paracheck3 -eq $false -or $para3.length -eq 0){
$para3=""
}

$dlfilename=$para1
$dlfilesize=$para2
$nonlog_flag=$para3

if($PSScriptRoot.length -eq 0){
$scriptRoot="C:\testing_AI\modules"
}
else{
$scriptRoot=$PSScriptRoot
}


$action="delldownload"

$tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
$tcnumber=((get-content $tcpath).split(","))[0]
$tcstep=((get-content $tcpath).split(","))[1]

$picpath=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\"
if(-not(test-path $picpath)){new-item -ItemType directory -path $picpath |out-null}

$actionmd="screenshot"
Get-Module -name $actionmd|remove-module
$mdpath=(Get-ChildItem -path $scriptRoot -r -file |?{$_.name -match "^$actionmd\b" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

$screen = [System.Windows.Forms.Screen]::PrimaryScreen
$bounds = $screen.Bounds
$width  = $bounds.Width
$height = $bounds.Height

#$width  = (([string]::Join("`n", (wmic path Win32_VideoController get CurrentHorizontalResolution))).split("`n") -match "\d{1,}")[0]
#$height  = (([string]::Join("`n", (wmic path Win32_VideoController get CurrentVerticalResolution))).split("`n") -match "\d{1,}")[0]


Get-ChildItem  "C:\testing_AI\modules\selenium\WebDriver.dll" |Unblock-File 
Add-Type -Path "C:\testing_AI\modules\selenium\WebDriver.dll"

$dlcount=(Get-ChildItem $env:USERPROFILE\downloads\*.exe).count
$dlnames=(Get-ChildItem $env:USERPROFILE\downloads\*.exe).name


### web ##


$actionsln ="selenium_prepare"

Get-Module -name $actionsln|remove-module
$mdpath=(Get-ChildItem -path $scriptRoot -r -file |?{$_.name -match "^$actionsln\b" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

&$actionsln -para1 edge -para2 nonlog

$website="https://www.dell.com/support/home/en-us?lwp=rt"
#$website="https://www.dell.com/support/home/en-sg?app=drivers&lwp=rt"
$searchw= "Precision R5400"
$searchw2= "Intel Chipset Software Installation Utility, v.8.5"


    try{$driver = New-Object OpenQA.Selenium.Edge.EdgeDriver}
    catch{
    $results="NG"
    $index="fail to install web driver"
    }

    if($results -ne "NG"){

[OpenQA.Selenium.Interactions.Actions]$actions = New-Object OpenQA.Selenium.Interactions.Actions ($driver)
$driver.Manage().Window.Maximize()
$driver.Navigate().GoToUrl($website)

 Start-Sleep -s 10
 
 ## if popup message ##
   [System.Windows.Forms.SendKeys]::SendWait("{esc}")
    Start-Sleep -s 2
   [System.Windows.Forms.SendKeys]::SendWait("{esc}")
##>
 Start-Sleep -s 5
 
 
 $newbt=$driver.FindElement([OpenQA.Selenium.By]::ClassName("mh-mobile-nav-toggle")) 
 $newbt.Click()
  Start-Sleep -s 5
 $supelement = $driver.FindElement([OpenQA.Selenium.By]::XPath("//button[contains(@class, 'mh-top-nav-button') and span[text()='Support']]"))
 $supelement.Click()

 #$driver.ExecuteScript('arguments[0].scrollIntoView(true);', @($supelement))

  Start-Sleep -s 5
 $supl2=$element = $driver.FindElement([OpenQA.Selenium.By]::CssSelector("a.mh-menuItem[href*='self-support-knowledgebase']"))
 $supl2.click()

#$supl=$driver.FindElement([OpenQA.Selenium.By]::XPath("//*[@id=""divResourceLinks""]/div/div/div[5]/a"))
# $supl=$driver.FindElement([OpenQA.Selenium.By]::CssSelector("a[data-linkmetrics='support-library']"))
# $supl.click()
# Start-Sleep -s 5

 
 ## if popup message ##
   [System.Windows.Forms.SendKeys]::SendWait("{esc}")
##>

 Start-Sleep -s 5

 &$actionmd  -para3 nonlog -para5 web1
 
 $downl1=$driver.FindElement([OpenQA.Selenium.By]::CssSelector("a[href*='software-and-downloads'] div.dds__card"))
  
 [System.Windows.Forms.SendKeys]::SendWait("{esc}")
 Start-Sleep -s 1

 $downl1.click()
 Start-Sleep -s 5
 
 ## if popup message ##
   [System.Windows.Forms.SendKeys]::SendWait("{esc}")
##>

 &$actionmd  -para3 nonlog -para5 web2
  
Start-Sleep -s 5

 $downl2=$driver.FindElement([OpenQA.Selenium.By]::ID("tabi-2"))

 [System.Windows.Forms.SendKeys]::SendWait("{esc}")
 Start-Sleep -s 1

 $downl2.click()
 Start-Sleep -s 5

 ## if popup message ##
   [System.Windows.Forms.SendKeys]::SendWait("{esc}")
##>

 &$actionmd  -para3 nonlog -para5 web3

 $downl3=$driver.FindElement([OpenQA.Selenium.By]:: ID("PromotedContent-download-center-0"))
 
 [System.Windows.Forms.SendKeys]::SendWait("{esc}")
 Start-Sleep -s 1
  
 $downl3.click() 
   
 Start-Sleep -s 5

  ## if popup message ##
   [System.Windows.Forms.SendKeys]::SendWait("{esc}")
##>

 Start-Sleep -s 5

 &$actionmd  -para3 nonlog -para5 web4

 $downl4= $driver.FindElement([OpenQA.Selenium.By]::LinkText("Drivers & Downloads website"))
 
 [System.Windows.Forms.SendKeys]::SendWait("{esc}")
 Start-Sleep -s 1

 $downl4.Click()

 Start-Sleep -s 5

 ## if popup message ##
   [System.Windows.Forms.SendKeys]::SendWait("{esc}")
##>

 &$actionmd  -para3 nonlog -para5 web5

    Start-Sleep -s 5

$popupWindow = $driver.SwitchTo().Window($driver.WindowHandles[1])

$input=$popupWindow.FindElement([OpenQA.Selenium.By]::Id("inpEntrySelection"))
$input.SendKeys($searchw)

Start-Sleep -s 5
 ## if popup message ##
   [System.Windows.Forms.SendKeys]::SendWait("{esc}")
##>
 
 &$actionmd  -para3 nonlog -para5 web6
   
    Start-Sleep -s 5

$searchb=$popupWindow.FindElement([OpenQA.Selenium.By]::Id("txtSearchEs"))

[System.Windows.Forms.SendKeys]::SendWait("{esc}")
Start-Sleep -s 1

$searchb.Click()

Start-Sleep -s 5
 ## if popup message ##
   [System.Windows.Forms.SendKeys]::SendWait("{esc}")
##>

 &$actionmd  -para3 nonlog -para5 web7
    
    Start-Sleep -s 5

$input2=$popupWindow.FindElement([OpenQA.Selenium.By]::Id("keyword"))
$input2.SendKeys($searchw2)

Start-Sleep -s 5
 ## if popup message ##
   [System.Windows.Forms.SendKeys]::SendWait("{esc}")
##>

 &$actionmd  -para3 nonlog -para5 web8

  Start-Sleep -s 5

$searchb2=$popupWindow.FindElement([OpenQA.Selenium.By]::Id("dnd_btnKeywordSearch"))

[System.Windows.Forms.SendKeys]::SendWait("{esc}")
Start-Sleep -s 1
$searchb2.Click()

Start-Sleep -s 5
 ## if popup message ##
   [System.Windows.Forms.SendKeys]::SendWait("{esc}")
##>

Start-Sleep -s 5
$downloadbt=$popupWindow.FindElement([OpenQA.Selenium.By]::Id("btnDwn-P50X1"))

[System.Windows.Forms.SendKeys]::SendWait("{esc}")
Start-Sleep -s 1

$downloadbt.Click()


$i=0
do{
$i++
Start-Sleep -s 5
$dlcount2=(Get-ChildItem $env:USERPROFILE\downloads\*.exe).count
} until ($dlcount2 -gt $dlcount -or $i -gt 60)

$dlnames2=(Get-ChildItem $env:USERPROFILE\downloads\*.exe|?{$_.name -notin $dlnames}).name
$dlnamesfull=(Get-ChildItem $env:USERPROFILE\downloads\*.exe|?{$_.name -notin $dlnames}).fullname
$dlsize=(Get-ChildItem $env:USERPROFILE\downloads\*.exe|?{$_.name -notin $dlnames}).length

if($dlcount2 -gt $dlcount){
Move-Item $dlnamesfull $picpath -Force
}

if($dlnames2 -eq $dlfilename -and $dlsize -eq $dlfilesize){
$results="OK"
$index="same file name and size"
}
else{
$nonlog_flag="nolog"
}


### close web ###

$driver.Close()
$driver.Quit()

######### check timespan  #######

$logs=(Split-Path -Parent $scriptRoot)+"\logs\logs_timemap.csv"
$lastactiontime=(Get-ChildItem $logs).LastWriteTime
$timespanmin=(New-TimeSpan -start $lastactiontime -end (get-date)).TotalMinutes
if($timespanmin -gt 30){
$nonlog_flag=""
$results="NG"
$index="download failed (over 30 minutes), check screen shots"
}
$results
$index
$nonlog_flag

}

######### write log #######

if($nonlog_flag.Length -eq 0 -or $timespanmin -gt 30){
Get-Module -name "outlog"|remove-module
$mdpath=(Get-ChildItem -path "C:\testing_AI\modules\"  -r -file |?{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

#write-host "Do $action!"
outlog $action $results $tcnumber $tcstep $index
}
  }

    export-modulemember -Function delldownload