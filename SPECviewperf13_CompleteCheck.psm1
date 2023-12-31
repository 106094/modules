function SPECviewperf13_CompleteCheck {

Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force
 $wshell = New-Object -com WScript.Shell
  Add-Type -AssemblyName Microsoft.VisualBasic
     Add-Type -AssemblyName System.Windows.Forms

if($PSScriptRoot.length -eq 0){
$scriptRoot="C:\testing_AI\modules"
}
else{
$scriptRoot=$PSScriptRoot
}



$action="SPECviewperf13 job completed check"
$tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
$tcnumber=((get-content $tcpath).split(","))[0]
$tcstep=((get-content $tcpath).split(","))[1]
$picpath=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\"


$taskExists = Get-ScheduledTask | Where-Object {$_.TaskName -like "Auto_Run" }
if($taskExists -eq $null){

 $results="-"
 $index=   "SPECviewperf13 no execute"
 
}

else{

 $doneflag=$null

 $startruntime=(Get-ChildItem C:\SPEC\SPECgpc\SPECviewperf13\vp13bench\gwpgRunBenchmark.js).LastWriteTime
 $resultfd=Get-ChildItem -Path C:\SPEC\SPECgpc\SPECviewperf13\results_*  -Directory|Where-object{$_.CreationTime -gt $startruntime}
 
 if( $resultfd.count -eq 0){
 exit
 }

 else{
 
 start-process cmd -ArgumentList '/c schtasks /delete /TN "Auto_Run" -f' 

 Copy-Item -Path $resultfd.FullName -Destination $picpath -Recurse -Force

 $results="OK"
 $index=   $resultfd.name
 
 }
 }

### write log ##

Get-Module -name "outlog"|remove-module
$mdpath=(Get-ChildItem -path "C:\testing_AI\modules\" -r -file |Where-object{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

#write-host "Do $action!"
outlog $action $results  $tcnumber $tcstep $index

 }


  
    export-modulemember -Function SPECviewperf13_CompleteCheck