
function wactest ([string]$para1,[string]$para2){
    
    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force;
    #$wshell=New-Object -ComObject wscript.shell
      Add-Type -AssemblyName Microsoft.VisualBasic
      Add-Type -AssemblyName System.Windows.Forms   

$paracheck=$PSBoundParameters.ContainsKey('para1')

if( $paracheck -eq $false -or $para1.length -eq 0 ){
#write-host "no defined, setting 1 min after login"
$para1="hybernate"
}

if($PSScriptRoot.length -eq 0){
$scriptRoot="C:\testing_AI\modules"
}
else{
$scriptRoot=$PSScriptRoot
}

$testtype=$para1
$nonlog_flag=$para2

$action="WAC test - $testtype"

$tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
$tcnumber=((get-content $tcpath).split(","))[0]
$tcstep=((get-content $tcpath).split(","))[1]
$results="OK"
$index="check logs"

$actionss ="screenshot"
Get-Module -name $actionss|remove-module
$mdpath=(Get-ChildItem -path $scriptRoot -r -file |Where-object{$_.name -match "^$actionss\b" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

$actionapp ="startmenuapp"
Get-Module -name $actionapp|remove-module
$mdpath=(Get-ChildItem -path $scriptRoot -r -file |Where-object{$_.name -match "^$actionapp\b" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

$appname="Windows Assessment Console"
$apppname="wac"
&$actionapp -para1 $appname  -para3 "nonlog"
start-sleep -s 20

$wacpid=(get-process -name $apppname).Id
  [Microsoft.VisualBasic.Interaction]::AppActivate($wacpid)
  start-sleep -s 2
  [System.Windows.Forms.SendKeys]::SendWait("{tab 2}")
  start-sleep -s 2
  [System.Windows.Forms.SendKeys]::SendWait("{down 10}")
  start-sleep -s 2
  [System.Windows.Forms.SendKeys]::SendWait("{tab 2}")
  start-sleep -s 2
  [System.Windows.Forms.SendKeys]::SendWait("{down 4}")
  start-sleep -s 2
  [System.Windows.Forms.SendKeys]::SendWait("{tab 3}")
  &$actionss -para3 "nolog" -para5 "run"
  
  [System.Windows.Forms.SendKeys]::SendWait("{Enter}")
  start-sleep -s 20

$alpid=(get-process -name al).Id
if($alpid){

 [Microsoft.VisualBasic.Interaction]::AppActivate($alpid)
  &$actionss -para3 "nolog" -para5 "launcher"
  start-sleep -s 2
  [System.Windows.Forms.SendKeys]::SendWait("{tab 3}")
  $x=0
   do{
   $x++
   start-sleep -s 2
   [System.Windows.Forms.SendKeys]::SendWait(" ")
   &$actionss -para3 "nolog" -para5 "check-item$($x)"
   [System.Windows.Forms.SendKeys]::SendWait(" ")
   start-sleep -s 2
   [System.Windows.Forms.SendKeys]::SendWait("{down}")
   }until($x -ge 6)
  }
  start-sleep -s 2
  [System.Windows.Forms.SendKeys]::SendWait("{tab 2}")
  start-sleep -s 2  
  
   &$actionss -para3 "nolog" -para5 "start"
 [Microsoft.VisualBasic.Interaction]::AppActivate($alpid)
   start-sleep -s 2  
  [System.Windows.Forms.SendKeys]::SendWait("{Enter}")
  
  Start-Sleep -s 10
  if(get-process -name axe){
    &$actionss -para3 "nolog" -para5 "running"
    }
    else{
    $results="NG"
    $index="fail to run"
    }

######### write log #######
if($nonlog_flag.Length -eq 0){
Get-Module -name "outlog"|remove-module
$mdpath=(Get-ChildItem -path "C:\testing_AI\modules\"  -r -file |Where-object{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

#write-host "Do $action!"
outlog $action $results $tcnumber $tcstep $index
}

  }

    export-modulemember -Function appclose