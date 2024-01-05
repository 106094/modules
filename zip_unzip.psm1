

function zip_unzip ([string]$para1,[string]$para2,[string]$para3){
    
    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force;
    $wshell=New-Object -ComObject wscript.shell
     Add-Type -AssemblyName Microsoft.VisualBasic
     Add-Type -AssemblyName System.Windows.Forms
   
$paracheck=$PSBoundParameters.ContainsKey('para1')

if( $paracheck -eq $false -or $para1.length -eq 0 ){
#write-host "no defined, setting 1 min after login"
$para1="no_define"
}


$appname=$para1

$appcheck=Get-Process -Name $appname -ErrorAction SilentlyContinue
$bcount=($appcheck.id).Count
  
  if($bcount -ge 1){
  
(Get-Process -Name $appname).CloseMainWindow()
Start-Sleep -s 30
$appcheck=Get-Process -Name $appname -ErrorAction SilentlyContinue
$bcount=($appcheck.id).Count

if($bcount -ge 1){
(get-process |Where-object{$_ -match $appname}).Id |%{ 
taskkill -pid  $_  /F
} 
}
  start-sleep -s 3
   $appcheck=Get-Process -Name $appname -ErrorAction SilentlyContinue
   $bcount=($appcheck.id).Count
     if($bcount -eq 0){$results="OK";  $index="close app $appname ok"}
       if($bcount -gt 0) {$results="NG" ; $index= "close app $appname fail"}
       
  }

  else{  $results="-"; $index="No app $appname is found" }
   

  
######### write log #######


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

Get-Module -name "outlog"|remove-module
$mdpath=(Get-ChildItem -path "C:\testing_AI\modules\"  -r -file |Where-object{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

#write-host "Do $action!"
outlog $action $results $tcnumber $tcstep $index


  }

    export-modulemember -Function zip_unzip