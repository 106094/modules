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
$picpath=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\"
if(-not(test-path $picpath)){new-item -ItemType directory -path $picpath |out-null}
$results="OK"
$index="check logs"

$appname="Windows Assessment Console"
$apppname="wac"
$apppname2="axe"

#region import functions
$actiontask1="taskschedule_attime_repeat"
Get-Module -name $actiontask1=|remove-module
$mdpath=(Get-ChildItem -path $scriptRoot -r -file |Where-object{$_.name -match "^$actiontask1\b" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global


$actiontask2="taskschedule_delete"
Get-Module -name $actiontask2=|remove-module
$mdpath=(Get-ChildItem -path $scriptRoot -r -file |Where-object{$_.name -match "^$actiontask2\b" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global
   
$actionss ="screenshot"
Get-Module -name $actionss|remove-module
$mdpath=(Get-ChildItem -path $scriptRoot -r -file |Where-object{$_.name -match "^$actionss\b" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

$actionapp ="startmenuapp"
Get-Module -name $actionapp|remove-module
$mdpath=(Get-ChildItem -path $scriptRoot -r -file |Where-object{$_.name -match "^$actionapp\b" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

$cSource = @'
using System;
using System.Drawing;
using System.Runtime.InteropServices;
using System.Windows.Forms;
public class Clicker
{
//https://msdn.microsoft.com/en-us/library/windows/desktop/ms646270(v=vs.85).aspx
[StructLayout(LayoutKind.Sequential)]
struct INPUT
{ 
  public int        type; // 0 = INPUT_MOUSE,
                          // 1 = INPUT_KEYBOARD
                          // 2 = INPUT_HARDWARE
  public MOUSEINPUT mi;
}

//https://msdn.microsoft.com/en-us/library/windows/desktop/ms646273(v=vs.85).aspx
[StructLayout(LayoutKind.Sequential)]
struct MOUSEINPUT
{
  public int    dx ;
  public int    dy ;
  public int    mouseData ;
  public int    dwFlags;
  public int    time;
  public IntPtr dwExtraInfo;
}

//This covers most use cases although complex mice may have additional buttons
//There are additional constants you can use for those cases, see the msdn page
const int MOUSEEVENTF_MOVED      = 0x0001 ;
const int MOUSEEVENTF_LEFTDOWN   = 0x0002 ;
const int MOUSEEVENTF_LEFTUP     = 0x0004 ;
const int MOUSEEVENTF_RIGHTDOWN  = 0x0008 ;
const int MOUSEEVENTF_RIGHTUP    = 0x0010 ;
const int MOUSEEVENTF_MIDDLEDOWN = 0x0020 ;
const int MOUSEEVENTF_MIDDLEUP   = 0x0040 ;
const int MOUSEEVENTF_WHEEL      = 0x0080 ;
const int MOUSEEVENTF_XDOWN      = 0x0100 ;
const int MOUSEEVENTF_XUP        = 0x0200 ;
const int MOUSEEVENTF_ABSOLUTE   = 0x8000 ;

const int screen_length = 0x10000 ;

//https://msdn.microsoft.com/en-us/library/windows/desktop/ms646310(v=vs.85).aspx
[System.Runtime.InteropServices.DllImport("user32.dll")]
extern static uint SendInput(uint nInputs, INPUT[] pInputs, int cbSize);

public static void LeftClickAtPoint(int x, int y)
{
  //Move the mouse
  INPUT[] input = new INPUT[3];
  input[0].mi.dx = x*(65535/System.Windows.Forms.Screen.PrimaryScreen.Bounds.Width);
  input[0].mi.dy = y*(65535/System.Windows.Forms.Screen.PrimaryScreen.Bounds.Height);
  input[0].mi.dwFlags = MOUSEEVENTF_MOVED | MOUSEEVENTF_ABSOLUTE;
  //Left mouse button down
  input[1].mi.dwFlags = MOUSEEVENTF_LEFTDOWN;
  //Left mouse button up
  input[2].mi.dwFlags = MOUSEEVENTF_LEFTUP;
  SendInput(3, input, Marshal.SizeOf(input[0]));
}
}
'@
Add-Type -TypeDefinition $cSource -ReferencedAssemblies System.Windows.Forms,System.Drawing
function Set-WindowState {
<#
.LINK
https://gist.github.com/Nora-Ballard/11240204
#>

[CmdletBinding(DefaultParameterSetName = 'InputObject')]
param(
  [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
  [Object[]] $InputObject,

  [Parameter(Position = 1)]
  [ValidateSet('FORCEMINIMIZE', 'HIDE', 'MAXIMIZE', 'MINIMIZE', 'RESTORE',
         'SHOW', 'SHOWDEFAULT', 'SHOWMAXIMIZED', 'SHOWMINIMIZED',
         'SHOWMINNOACTIVE', 'SHOWNA', 'SHOWNOACTIVATE', 'SHOWNORMAL')]
  [string] $State = 'SHOW'
)

Begin {
  $WindowStates = @{
    'FORCEMINIMIZE'		= 11
    'HIDE'				= 0
    'MAXIMIZE'			= 3
    'MINIMIZE'			= 6
    'RESTORE'			= 9
    'SHOW'				= 5
    'SHOWDEFAULT'		= 10
    'SHOWMAXIMIZED'		= 3
    'SHOWMINIMIZED'		= 2
    'SHOWMINNOACTIVE'	= 7
    'SHOWNA'			= 8
    'SHOWNOACTIVATE'	= 4
    'SHOWNORMAL'		= 1
  }

  $Win32ShowWindowAsync = Add-Type -MemberDefinition @'
[DllImport("user32.dll")]
public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);
'@ -Name "Win32ShowWindowAsync" -Namespace Win32Functions -PassThru

  if (!$global:MainWindowHandles) {
    $global:MainWindowHandles = @{ }
  }
}

Process {
  foreach ($process in $InputObject) {
    if ($process.MainWindowHandle -eq 0) {
      if ($global:MainWindowHandles.ContainsKey($process.Id)) {
        $handle = $global:MainWindowHandles[$process.Id]
      } else {
        Write-Error "Main Window handle is '0'"
        continue
      }
    } else {
      $handle = $process.MainWindowHandle
      $global:MainWindowHandles[$process.Id] = $handle
    }

    $Win32ShowWindowAsync::ShowWindowAsync($handle, $WindowStates[$State]) | Out-Null
    Write-Verbose ("Set Window State '{1} on '{0}'" -f $MainWindowHandle, $State)
  }
}
}

#endregion

#check start or running
$axerun=get-process -name $apppname2

if(!$axerun){

&$actionapp -para1 $appname  -para3 "nonlog"
start-sleep -s 20

$wacpid=(get-process -name $apppname).Id
[Microsoft.VisualBasic.Interaction]::AppActivate($wacpid)

  [Clicker]::LeftClickAtPoint(20,1)

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
  
  #set taskschedule time repeat after 30 min every 5 min
  &$actiontask1 -para1 30 -para2 5 -para4 "nonlog"
  
  exit

  }
  else{
  $results="NG"
  $index="fail to run"
  }
  }

#collect log
else{
  $starttime=(Get-ChildItem C:\testing_AI\logs\logs_timemap.csv).lastwritetime
  $testtime=(New-TimeSpan -Start $starttime -End (get-date)).TotalMinutes
  if($testtime -gt 60){
  $results="NG"
  $index="testing time over 60 minutes, please check"
  $teststatus="wactestovertime"

  }
  else{
  $axecmd=(get-process *|Where-Object {$_.MainWindowTitle -match "axe"}).Id
  [Microsoft.VisualBasic.Interaction]::AppActivate($axecmd) |out-null
  Get-Process -id $axecmd  | Set-WindowState -State MAXIMIZE
  Start-Sleep -Seconds 1
  [Clicker]::LeftClickAtPoint(1,1)
  start-sleep -s 1
  
  $wshell.SendKeys("E")
  start-sleep -s 1
  $wshell.SendKeys("S")
  start-sleep -s 1
  $wshell.SendKeys("~")
  start-sleep -s 3
  $contents=Get-Clipboard
  start-sleep -s 3
  if($contents -match "Press any key to finish"){
  
  $xmlresult=split-path (($contents -match "\.xml") -match "JobResults")
  try{
  move-item $xmlresult -Destination $picpath -Recurse -Force
  }catch{
    write-host "fail to move reuslt folder"
   copy-item $xmlresult -Destination $picpath -Recurse -Force
  }
  
  
  $teststatus="wactestfinish"

  }

  else{
  exit
  }
  
  }
  
  &$actionss -para3 "nolog" -para5 $teststatus
  (Get-Process -id $axecmd).CloseMainWindow()
  
  &$actionss -para3 "nolog" -para5 "wactestfinish"

  $wacpid=(get-process -name $apppname).Id
  [Microsoft.VisualBasic.Interaction]::AppActivate($wacpid)
 
  &$actionss -para3 "nolog" -para5 "wactestreport"
      
  (Get-Process -id $wacpid).CloseMainWindow()

  #remove tasks schedule
  &$actiontask2 -para1 "nonlog"
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

  export-modulemember -Function wactest