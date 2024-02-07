
function SetScreenPrimary ([string]$para1,[string]$para2){
    
    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force;
    #$wshell=New-Object -ComObject wscript.shell
      Add-Type -AssemblyName Microsoft.VisualBasic
      Add-Type -AssemblyName System.Windows.Forms
 
  $source = @"
using System;
using System.Threading.Tasks;
using System.Runtime.InteropServices;
using System.Windows.Forms;
namespace KeySends
{
    public class KeySend
    {
        [DllImport("user32.dll")]
        public static extern void keybd_event(byte bVk, byte bScan, int dwFlags, int dwExtraInfo);
        private const int KEYEVENTF_EXTENDEDKEY = 1;
        private const int KEYEVENTF_KEYUP = 2;
        public static void KeyDown(Keys vKey)
        {
            keybd_event((byte)vKey, 0, KEYEVENTF_EXTENDEDKEY, 0);
        }
        public static void KeyUp(Keys vKey)
        {
            keybd_event((byte)vKey, 0, KEYEVENTF_EXTENDEDKEY | KEYEVENTF_KEYUP, 0);
        }
    }
}
"@
Add-Type -TypeDefinition $source -ReferencedAssemblies "System.Windows.Forms"
  

$paracheck=$PSBoundParameters.ContainsKey('para1')
$paracheck2=$PSBoundParameters.ContainsKey('para2')


if( $paracheck -eq $false -or $para1.length -eq 0 ){
$para1=""
}
$nonlog=$para1
if( $paracheck2 -eq $false -or $para2.length -eq 0 ){
$para2=""
}

$showonlypri=$para1
$reversesetting=$para2
$nonlog=$para3

if($PSScriptRoot.length -eq 0){
$scriptRoot="C:\testing_AI\modules"
}
else{
$scriptRoot=$PSScriptRoot
}

$action="SetPrimaryScreen"
$tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
$tcnumber=((get-content $tcpath).split(","))[0]
$tcstep=((get-content $tcpath).split(","))[1]

$timenow=get-date -format "yyMMdd_HHmmss"
#$picpath=(Split-Path -Parent $scriptRoot)+"\logs\screenshot\"
$picpath=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\"
if(-not(test-path $picpath)){new-item -ItemType directory -path $picpath |out-null}
$moninfo=$picpath+"$($timenow)_step$($tcstep)_monitorinfo_before.csv"

$monitors = Get-WmiObject -Class Win32_DesktopMonitor
$numberOfMonitors = $monitors.Count

if($numberOfMonitors -gt 1){
    $actionss ="screenshot_multiscreen"
}
if($numberOfMonitors -eq 1){
    $actionss ="screenshot"
}

Get-Module -name $actionss|remove-module
$mdpath=(Get-ChildItem -path $scriptRoot -r -file |Where-object{$_.name -match "^$actionss\b" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global


    [KeySends.KeySend]::KeyDown("LWin")
    [KeySends.KeySend]::KeyUp("LWin")
    Start-Sleep -s 2

&$actionss -para3 nolog -para5 "before"

    [KeySends.KeySend]::KeyDown("LWin")
    [KeySends.KeySend]::KeyUp("LWin")

Start-Sleep -s 2

$mtool="C:\testing_AI\modules\MultiMonitorTool\MultiMonitorTool.exe"
&$mtool /scomma $moninfo
do{
Start-Sleep -s 5
}until(test-path  $moninfo)
Start-Sleep -s 5

$moninfodata=import-csv  $moninfo|Where-object{$_.Active -eq "Yes"}

if($reversesetting.Length -eq 0){
$maxr=0
foreach($mondata in $moninfodata){
$rex=((($mondata."Maximum Resolution").split("X"))[0]).trim()
if($rex -gt $maxr){
$maxr=$rex
$maxname=$mondata.Name
}
}
$setname=$maxname
&$mtool /SetPrimary $maxname
}

if($reversesetting.Length -gt 0){
    $minr=9999999
    foreach($mondata in $moninfodata){
    $rex=((($mondata."Maximum Resolution").split("X"))[0]).trim()
    if($rex -lt $minr){
      $minr=$rex
    $minname=$mondata.Name
    }
    }
    $setname=$minname
    &$mtool /SetPrimary $minname
}

Start-Sleep -s 20


$timenow=get-date -format "yyMMdd_HHmmss"
$moninfo2=$picpath+"$($timenow)_step$($tcstep)_monitorinfo_after.csv"

&$mtool /scomma $moninfo2

do{
Start-Sleep -s 5
}until(test-path  $moninfo2)
Start-Sleep -s 5



## show only primary
if($showonlypri.length -gt 0){
$nonpris=(import-csv  $moninfo2|Where-object{$_.Active -eq "Yes" -and $_.name -ne $maxname}).name
foreach ($nonpri in $nonpris){
&$mtool /disable $nonpri
Start-Sleep -s 10
}
}

    [KeySends.KeySend]::KeyDown("LWin")
    [KeySends.KeySend]::KeyUp("LWin")
    Start-Sleep -s 2

&$actionss -para3 nolog -para5 "after"

    [KeySends.KeySend]::KeyDown("LWin")
    [KeySends.KeySend]::KeyUp("LWin")

Start-Sleep -s 2

$newprimary=(import-csv  $moninfo2|Where-object{$_.Active -eq "Yes" -and $_.Primary  -eq "Yes"}).name

$results="NG"
$index="Fail to setup primary display, need check"
if($newprimary -eq $setname ){
$results="OK"
$index="$setname set as primary display"
}

######### write log #######

if($nonlog.Length -eq 0){
Get-Module -name "outlog"|remove-module
$mdpath=(Get-ChildItem -path "C:\testing_AI\modules\"  -r -file |Where-object{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

#write-host "Do $action!"
outlog $action $results $tcnumber $tcstep $index
}

  }

    export-modulemember -Function SetScreenPrimary