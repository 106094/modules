function amddownload([string]$para1){
    
    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force;
    $wshell=New-Object -ComObject wscript.shell
      Add-Type -AssemblyName Microsoft.VisualBasic
      Add-Type -AssemblyName System.Windows.Forms
      
$actionss ="screenshot"
Get-Module -name $actionss|remove-module
$mdpath=(Get-ChildItem -path $scriptRoot -r -file |Where-object{$_.name -match "^$actionss\b" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global
  
$nonlog_flag=$para1

if($PSScriptRoot.length -eq 0){
$scriptRoot="C:\testing_AI\modules"
}
else{
$scriptRoot=$PSScriptRoot
}

$action="AMDdownload"

$tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
$tcnumber=((get-content $tcpath).split(","))[0]
$tcstep=((get-content $tcpath).split(","))[1]

$picpath=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\"
if(-not(test-path $picpath)){new-item -ItemType directory -path $picpath |out-null}


### import web driver ##

$actionsln ="selenium_prepare"

Get-Module -name $actionsln|remove-module
$mdpath=(Get-ChildItem -path $scriptRoot -r -file |Where-object{$_.name -match "^$actionsln\b" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

&$actionsln -para1 edge -para2 nonlog

Get-ChildItem  "C:\testing_AI\modules\selenium\WebDriver.dll" |Unblock-File 
Add-Type -Path "C:\testing_AI\modules\selenium\WebDriver.dll"

    try{$driver = New-Object OpenQA.Selenium.Edge.EdgeDriver}
    catch{
    $results="NG"
    $index="fail to install web driver"
    }

    if($results -ne "NG"){

[OpenQA.Selenium.Interactions.Actions]$actions = New-Object OpenQA.Selenium.Interactions.Actions ($driver)
$driver.Manage().Window.Maximize()
$results="OK"

$website="https://www.amd.com/en.html"

$driver.Navigate().GoToUrl($website)

Start-Sleep -s 30
&$actionss -para3 "nonlog" -para5 "AMD_webpage_open"

$timenow=get-date
do{
Start-Sleep -s 1
 $acceptelement = $driver.FindElement([OpenQA.Selenium.By]::Id("onetrust-accept-btn-handler"))
 $timewait=(New-TimeSpan -start $timenow  -end (get-date)).TotalSeconds
 }until($acceptelement -or  $timewait -gt 60)
 
 if($acceptelement){ 
 $acceptelement.Click()
 &$actionss -para3 "nonlog" -para5 "AMD_webpage_accept"
 }
 else{$index=$index+@("1. fail to find and click accept")}
 
Start-Sleep -s 5
### menu
$timenow=get-date
do{
Start-Sleep -s 1
 $menuelement = $driver.FindElement([OpenQA.Selenium.By]::ClassName("navbar-toggler"))
 $timewait=(New-TimeSpan -start $timenow  -end (get-date)).TotalSeconds
 }until($menuelement -or  $timewait -gt 60)
 
 if($menuelement){ 
 try{  $menuelement.Click()}
 catch{$index=$index+@("2. no menu button is  found")}
  }
  
Start-Sleep -s 5
## download_support 
$timenow=get-date
do{
Start-Sleep -s 1
 $dlsuelement = $driver.FindElement([OpenQA.Selenium.By]::Id("downloads-support"))
  $timewait=(New-TimeSpan -start $timenow  -end (get-date)).TotalSeconds
 }until($dlsuelement -or  $timewait -gt 60)
 
 if( $dlsuelement){
  $dlsuelement.Click()
  &$actionss -para3 "nonlog" -para5 "AMD_downloads_support"
  }
 else{$index=$index+@("3. fail to find and click download_support menu")}


Start-Sleep -s 5
## downloads
$timenow=get-date
do{
Start-Sleep -s 1
 $dlelement = $driver.FindElement([OpenQA.Selenium.By]::Id("headerMenu-a58a50d2a0-item-f2931226c7-tabpanel"))
  $timewait=(New-TimeSpan -start $timenow  -end (get-date)).TotalSeconds
 }until( $dlelement -or  $timewait -gt 60)
 
 if( $dlelement){
 $dlelement.Click()
 &$actionss -para3 "nonlog" -para5 "AMD_downloads"
  }
 else{$index=$index+@("4. fail to find and click downloads menu")}
 
 
Start-Sleep -s 5
## Drivers
$timenow=get-date
do{
Start-Sleep -s 1
 $drvelement = $driver.FindElement([OpenQA.Selenium.By]::LinkText("Drivers"))
  $timewait=(New-TimeSpan -start $timenow  -end (get-date)).TotalSeconds
 }until( $drvelement  -or  $timewait -gt 60)
 
 if( $drvelement ){
 $drvelement.Click()
  &$actionss -para3 "nonlog" -para5 "AMD_Drivers"
 }
 else{$index=$index+@("5. fail to find and click Drivers")}

#check  before download files
$downlfs=(Get-ChildItem $env:userprofile\Downloads\* -file).Name
 
Start-Sleep -s 5
##Download Windows Drivers
$timenow=get-date
do{
Start-Sleep -s 1
 $dldrvelement = $driver.FindElement([OpenQA.Selenium.By]::LinkText("DOWNLOAD WINDOWS DRIVERS"))
  $timewait=(New-TimeSpan -start $timenow  -end (get-date)).TotalSeconds
 }until( $dldrvelement  -or  $timewait -gt 60)
 
 if( $dldrvelement ){ 
  $dldrvelement.Click()
   &$actionss -para3 "nonlog" -para5 "AMD_Drivers_download"

 do{
 start-sleep -s 5
$downlfs_new=(Get-ChildItem $env:userprofile\Downloads\* -file).Name|Where-object{$_ -notin $downlfs}
}until($downlfs_new -match "amd-software" -and $downlfs_new -match "\.exe")
 
start-sleep -s 5

$datenow=get-date -format "yyMMdd_HHmmss"
$downfl_newname=$picpath+"$($datenow)_$($downlfs_new)"
copy-item  $env:userprofile\Downloads\$downlfs_new -destination $downfl_newname -force
}
else{
$index=$index+@("6. fail to find and donwload windows Drivers")
 }
### close web ###

$driver.Close()
$driver.Quit()

  &$actionss -para3 "nonlog" -para5 "AMD_Webpage_Close"

$index=$index|out-string

if($index -match "fail"){
$results="NG"
}
write-host "results:$results"
write-host "index:$index"



}

######### write log #######

if($nonlog_flag.Length -eq 0 -or $timespanmin -gt 30){
Get-Module -name "outlog"|remove-module
$mdpath=(Get-ChildItem -path "C:\testing_AI\modules\"  -r -file |Where-object{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

#write-host "Do $action!"
outlog $action $results $tcnumber $tcstep $index
}
  }

    export-modulemember -Function amddownload