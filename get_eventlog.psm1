
function get_eventlog ([double]$para1){
    
    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force;
    $wshell=New-Object -ComObject wscript.shell
      Add-Type -AssemblyName Microsoft.VisualBasic
      Add-Type -AssemblyName System.Windows.Forms
        Add-Type -AssemblyName Microsoft.VisualBasic
   
$paracheck1=$PSBoundParameters.ContainsKey('para1')

if($paracheck1 -eq $false -or $para1 -eq 0){
$para1= 0
}

$settime=[double]$para1

if($PSScriptRoot.length -eq 0){
$scriptRoot="C:\testing_AI\modules"
}
else{
$scriptRoot=$PSScriptRoot
}

$action="get_eventlog"

$tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
$tcnumber=((get-content $tcpath).split(","))[0]
$tcstep=((get-content $tcpath).split(","))[1]
$picpath=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\"
$timenow=get-date -format "yyMMdd_HHmm"
if (-not(test-path $picpath)){New-Item -ItemType directory $picpath }
$evtfile="$picpath\Eventlog_$($timenow).csv" 

if($settime -ne 0){
$time0=(get-date).AddMinutes(-1*$settime)
$evt=get-winevent -FilterHashtable @{logname='application','system','setup','Microsoft-Windows-Diagnostics-Performance/Operational'} -Oldest | select-object -property Level,LevelDisplayName,LogName,TimeCreated,ProviderName,Id,TaskDisplayName,Message |`
 where {$_.TimeCreated -gt $time0 }

 if($evt.count -gt 0){
  $evt |export-csv -LiteralPath $evtfile -Encoding UTF8 -NoTypeInformation
  $index=$evtfile
  }
  else{
   $index="No Eventlog in $settime minutes (PASS)"
  }
 }

 else{
 get-winevent -FilterHashtable @{logname='application','system','setup','Microsoft-Windows-Diagnostics-Performance/Operational'} -Oldest | select-object -property Level,LevelDisplayName,LogName,TimeCreated,ProviderName,Id,TaskDisplayName,Message |`
  export-csv $evtfile  -Encoding UTF8 -NoTypeInformation

 }
  
$results="OK"

######### write log #######

Get-Module -name "outlog"|remove-module
$mdpath=(gci -path "C:\testing_AI\modules\"  -r -file |?{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

#write-host "Do $action!"
outlog $action $results $tcnumber $tcstep $index


  }

    export-modulemember -Function get_eventlog