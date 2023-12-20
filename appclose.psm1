
function appclose ([string]$para1){
    
    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force;
    $wshell=New-Object -ComObject wscript.shell
      Add-Type -AssemblyName Microsoft.VisualBasic
      Add-Type -AssemblyName System.Windows.Forms
   

$paracheck=$PSBoundParameters.ContainsKey('para1')

if( $paracheck -eq $false -or $para1.length -eq 0 ){
#write-host "no defined, setting 1 min after login"
$para1="no_define"
}


if($PSScriptRoot.length -eq 0){
$scriptRoot="C:\testing_AI\modules"
}
else{
$scriptRoot=$PSScriptRoot
}

$action="appclose"

$tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
$tcnumber=((get-content $tcpath).split(","))[0]
$tcstep=((get-content $tcpath).split(","))[1]


$actionss ="screenshot"
Get-Module -name $actionss|remove-module
$mdpath=(gci -path $scriptRoot -r -file |?{$_.name -match "^$actionss\b" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

$appname=$para1
if($appname -match "^cmd\b"){
$cmdcount=((Get-Process -Name cmd -ErrorAction SilentlyContinue).id).count
if($cmdcount -gt 1){
$appchecks=Get-Process -Name cmd -ErrorAction SilentlyContinue|sort processtime|select -last 1
Stop-Process -id $appchecks.Id
&$actionss -para3 "nolog" -para5 "$($appname)_close"
$results="OK"
$index="close app $appname ok"
}
else{
$results="NG"
$index="No app $appname is found" 

}
}
else{
$appchecks=Get-Process -Name $appname* -ErrorAction SilentlyContinue

$bcount=($appchecks.id).Count
  
  if($bcount -ge 1){
  
(Get-Process -Name $appname*).CloseMainWindow()
(Get-Process -Name $appname* -ea SilentlyContinue)|stop-process -Force

Start-Sleep -s 30
$appchecks=Get-Process -Name $appname* -ErrorAction SilentlyContinue
$bcount=($appcheck.id).Count

if($bcount -ge 1){
foreach($appname1 in $appchecks){
taskkill -pid  ($appname1.id)  /F
} 

  start-sleep -s 3
   $appcheck=Get-Process -Name $appname* -ErrorAction SilentlyContinue
   $bcount=($appcheck.id).Count
}

&$actionss -para3 "nolog" -para5 "$($appname)_close"

     if($bcount -eq 0){$results="OK";  $index="close app $appname ok"}
       if($bcount -gt 0) {$results="NG" ; $index= "close app $appname fail"}
       
  }

  else{  $results="-"; $index="No app $appname is found" }
   
}
  
######### write log #######

Get-Module -name "outlog"|remove-module
$mdpath=(gci -path "C:\testing_AI\modules\"  -r -file |?{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

#write-host "Do $action!"
outlog $action $results $tcnumber $tcstep $index


  }

    export-modulemember -Function appclose