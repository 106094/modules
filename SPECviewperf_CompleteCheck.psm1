function SPECviewperf_CompleteCheck ([string]$para1) {

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

if($para1 -match "13"){$benchtype="SPECviewperf13"}
if($para1 -match "2020"){$benchtype="SPECviewperf2020"}

$action="$benchtype job completed check"
$tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
$tcnumber=((get-content $tcpath).split(","))[0]
$tcstep=((get-content $tcpath).split(","))[1]
$picpath=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\"


$taskExists = Get-ScheduledTask | Where-Object {$_.TaskName -like "Auto_Run" }
if($taskExists -eq $null){

 $results="-"
 $index=   "$benchtyp no execute"
 
}

else{

 $doneflag=$null

 if($benchtype -eq "SPECviewperf13"){
 $startruntime=(Get-ChildItem C:\SPEC\SPECgpc\SPECviewperf13\vp13bench\gwpgRunBenchmark.js).LastWriteTime
 $resultfd=Get-ChildItem -Path C:\SPEC\SPECgpc\SPECviewperf13\results_*  -Directory|?{$_.CreationTime -gt $startruntime}
 
$setindex="C:\SPEC\SPECgpc\SPECviewperf13\vp13bench\index.html"
$setindexb="C:\SPEC\SPECgpc\SPECviewperf13\vp13bench\index_0.html"
$mgntjs="C:\SPEC\SPECgpc\SPECviewperf13\vp13bench\gwpgManageBenchmark.js"
$mgntjsb="C:\SPEC\SPECgpc\SPECviewperf13\vp13bench\gwpgManageBenchmark_0.js"
$mgntrbjs="C:\SPEC\SPECgpc\SPECviewperf13\vp13bench\gwpgRunBenchmark.js"
$mgntrbjsb="C:\SPEC\SPECgpc\SPECviewperf13\vp13bench\gwpgRunBenchmark_0.js"

 }
  if($benchtype -eq "SPECviewperf2020"){
 $startruntime=(Get-ChildItem C:\SPEC\SPECgpc\SPECviewperf2020\vpbench\gwpgRunBenchmark.js).LastWriteTime
 $resultfd=Get-ChildItem -Path C:\SPEC\SPECgpc\SPECviewperf2020\results_*  -Directory|?{$_.CreationTime -gt $startruntime}
 
$setindex="C:\SPEC\SPECgpc\SPECviewperf2020\vpbench\index.html"
$setindexb="C:\SPEC\SPECgpc\SPECviewperf2020\vpbench\index_0.html"
$mgntjs="C:\SPEC\SPECgpc\SPECviewperf2020\vpbench\gwpgManageBenchmark.js"
$mgntjsb="C:\SPEC\SPECgpc\SPECviewperf2020\vpbench\gwpgManageBenchmark_0.js"
$mgntrbjs="C:\SPEC\SPECgpc\SPECviewperf2020\vpbench\gwpgRunBenchmark.js"
$mgntrbjsb="C:\SPEC\SPECgpc\SPECviewperf2020\vpbench\gwpgRunBenchmark_0.js"

 }

 if( $resultfd.count -eq 0){
 exit
 }

 else{

 start-sleep -s 30

 (get-process -name msedge -ea SilentlyContinue).CloseMainWindow()

 start-process cmd -ArgumentList '/c schtasks /delete /TN "Auto_Run" -f' 

 Copy-Item -Path $resultfd.FullName -Destination $picpath -Recurse -Force
 
move-item $setindexb $setindex -Force
move-item $mgntjsb $mgntjs -Force
move-item $mgntrbjsb $mgntrbjs -Force

 $results="OK"
 $index=   $resultfd.name
 
 }
 }

### write log ##

Get-Module -name "outlog"|remove-module
$mdpath=(Get-ChildItem -path "C:\testing_AI\modules\" -r -file |?{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

#write-host "Do $action!"
outlog $action $results  $tcnumber $tcstep $index

 }


  
    export-modulemember -Function SPECviewperf_CompleteCheck