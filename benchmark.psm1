
function benchmark ([string]$para1, [string]$para2, [string]$para3,[string]$para4){
    
  Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force;
  $shell=New-Object -ComObject shell.application
  $wshell=New-Object -ComObject wscript.shell
    Add-Type -AssemblyName Microsoft.VisualBasic
     Add-Type -AssemblyName System.Windows.Forms
      Add-Type -AssemblyName System.Windows.Forms,System.Drawing

#region functions

Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public class Window {
  [DllImport("user32.dll")]
  [return: MarshalAs(UnmanagedType.Bool)]
  public static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect);
}

public class Win32 {
  [DllImport("user32.dll", SetLastError = true)]
  public static extern IntPtr FindWindow(string lpClassName, string lpWindowName);

  [DllImport("user32.dll")]
  [return: MarshalAs(UnmanagedType.Bool)]
  public static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect);
}

public struct RECT {
  public int Left;
  public int Top;
  public int Right;
  public int Bottom;
}
"@

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

# create a new .NET type
$signature = @"
[DllImport("user32.dll")]public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);
"@
Add-Type -MemberDefinition $signature -Name MyType -Namespace MyNamespace

## https://github.com/proxb/PowerShell_Scripts/blob/master/Set-Window.ps1
Function Set-Window ([string]$processname,$x,$y){

Try{
          [void][Window]
      } Catch {
      Add-Type @"
            using System;
            using System.Runtime.InteropServices;
            public class Window {
              [DllImport("user32.dll")]
              [return: MarshalAs(UnmanagedType.Bool)]
              public static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect);
              [DllImport("User32.dll")]
              public extern static bool MoveWindow(IntPtr handle, int x, int y, int width, int height, bool redraw);
            }
            public struct RECT
            {
              public int Left;        // x position of upper-left corner
              public int Top;         // y position of upper-left corner
              public int Right;       // x position of lower-right corner
              public int Bottom;      // y position of lower-right corner
            }
"@
      }

      $Rectangle = New-Object RECT
      $Handle = (Get-Process -Name $processname).MainWindowHandle
      $Return = [Window]::GetWindowRect($Handle,[ref]$Rectangle)
      $Width = $Rectangle.Right - $Rectangle.Left   
      $Height = $Rectangle.Bottom - $Rectangle.Top
      [Window]::MoveWindow($Handle, $x, $y, $Width, $Height,$True)

      }
      
#endregion functions

#region tc settings
$paracheck1=$PSBoundParameters.ContainsKey('para1')
$paracheck2=$PSBoundParameters.ContainsKey('para2')
$paracheck3=$PSBoundParameters.ContainsKey('para3')
$paracheck4=$PSBoundParameters.ContainsKey('para4')

if($paracheck3 -eq $false -or $para3.Length -eq 0){
$para3=""
}
if($paracheck4 -eq $false -or $para4.Length -eq 0){
$para4=""
}

$bitype=$para1
$bitconfig=$para2
$noexit_flag=$para3
$option2=$para4

if($PSScriptRoot.length -eq 0){
$scriptRoot="C:\testing_AI\modules"
}
else{
$scriptRoot=$PSScriptRoot
}

$actionss="screenshot"
Get-Module -name $actionss|remove-module
$mdpath=(Get-ChildItem -path $scriptRoot -r -file |Where-object{$_.name -match "^$actionss\b" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

$actioncmd="cmdline"
Get-Module -name $actioncmd|remove-module
$mdpath=(Get-ChildItem -path $scriptRoot -r -file |Where-object{$_.name -match "^$actioncmd\b" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

$tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
$tcnumber=((get-content $tcpath).split(","))[0]
$tcstep=((get-content $tcpath).split(","))[1]

$timenow=get-date -format "yyMMdd_HHmmss"
#$picpath=(Split-Path -Parent $scriptRoot)+"\logs\screenshot\"
$picpath=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\"
if(-not(test-path $picpath)){new-item -ItemType directory -path $picpath |out-null}


$screen = [System.Windows.Forms.Screen]::PrimaryScreen
$bounds = $screen.Bounds
$width  = $bounds.Width
$height  =$bounds.Height

#$width  = ([string]::Join("`n", (wmic path Win32_VideoController get CurrentHorizontalResolution))).split("`n") -match "\d{1,}" |select -first 1
#$height  = ([string]::Join("`n", (wmic path Win32_VideoController get CurrentVerticalResolution))).split("`n") -match "\d{1,}" |select -first 1

#endregion

if($bitype -match "passmark"){

$action="passmark burnin"

$bifolder= "C:\Program Files\BurnInTest\bit.exe"
$bipath=(Get-ChildItem "$scriptRoot\BITools\$bitype\" -r -file |Where-object{$_.name -match "bit" -and $_.name -match "exe"}).FullName
$keypath=(Get-ChildItem "$scriptRoot\BITools\$bitype\" -r -file |Where-object{$_.name -match "key"}).FullName
$cfgpath=(Get-ChildItem "$scriptRoot\BITools\config\" -r -file |Where-object{$_.name -match $bitconfig}).FullName

#check $bitconfig volumn # exist ##
if($bitconfig -match "volume"){
$text1=($bitconfig -split "volume")[1]
$diskid=$text1.Substring(0,1)

$currentdisks= ((Get-WmiObject -Class Win32_LogicalDisk |Where-Object{$_.providername -notlike "\\*"}).name).replace(":","")
$currentdiskstring=$currentdisks|Out-String
write-host "current all disks:$currentdiskstring"

if(!($diskid -in $currentdisks)){
write-host "Drive $diskid doesnot exist, quit running, go to next step"
$resultNG="NG"
$index="no disk $diskid exist in $currentdiskstring"
$noexit_flag="noexit" 
}


}

if(!$resultNG){

if((test-path $bifolder) -eq $false){

new-item -ItemType directory  -path "C:\Program Files\BurnInTest\" -Force | Out-Null
copy-item "$keypath" -destination "C:\Program Files\BurnInTest\" -Force | Out-Null

&$bipath /VERYSILENT 
 
do{

$bitp=Get-Process -Name "bit" -ErrorAction SilentlyContinue
$bcount=($bitp.id).Count
Start-Sleep -s 1
} until ($bcount -eq 1)
  


}

 $des= "c:\dash\tools\storage\burnintest\"
 if(-not(test-path $des)){new-item -ItemType directory -Path $des |Out-Null}
copy-item C:\testing_AI\modules\BITools\passmark\Bear.wmv  $des  -force 

 start-sleep -s 10
   
taskkill -pid (get-process |Where-object{$_ -match "bit"}).Id /F

start-sleep -s 5


##### pcaui delete for windows 11 new pcaui mesasge tab once (old versoin tab twice) ###
$checkpcaui= ((get-process pcaui -ErrorAction SilentlyContinue).id).count
$checkpcauiids= ((get-process pcaui -ErrorAction SilentlyContinue).id)
if($checkpcaui -gt 0){
   foreach($checkpcauiid in $checkpcauiids){
  [Microsoft.VisualBasic.Interaction]::AppActivate($checkpcauiid)
  Start-Sleep -s 2
    [System.Windows.Forms.SendKeys]::SendWait("{tab}")
    Start-Sleep -s 1
     [System.Windows.Forms.SendKeys]::SendWait(" ")
     Start-Sleep -s 1
      [System.Windows.Forms.SendKeys]::SendWait("{tab 2}")
      Start-Sleep -s 1
     [System.Windows.Forms.SendKeys]::SendWait(" ")
     Start-Sleep -s 1
     }
     }

(get-process pcaui -ea SilentlyContinue)|Stop-Process -Force -ErrorAction SilentlyContinue


start-sleep -s 3

&$bifolder /C $cfgpath /R

 start-sleep -s 10

##### pcaui delete for windows 11 new pcaui mesasge tab once (old versoin tab twice) ###
$checkpcaui= ((get-process pcaui -ErrorAction SilentlyContinue).id).count
$checkpcauiids= ((get-process pcaui -ErrorAction SilentlyContinue).id)
if($checkpcaui -gt 0){
   foreach($checkpcauiid in $checkpcauiids){
  [Microsoft.VisualBasic.Interaction]::AppActivate($checkpcauiid)
  Start-Sleep -s 2
    [System.Windows.Forms.SendKeys]::SendWait("{tab}")
    Start-Sleep -s 1
     [System.Windows.Forms.SendKeys]::SendWait(" ")
     Start-Sleep -s 1
      [System.Windows.Forms.SendKeys]::SendWait("{tab 2}")
      Start-Sleep -s 1
     [System.Windows.Forms.SendKeys]::SendWait(" ")
     Start-Sleep -s 1
     }
     }

(get-process pcaui -ea SilentlyContinue)|Stop-Process -Force -ErrorAction SilentlyContinue

 Start-Sleep -s 20

##### screen shot ###

$title=(get-process bit).MainWindowTitle

if ( $title -match "evaluation"){

[Microsoft.VisualBasic.Interaction]::AppActivate("Error")
Start-Sleep -s 1
[System.Windows.Forms.SendKeys]::SendWait("% ")
[System.Windows.Forms.SendKeys]::SendWait("{Down}")
[System.Windows.Forms.SendKeys]::SendWait("{Enter}")
start-sleep -s 2

}


$cmptid= (get-process *|Where-object{$_.MainWindowTitle -match "Program Compatibility Assistant"}).Id
if ($cmptid -ne $null){

[Microsoft.VisualBasic.Interaction]::AppActivate($cmptid)
Start-Sleep -s 1
[System.Windows.Forms.SendKeys]::SendWait("% ")
[System.Windows.Forms.SendKeys]::SendWait("{Down}")
[System.Windows.Forms.SendKeys]::SendWait("{Enter}")
start-sleep -s 2

}


$title=(get-process bit).MainWindowTitle


[Microsoft.VisualBasic.interaction]::AppActivate($title)|out-null

## scrrenshot##

&$actionss  -para3 nonlog -para5 "$action-start"
 

## second picture ##

&$actionss  -para3 nonlog -para5 "$action-start2"
 

}

}

if($bitype -match "furmark"){

$action="furmark burnin"
$duration=($bitype.split("-"))[1]
if($duration.length -eq 0){$duration=1}
 $bitype= ($bitype.split("-"))[0]

$durationtime=[int64]$duration*60*1000

$bifolder= "C:\Program Files (x86)\Geeks3D\Benchmarks\FurMark\FurMark.exe"
$bipath=(Get-ChildItem "$scriptRoot\BITools\$bitype\" -r -file |Where-object{$_.name -match "FurMark" -and $_.name -match "exe"}).FullName
#$keypath=(Get-ChildItem "$scriptRoot\BITools\$bitype\" -r -file |Where-object{$_.name -match "key"}).FullName
#$cfgpath=(Get-ChildItem "$scriptRoot\BITools\config\" -r -file |Where-object{$_.name -match $bitconfig}).FullName

if((test-path $bifolder) -eq $false){

#new-item -ItemType directory  -path "C:\Program Files\BurnInTest\" -Force | Out-Null
#copy-item "$keypath" -destination "C:\Program Files\BurnInTest\" -Force | Out-Null

&$bipath /VERYSILENT 
 
do{
$checkinstall=test-path $bifolder
Start-Sleep -s 1
} until ($checkinstall -eq $true) 
}

start-sleep -s 10

do{

### check if furmark running ##
get-process -name furmark -ErrorVariable b -ErrorAction SilentlyContinue
if(-not (($b.CategoryInfo).Reason -match  "ProcessCommandException")){
   taskkill -pid (get-process |Where-object{$_ -match "furmark"}).Id /F
         start-sleep -s 2
    }

#  &$bifolder /width=$width  /height=$height /fullscreen /max_time=$durationtime /run_mode=1 /log_score /disable_catalyst_warning
&$bifolder /width=$width  /height=$height  /max_time=$durationtime /run_mode=1 /log_score /disable_catalyst_warning

 start-sleep -s 10

 if($wshell.AppActivate('FurMark - Check for update') -eq $true ){
 start-sleep -s 2
$wshell.SendKeys("%{F4}")
  start-sleep -s 2
}

## settings screen shot
if($wshell.AppActivate('Geeks3D') -eq $true ){


## scrrenshot##

&$actionss  -para3 nonlog -para5 "$action-settings"
 
$picfile1=(Get-ChildItem $picpath |Where-object{$_.name -match ".jpg" -and $_.name -match "$action-settings" }).FullName

## start running

$wshell.AppActivate('Geeks3D')
 start-sleep -s 2
$wshell.SendKeys("+{tab 5}")
#[System.Windows.Forms.SendKeys]::SendWait("+{tab 5}")
  start-sleep -s 5
  $wshell.SendKeys("~")
  start-sleep -s 2
  
if($wshell.AppActivate('*** Caution') -eq $true ){
 start-sleep -s 1
    $wshell.SendKeys("~")
  start-sleep -s 2
  }
}

start-sleep -s 10

$checkrun= (get-process -name furmark).MainWindowTitle -match "FPS"

} until ($checkrun -eq $true)

<##### screen shot by F9 ###

$pic1= (Get-ChildItem -path  "C:\Program Files (x86)\Geeks3D\Benchmarks\FurMark\screenshots\*" -Recurse -file -Filter "*jpg*").fullname

 start-sleep -s 2  
$wshell.SendKeys("{F1}")
start-sleep -s 2  
$wshell.SendKeys("G")
start-sleep -s 2
$wshell.SendKeys("{F9}")
start-sleep -s 5  

$pic2= (Get-ChildItem -path  "C:\Program Files (x86)\Geeks3D\Benchmarks\FurMark\screenshots\*" -Recurse -file -Filter "*jpg*").fullname
foreach($pic in $pic2){
if($pic -notin $pic1){
$picfile=$picpath+"$timenow-$tcnumber-$tcstep-$action-1.jpg"
Copy-Item  $pic -Destination $picfile -Force
}
}

$wshell.SendKeys("{F1}")
start-sleep -s 2  
$wshell.SendKeys("G")
start-sleep -s 2
$wshell.SendKeys("{F9}")
start-sleep -s 5  

$pic3= (Get-ChildItem -path  "C:\Program Files (x86)\Geeks3D\Benchmarks\FurMark\screenshots\*" -Recurse -file -Filter "*jpg*").fullname
foreach($pic in $pic3){
if($pic -notin $pic2){
$picfile=$picpath+"$timenow-$tcnumber-$tcstep-$action-2.jpg"
Copy-Item  $pic -Destination $picfile -Force
}
}

##### screen shot by F9 ###>

start-sleep -s 10
  [KeySends.KeySend]::KeyDown("LWin")
  [KeySends.KeySend]::KeyDown("B")
  [KeySends.KeySend]::KeyUp("LWin")
  [KeySends.KeySend]::KeyUp("B")
  Start-Sleep -s 1
  [KeySends.KeySend]::KeyDown("LWin")
  [KeySends.KeySend]::KeyUp("LWin")
  Start-Sleep -s 1
  [KeySends.KeySend]::KeyDown("LWin")
  [KeySends.KeySend]::KeyUp("LWin")
   Start-Sleep -s 2

##### screen shot by Windows ###

&$actionss  -para3 nonlog -para5 "$action-start"
 
$picfile2=(Get-ChildItem $picpath |Where-object{$_.name -match ".jpg" -and $_.name -match "$action-start" }).FullName

$picfile=[string]::join("`n",$picfile1,$picfile2)

#$id=(get-process -name FurMark).id
#$wshell.AppActivate($id)

}

if($bitype -match "FluidMark"){

if($wshell.AppActivate('Geeks3D') -eq $true ){
(get-process -name FluidMark -ea SilentlyContinue).CloseMainWindow()
}

$action="FluidMark burnin"
$duration=($bitype.split("-"))[1]
if($duration.length -eq 0){$duration=1}
$bitype= ($bitype.split("-"))[0]
$counts=[int64]$duration
#$durationtime=[int64]$duration*60*1000

$bifolder= "C:\Program Files (x86)\Geeks3D\Benchmarks\FluidMark\"
$bitprg=".\FluidMark.exe"

$bipath=(Get-ChildItem "$scriptRoot\BITools\$bitype\" -r -file |Where-object{$_.name -match "FluidMark" -and $_.name -match "exe"}).FullName
$bipath2=(Get-ChildItem "$scriptRoot\BITools\$bitype\" -r -file -filter "*PhysX*System*").FullName

#$keypath=(Get-ChildItem "$scriptRoot\BITools\$bitype\" -r -file |Where-object{$_.name -match "key"}).FullName
#$cfgpath=(Get-ChildItem "$scriptRoot\BITools\config\" -r -file |Where-object{$_.name -match $bitconfig}).FullName

## install##
if((test-path  "C:\Program Files (x86)\Geeks3D\Benchmarks\FluidMark\data") -eq $false){

#new-item -ItemType directory  -path "C:\Program Files\BurnInTest\" -Force | Out-Null
#copy-item "$keypath" -destination "C:\Program Files\BurnInTest\" -Force | Out-Null

&$bipath2 -s
&$bipath /VERYSILENT
 
do{
$checkinstall=test-path  "C:\Program Files (x86)\Geeks3D\Benchmarks\FluidMark\data"
Start-Sleep -s 1
} until ($checkinstall -eq $true)

 Copy-Item "C:\testing_AI\modules\BITools\FluidMark\startup_options.xml" "C:\Program Files (x86)\Geeks3D\Benchmarks\FluidMark\" -Force

}

<## play for counts ##

$x=0

do{

$x++

set-location $bifolder
#&$bitprg /width=$width  /height=$height /fullscreen 

&".\start_preset_1080.bat"

 start-sleep -s 10

if($wshell.AppActivate('Geeks3D') -eq $true ){

 ### window focus ###

Get-Module -name appfocus |remove-module
$mdpath=(Get-ChildItem -path $scriptRoot -r -file |Where-object{$_.name -match "^appfocus\b" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global
appfocus -para1 FluidMark

start-sleep -s 5

##### screen shot ###

$timenow=get-date -format "yyMMdd_HHmmss"

$picfile=$picpath+"$($timenow)-$($tcnumber)-$($tcstep)-$($action)"+"_cycle-$($x)_starting.jpg" 
$bounds   = [Drawing.Rectangle]::FromLTRB(0, 0, [int64] $width.trim() , [int64] $height.trim() )
$bmp      = New-Object System.Drawing.Bitmap ([int]$bounds.width), ([int]$bounds.height)
$graphics = [Drawing.Graphics]::FromImage($bmp)
$graphics.CopyFromScreen($bounds.Location, [Drawing.Point]::Empty, $bounds.size)  
start-sleep -s 5
$bmp.Save($picfile)
start-sleep -s 2
$graphics.Dispose()
$bmp.Dispose()

 start-sleep -s 2
 
$wshell.SendKeys("{tab}")
  start-sleep -s 2
$wshell.SendKeys("+{tab}")
  start-sleep -s 2
  $wshell.SendKeys("~")
  start-sleep -s 2

}

start-sleep -s 5

  
##### screen shot when running ###

$n=0

do{
start-sleep -s 180

$checkrunning=$wshell.AppActivate('FluidMark') 

if($checkrunning -eq $true ){

##### screen shot ###
  
$timenow=get-date -format "yyMMdd_HHmmss"

$picfile=$picpath+"$($timenow)-$($tcnumber)-$($tcstep)-$($action)"+"_cycle-"+"$($x)_$($n)"+".jpg"

$bounds   = [Drawing.Rectangle]::FromLTRB(0, 0, [int64] $width.trim() , [int64] $height.trim() )
$bmp      = New-Object System.Drawing.Bitmap ([int]$bounds.width), ([int]$bounds.height)
$graphics = [Drawing.Graphics]::FromImage($bmp)
$graphics.CopyFromScreen($bounds.Location, [Drawing.Point]::Empty, $bounds.size)  
start-sleep -s 5
$bmp.Save($picfile)
start-sleep -s 2
$graphics.Dispose()
$bmp.Dispose()



$n++

}

}until($checkrunning -eq $false )

start-sleep -s 5


if($wshell.AppActivate('Geeks3D') -eq $true ){
 
(get-process -name FluidMark -ea SilentlyContinue).CloseMainWindow()
if($wshell.AppActivate('Geeks3D') -eq $true ){
stop-process -name FluidMark -ea SilentlyContinue
}

}


}until($x -ge $counts)

## play for counts ##>

}

if($bitype -match "prime95"){

$action="prime95 stress burnin"

$bipath=(Get-ChildItem "$scriptRoot\BITools\$bitype\" -r -file |Where-object{$_.name -match $bitype -and $_.name -match "exe"}).FullName

$checkrun=((get-process -Name prime95 -ErrorAction SilentlyContinue).Id).count

if( $checkrun -ne 0){
taskkill /IM prime95.exe /F 
  start-sleep -s 10
    }

 remove-item -Path $scriptRoot\BITools\$bitype\prime.txt -Force
 remove-item -Path $scriptRoot\BITools\$bitype\local.txt -Force

&$bipath
 start-sleep -s 10
 
$primid= (get-process -name prime95).Id

$Handle = Get-Process prime95| Where-Object { $_.MainWindowTitle -match $env:TITLE } | ForEach-Object { $_.MainWindowHandle }
if ( $Handle -is [System.Array] ) { $Handle = $Handle[0] }
$WindowRect = New-Object RECT
$GotWindowRect = [Window]::GetWindowRect($Handle, [ref]$WindowRect)
#Write-Host $WindowRect.Left $WindowRect.Top $WindowRect.Right $WindowRect.Bottom

##scale
$bdh=(([System.Windows.Forms.Screen]::AllScreens|Select-Object Bounds).Bounds).Bottom 
$height  = ([string]::Join("`n", (wmic path Win32_VideoController get CurrentVerticalResolution))).split("`n") -match "\d{1,}"
#$sacle=$height[0]/$bdh[0]
$sacle=1 ## for command use, no need to divided with scale ( don't know the reason yet)

$x1=[math]::Round(($WindowRect.Left + $WindowRect.Right)/2/$sacle,0)
$y1=[math]::Round(($WindowRect.Top + $WindowRect.Bottom)/2/$sacle,0)


if( $wshell.AppActivate($primid) ){

#[Clicker]::LeftClickAtPoint( [int64]$width[0].ToString()/2, [int64]$height[0].ToString()/2)
[Clicker]::LeftClickAtPoint($x1, $y1)

start-sleep -s 3
$wshell.SendKeys("s")
  start-sleep -s 3

    $wshell.SendKeys("{tab}")
  start-sleep -s 2
    $wshell.SendKeys("2")
 start-sleep -s 2
$wshell.SendKeys("{tab}")
 start-sleep -s 2
$wshell.SendKeys("{tab}")
  start-sleep -s 2
  
 ##### screenshot for settings ###
    
&$actionss  -para3 nonlog -para5 "$action-settings"
 
$picfile1=(Get-ChildItem $picpath |Where-object{$_.name -match ".jpg" -and $_.name -match "$action-settings" }).FullName

 ##### go ###

$wshell.AppActivate('Run a Torture Test')
    $wshell.SendKeys("~")


 ##### screenshot for running ###
   start-sleep -s 20

   

&$actionss  -para3 nonlog -para5 "$action-start"
 
$picfile1=(Get-ChildItem $picpath |Where-object{$_.name -match ".jpg" -and $_.name -match "$action-start" }).FullName

$picfile=[string]::join("`n",$picfile1,$picfile2)



}


}


if($bitype -match "Unigine_Heaven"){

  $action="Unigine Heaven burnin"
  $appname="Heaven"
  $noexit_flag="noexit"  
  #API(opengl/dx11/dx9)|Quality(Low/Medium/High/Ultra)|Resolution(System/[WidthxLength])
  $bitconfig_api=($bitconfig.split("|"))[0]
  $bitconfig_quality=($bitconfig.split("|"))[1]
  $bitconfig_res=($bitconfig.split("|"))[2]
  if($bitconfig_res -match "x"){
   $bitconfig_resx=($bitconfig_res.split("x"))[0]
   $bitconfig_resy=($bitconfig_res.split("x"))[1]
  }
  $logfilename="Unigine_Heaven_Benchmark_4.0_"+$bitconfig.replace("|","_")+".html"
  $bipath=(Get-ChildItem "$scriptRoot\BITools\$bitype\" -r -file |Where-object{$_.name -match $bitype -and $_.name -match "exe"}).FullName
   
   $checkprocessing1=((get-process -name Valley -ea SilentlyContinue).Id).count 
   if( $checkprocessing1 -gt 0){
   taskkill /IM "$appname.exe" /F 
    start-sleep -s 20
    }
 
      $checkprocessing2=((get-process -name browser_x86 -ea SilentlyContinue).Id).count 
   if( $checkprocessing2 -gt 0){
   taskkill /IM browser_x86.exe /F 
    start-sleep -s 5
    }
 
    ### uninstall ###
 
  $uninstallexe="C:\Program Files (x86)\Unigine\Heaven Benchmark 4.0\unins000.exe"
 if(test-path $uninstallexe){
  &$uninstallexe /silent
  
  do{
  Start-Sleep -s 5
  $checkins=get-process -name unins000 -ErrorAction SilentlyContinue        
  }until(!$checkins)
  
    start-sleep -s 10
 
 }
 
 ### install ###
   
  write-host "start install $(get-date)"

   &$bipath /VERYSILENT
   #set-location "C:\Program Files (x86)\Unigine\Valley Benchmark 1.0\ 
   
  do{
  Start-Sleep -s 10
  $checkins=get-process -name Unigine_Heaven-4.0 -ErrorAction SilentlyContinue        
  }until(!$checkins)

  write-host "install cmplt $(get-date)"
    start-sleep -s 30
 
## brower js move ###
 $backuppath="C:\testing_AI\modules\BITools\Unigine_Heaven\backup\"
 $brwjsfrom="C:\testing_AI\modules\BITools\Unigine_Heaven"
 $brwjsfolder="C:\Program Files (x86)\Unigine\Heaven Benchmark 4.0\data\launcher\js"

 if(! (test-path $backuppath)){
 new-item -ItemType Directory $backuppath |Out-Null
 }

 Get-ChildItem -path $brwjsfolder -Filter "browser.js" |Copy-Item -Destination $backuppath -Force
 Get-ChildItem -path $brwjsfrom -Filter "browser.js" |Copy-Item -Destination $brwjsfolder -Force

 ## remove cashe##
 $cashe="$env:USERPROFILE\AppData\Local\file__0.localstorage"
 $cashe2="$env:HOMEPATH\Heaven\log.html"
 $cashe3="$env:USERPROFILE\documents\Unigine_Heaven_Benchmark_4.0*.html"
 if(test-path  $cashe){remove-item -path  $cashe -Force}
 if(test-path  $cashe2){remove-item -path  $cashe2 -Force}
 if(test-path  $cashe3){remove-item -path  $cashe3 -Force}
 
 ## start UI ##
 
 $runbatfile="C:\Program Files (x86)\Unigine\Heaven Benchmark 4.0\heaven.bat"
 #$runpath="C:\Program Files (x86)\Unigine\Heaven Benchmark 4.0\"
 
 $opentime=get-date
 
 &$runbatfile
  
 do{
  Start-Sleep -s 1
  $unigineid=(get-process -name * |Where-Object{$_.MainWindowTitle -match "Unigine Heaven Benchmark"}).Id
  $timepassed=(New-TimeSpan -start $opentime -end (get-date)).TotalSeconds
  }until ($unigineid -or $timepassed -gt 60)    
 
 if($timepassed -gt 60){
 $results="NG"
 $index="fail to open Unigin Heave"
 }

else{   

$Handle = (get-process -name * |Where-Object{$_.MainWindowTitle -match "Unigine Heaven Benchmark"}).MainWindowHandle
if ( $Handle -is [System.Array] ) { $Handle = $Handle[0] }
$WindowRect = New-Object RECT
$GotWindowRect = [Window]::GetWindowRect($Handle, [ref]$WindowRect)

##scale
$bdh=(([System.Windows.Forms.Screen]::AllScreens|Select-Object Bounds).Bounds).Bottom 
$height  = ([string]::Join("`n", (wmic path Win32_VideoController get CurrentVerticalResolution))).split("`n") -match "\d{1,}"
#$sacle=$height[0]/$bdh[0]
$sacle=1 ## for command use, no need to divided with scale ( don't know the reason yet)

$x1=[math]::Round(($WindowRect.Left + $WindowRect.Right)/2/$sacle,0)
$y1=[math]::Round(($WindowRect.Top + $WindowRect.Bottom)/2/$sacle,0)

[Microsoft.VisualBasic.interaction]::AppActivate($unigineid)|out-null
start-sleep -s 2
[Clicker]::LeftClickAtPoint($x1, $y1)
start-sleep -s 2

&$actionss  -para3 nonlog -para5 "open"

##api settings

[System.Windows.Forms.SendKeys]::SendWait("{tab 3}")
 Start-Sleep -s 1
[System.Windows.Forms.SendKeys]::SendWait(" ")
&$actionss  -para3 nonlog -para5 "API_check"
if($bitconfig_api -match "9"){
[System.Windows.Forms.SendKeys]::SendWait("{down}")
}
if($bitconfig_api -match "opengl"){
[System.Windows.Forms.SendKeys]::SendWait("{down 2}")
}
 Start-Sleep -s 1
[System.Windows.Forms.SendKeys]::SendWait("~")

##quality settings

[System.Windows.Forms.SendKeys]::SendWait("{tab}")
 Start-Sleep -s 1
[System.Windows.Forms.SendKeys]::SendWait(" ")
&$actionss  -para3 nonlog -para5 "Quality_check"

[System.Windows.Forms.SendKeys]::SendWait("{UP 5}")
 Start-Sleep -s 1
if($bitconfig_quality -match "medium"){
[System.Windows.Forms.SendKeys]::SendWait("{Down}")
}
if($bitconfig_quality -match "high"){
[System.Windows.Forms.SendKeys]::SendWait("{Down 2}")
}
if($bitconfig_quality -match "ultra"){
[System.Windows.Forms.SendKeys]::SendWait("{Down 3}")
}
  Start-Sleep -s 1
[System.Windows.Forms.SendKeys]::SendWait("~")

##resolution settings
[System.Windows.Forms.SendKeys]::SendWait("{tab 6}")
 Start-Sleep -s 1
[System.Windows.Forms.SendKeys]::SendWait(" ")
 Start-Sleep -s 1
&$actionss  -para3 nonlog -para5 "Resolution_check"

if($bitconfig_resx -and $bitconfig_resy){
[System.Windows.Forms.SendKeys]::SendWait("{Down}")
 Start-Sleep -s 1
[System.Windows.Forms.SendKeys]::SendWait("~")
 Start-Sleep -s 1
[System.Windows.Forms.SendKeys]::SendWait("{tab}")
set-clipboard $bitconfig_resx
Start-Sleep -s 5
[System.Windows.Forms.SendKeys]::SendWait("^v")
Start-Sleep -s 1
[System.Windows.Forms.SendKeys]::SendWait("{tab}")
set-clipboard $bitconfig_resy
Start-Sleep -s 5 
[System.Windows.Forms.SendKeys]::SendWait("^v")

}
else{
[System.Windows.Forms.SendKeys]::SendWait("~")
}


&$actionss  -para3 nonlog -para5 "allsettings"

## start to Run ###

[System.Windows.Forms.SendKeys]::SendWait("{tab}")
 Start-Sleep -s 1
[System.Windows.Forms.SendKeys]::SendWait(" ")

  start-sleep -s 30

  $checkrunning=Get-Process -name $appname -ErrorAction SilentlyContinue
  if(!$checkrunning){
   &$actionss  -para3 nonlog -para5 "run_fail"
  $results="NG"
  $index="Fail to run"
  
  }
  else{                              
    ### RUN benchmark ###
    [System.Windows.Forms.SendKeys]::SendWait("{F9}")
    start-sleep -s 5
    &$actionss  -para3 nonlog -para5 "run_benchmark"
    do{
     start-sleep -s 5
     $logout=test-path $env:HOMEPATH\Heaven\log.html   
     $result=Get-Content $env:HOMEPATH\Heaven\log.html 
     } until($logout -and $result -like "*score*")

     start-sleep -s 10
     &$actionss  -para3 nonlog -para5 "score"

     do{
      Start-Sleep -s 2
      [System.Windows.Forms.SendKeys]::SendWait("~")
      Start-Sleep -s 5
      [System.Windows.Forms.SendKeys]::SendWait("~")
      start-sleep -s 10
        $checkbenchresult=Get-ChildItem -path "$env:USERPROFILE\documents\Unigine_Heaven_Benchmark_4.0*.html"
     } until ($checkbenchresult)
          
      [System.Windows.Forms.SendKeys]::SendWait("%{F4}")
      start-sleep -s 5

      (get-process -name heaven -ErrorAction SilentlyContinue).CloseMainWindow()|Out-Null
      (get-process -name browser_x86 -ErrorAction SilentlyContinue).CloseMainWindow()|Out-Null

     copy-item $env:HOMEPATH\Heaven\log.html -Destination  $picpath -Force
     move-item $checkbenchresult -destination $picpath -Force
     $logfile1=(get-chileitem -path $picpath -file $checkbenchresult.name).fullname
     new-name -path $logfile1 -newname $logfilename
     
     #recover settings  
     Get-ChildItem $backuppath -file| Copy-Item -Destination "C:\Program Files (x86)\Unigine\Heaven Benchmark 4.0\data\launcher\js\" -Force
     remove-item -path  "$env:USERPROFILE\AppData\Local\file__0.localstorage"  -Force
       }

   }
 
   }    
 

if($bitype -match "Unigine_Valley"){

$action="Unigine Valley burnin"

$bipath=(Get-ChildItem "$scriptRoot\BITools\$bitype\" -r -file |Where-object{$_.name -match $bitype -and $_.name -match "exe"}).FullName

$checkprocessing1=((get-process -name Valley -ea SilentlyContinue).Id).count 
if( $checkprocessing1 -gt 0){
taskkill /IM Valley.exe /F 
 start-sleep -s 20
 }

   $checkprocessing2=((get-process -name browser_x86 -ea SilentlyContinue).Id).count 
if( $checkprocessing2 -gt 0){
taskkill /IM browser_x86.exe /F 
 start-sleep -s 5
 }

 ### uninstall ###

$uninstallexe="C:\Program Files (x86)\Unigine\Valley Benchmark 1.0\unins000.exe"
if(test-path $uninstallexe){
#&$uninstallexe /silent
$id0=(Get-Process cmd).Id

$runcommanduin="unins000.exe /silent"

set-location "C:\Program Files (x86)\Unigine\Valley Benchmark 1.0\"
start-process cmd -WindowStyle Maximized
start-sleep -s 2
$id3=(Get-Process cmd).Id|Where-object{$_ -notin $id0}
[Microsoft.VisualBasic.interaction]::AppActivate($id3)|out-null

### click cmd window and hit enter###
[Clicker]::LeftClickAtPoint(50, 1)
start-sleep -s 2
$wshell.SendKeys("~") 

### send command ## 
Set-Clipboard "$runcommanduin"
 start-sleep -s 5
[System.Windows.Forms.SendKeys]::SendWait("^v")
start-sleep -s 2
[System.Windows.Forms.SendKeys]::SendWait("~")
start-sleep -s 10

if( $wshell.AppActivate("Unigine Valley Benchmark Uninstall")){
start-sleep -s 2
[System.Windows.Forms.SendKeys]::SendWait("Y")
start-sleep -s 10
[System.Windows.Forms.SendKeys]::SendWait("~")
}

 taskkill /F /PID $id3

}

#&$bipath /VERYSILENT 
$id0=(Get-Process cmd).Id
$runcommandin="$bipath /VERYSILENT"
#set-location "C:\Program Files (x86)\Unigine\Valley Benchmark 1.0\"

start-process cmd -WindowStyle Maximized
start-sleep -s 2
$id3=(Get-Process cmd).Id|Where-object{$_ -notin $id0}
[Microsoft.VisualBasic.interaction]::AppActivate($id3)|out-null

### click cmd window and hit enter###
[Clicker]::LeftClickAtPoint(50, 1)
start-sleep -s 2
$wshell.SendKeys("~") 

### send command ## 
Set-Clipboard "$runcommandin"
start-sleep -s 5
[System.Windows.Forms.SendKeys]::SendWait("^v")
start-sleep -s 2
[System.Windows.Forms.SendKeys]::SendWait("~")

do{
start-sleep -s 10
 $checkins=get-process -name "Unigine_Valley-1.0" -ea SilentlyContinue
 }until(!$checkins)

write-host "install completed"
taskkill /F /PID $id3
 start-sleep -s 10

<#
 do{
  start-sleep -s 10
 $checkinstall=test-path "C:\Program Files (x86)\Unigine\Valley Benchmark 1.0\valley.bat"
 $checkinstall2=test-path "C:\Program Files (x86)\Unigine\Valley Benchmark 1.0\bin\browser_x86.exe"
 }until($checkinstall -eq $true -and $checkinstall2 -eq $true)
    start-sleep -s 30
    #>
### setting video type ##

## brower window screen js move###

copy-item "C:\testing_AI\modules\BITools\Unigine_Valley\browser.js" -Destination "C:\Program Files (x86)\Unigine\Valley Benchmark 1.0\data\launcher\js\" -Force


$vedioset0="direct3d11:""DirectX 11"",direct3d9:""DirectX 9"",opengl:""OpenGL"""

if($bitconfig -match "opengl"){
#$videoset="opengl:""OpenGL"", direct3d11:""DirectX 11"",direct3d9:""DirectX 9"""
$videoset="opengl:""OpenGL"""
}
if($bitconfig -match "11"){
#$videoset=$vedioset0
$videoset="direct3d11:""DirectX 11"""
}
if($bitconfig -match "9"){
 #$videoset="direct3d9:""DirectX 9"",direct3d11:""DirectX 11"",opengl:""OpenGL"""
 $videoset="direct3d9:""DirectX 9"""
}


### revise browser js ###

(get-content "C:\Program Files (x86)\Unigine\Valley Benchmark 1.0\data\launcher\js\browser.js").replace($vedioset0, $videoset) `
|set-content "C:\Program Files (x86)\Unigine\Valley Benchmark 1.0\data\launcher\js\browser.js" -Force


### start UI & screenshot ###

## remove cashe##

remove-item -path  "$env:USERPROFILE\AppData\Local\file__0.localstorage"  -Force

start-sleep -s 5

## start UI ##

remove-item $env:HOMEPATH\Valley\log.html -Force

$runcommand="C:\Program Files (x86)\Unigine\Valley Benchmark 1.0\valley.bat"

$id0=(Get-Process cmd).Id
set-location "C:\Program Files (x86)\Unigine\Valley Benchmark 1.0\"

start-process cmd -WindowStyle Maximized
start-sleep -s 3

$id3=(Get-Process cmd).Id|Where-object{$_ -notin $id0}
[Microsoft.VisualBasic.interaction]::AppActivate($id3)|out-null
start-sleep -s 3

### click cmd window and hit enter###
[Clicker]::LeftClickAtPoint(50, 1)
start-sleep -s 3
$wshell.SendKeys("~") 

### send command ## 

Set-Clipboard """$runcommand"""
start-sleep -s 5
[System.Windows.Forms.SendKeys]::SendWait("^v")
start-sleep -s 2
[System.Windows.Forms.SendKeys]::SendWait("~")
start-sleep -s 5

 taskkill /F /PID $id3
  start-sleep -s 2

## screenshot for settings ###
     
&$actionss  -para3 nonlog -para5 "$action-settings"
 
$picfile1=(Get-ChildItem $picpath |Where-object{$_.name -match ".jpg" -and $_.name -match "$action-settings" }).FullName

 ## close settings ###

$checkprocessing2=((get-process -name browser_x86 -ea SilentlyContinue).Id).count 
if( $checkprocessing2 -gt 0){
taskkill /IM browser_x86.exe /F 
 start-sleep -s 5
 }

 

## AutoRun ###

### backup original js ###

copy-item "C:\Program Files (x86)\Unigine\Valley Benchmark 1.0\data\launcher\js\valley-ui-logic.js" -destination "C:\testing_AI\settings\" -Force

$uicontent= get-content "C:\Program Files (x86)\Unigine\Valley Benchmark 1.0\data\launcher\js\valley-ui-logic.js"

### revise autostart js ###

$cmdadd="EngineLauncher.launch(OptionsBuilder.getCommandLine());"

$lineafter="OptionsBuilder.build"

$newcontent= foreach($uiline in $uicontent){
$uiline
if($uiline -match  $lineafter){
$cmdadd
}
}
$newcontent|set-content "C:\Program Files (x86)\Unigine\Valley Benchmark 1.0\data\launcher\js\valley-ui-logic.js" -Force

$runcommand="C:\Program Files (x86)\Unigine\Valley Benchmark 1.0\valley.bat"

do{

$id0=(Get-Process cmd).Id
set-location "C:\Program Files (x86)\Unigine\Valley Benchmark 1.0\"

start-process cmd -WindowStyle Maximized
start-sleep -s 3

$id3=(Get-Process cmd).Id|Where-object{$_ -notin $id0}
[Microsoft.VisualBasic.interaction]::AppActivate($id3)|out-null
start-sleep -s 3

### click cmd window and hit enter###
[Clicker]::LeftClickAtPoint(50, 1)
start-sleep -s 3
$wshell.SendKeys("~") 

### send command ## 

Set-Clipboard """$runcommand"""
start-sleep -s 5
[System.Windows.Forms.SendKeys]::SendWait("^v")
start-sleep -s 2
[System.Windows.Forms.SendKeys]::SendWait("~")
start-sleep -s 10

 taskkill /F /PID $id3

 $valleyid=(get-process -Name Valley -ErrorAction SilentlyContinue).id

 }until($valleyid -ne $null)

#### check if fail to open##


if( (get-process -Name Valley).MainWindowTitle -match "Can't set video mode"){

taskkill /IM Valley.exe /F 
start-sleep -s 2
taskkill /IM browser_x86.exe /F 

$resultNG="NG, Fail to open programs"    
}

else{

start-sleep -s 30
 
 Set-Window -processname "Valley" -x -30 -y 0

<### RUN benchmark ###

[System.Windows.Forms.SendKeys]::SendWait("{F9}")

do{

start-sleep -s 10

$logout=test-path $env:HOMEPATH\Valley\log.html 

$result=Get-Content $env:HOMEPATH\Valley\log.html 

} until($logout -eq $true -and $result -like "*score*")

$newlogname=$picpath+"log_$($timenow).html"
copy-item $env:HOMEPATH\Valley\log.html -Destination  $newlogname -Force
  
start-sleep -s 30
  [KeySends.KeySend]::KeyDown("LWin")
  [KeySends.KeySend]::KeyDown("B")
  [KeySends.KeySend]::KeyUp("LWin")
  [KeySends.KeySend]::KeyUp("B")
  Start-Sleep -s 1
  [KeySends.KeySend]::KeyDown("LWin")
  [KeySends.KeySend]::KeyUp("LWin")
  Start-Sleep -s 1
  [KeySends.KeySend]::KeyDown("LWin")
  [KeySends.KeySend]::KeyUp("LWin")
   Start-Sleep -s 2
   
##### screen shot by Windows ###

$timenow=get-date -format "yyMMdd_HHmmss"
$picfile=$picpath+"$($timenow)-$($tcnumber)-$($tcstep)-$($action)-benchmark.jpg"

$bounds   = [Drawing.Rectangle]::FromLTRB(0, 0, [int64] $width.trim() , [int64] $height.trim() )
$bmp      = New-Object System.Drawing.Bitmap ([int]$bounds.width), ([int]$bounds.height)
$graphics = [Drawing.Graphics]::FromImage($bmp)

$graphics.CopyFromScreen($bounds.Location, [Drawing.Point]::Empty, $bounds.size)
start-sleep -s 2

$bmp.Save($picfile)
start-sleep -s 2

$graphics.Dispose()
$bmp.Dispose()
start-sleep -s 2

$vid=(get-process -Name Valley).id
$wshell.AppActivate($vid) 
start-sleep -s 2
[System.Windows.Forms.SendKeys]::SendWait("{esc}")

<##### screenshot *2 by F12###
$pngfile=(Get-ChildItem -path "$env:USERPROFILE/valley/screenshots").fullname
$id2=(Get-Process -name Valley).Id
$id2title=(Get-Process -name Valley).MainWindowTitle
Get-Process -id $id2 | Set-WindowState -State MAXIMIZE
start-sleep -s 10
$wshell.AppActivate($id2title)
 start-sleep -s 5 
[System.Windows.Forms.SendKeys]::SendWait("{F12}")
$timenow=get-date -format "yyMMdd_HHmmss"
    start-sleep -s 10
$picfile1=$($picpath)+"$($timenow)-$($tcnumber)-$($tcstep)-$($action)-1.jpg"
[System.Windows.Forms.SendKeys]::SendWait("{F12}")
$timenow=get-date -format "yyMMdd_HHmmss"
 start-sleep -s 10
  $picfile2=$($picpath)+"$($timenow)-$($tcnumber)-$($tcstep)-$($action)-2.jpg"    
$pngfile1=((Get-ChildItem -path "$env:USERPROFILE/valley/screenshots")|sort LastWriteTime|select -last 2|select -first 1).fullname
$pngfile2=((Get-ChildItem -path "$env:USERPROFILE/valley/screenshots")|sort LastWriteTime|select -last 1).fullname  
$picfile=""
if( $pngfile -ne 0 -and  $pngfile1 -notin  $pngfile){ copy-item $pngfile1 $picfile1 -Force; $picfile=$picfile1}
if( $pngfile -ne 0 -and  $pngfile2 -notin  $pngfile){ copy-item $pngfile2 $picfile2 -Force; $picfile=$picfile1+"`n"+$picfile2}
##### screenshot *2 by F12###>
   
start-sleep -s 2
  [KeySends.KeySend]::KeyDown("LWin")
  [KeySends.KeySend]::KeyDown("B")
  [KeySends.KeySend]::KeyUp("LWin")
  [KeySends.KeySend]::KeyUp("B")
  Start-Sleep -s 1
  [KeySends.KeySend]::KeyDown("LWin")
  [KeySends.KeySend]::KeyUp("LWin")
  Start-Sleep -s 1
  [KeySends.KeySend]::KeyDown("LWin")
  [KeySends.KeySend]::KeyUp("LWin")
   Start-Sleep -s 2

##### screen shot *2 by Windows ###

&$actionss  -para3 nonlog -para5 "$action_1"

$picfile2=(Get-ChildItem $picpath |Where-object{$_.name -match ".jpg" -and $_.name -match "$action_1" }).FullName

start-sleep -s 7

&$actionss  -para3 nonlog -para5 "$action_2"

$picfile3=(Get-ChildItem $picpath |Where-object{$_.name -match ".jpg" -and $_.name -match "$action_2" }).FullName

$picfile=[string]::join("`n",$picfile1,$picfile2,$picfile3)
  
}

 start-sleep -s 5



}    

if($bitype -match "Unigine_Superposition"){

$action=$bitype
$bitype="Unigine_Superposition"
$actiontype=($action.Replace($bitype,"")).replace("_","")

$bitconfig2=($bitconfig.Split("-"))[1]

if($option2.length -eq 0){
$resx="1920"
$resy="1080"
}
else{
$resx=($option2.split("x"))[0]
$resy=($option2.split("x"))[1]
}

$bipath=(Get-ChildItem "$scriptRoot\BITools\$bitype\" -r -file |Where-object{$_.name -match $bitype -and $_.name -match "exe"}).FullName

$checkprocessing1=((get-process -name "Unigine_Superposition*" -ea SilentlyContinue).Id).count + ((get-process -name launcher -ea SilentlyContinue).Id).count 
if( $checkprocessing1 -gt 0 -or $checkprocessing2 -gt 0){
taskkill /IM Unigine_Superposition-1.1* /F 
  taskkill /IM launcher.exe /F 
 start-sleep -s 20
 }


 <### uninstall ###

$uninstallexe="C:\Program Files\Unigine\Superposition Benchmark\unins*.exe"
if(test-path $uninstallexe){
&$uninstallexe 
start-sleep -s 3
[System.Windows.Forms.SendKeys]::SendWait("Y")
start-sleep -s 10
[System.Windows.Forms.SendKeys]::SendWait("~")
start-sleep -s 3
[System.Windows.Forms.SendKeys]::SendWait("Y")
start-sleep -s 10
[System.Windows.Forms.SendKeys]::SendWait("~")
}
 ###>

## install ##

if( $actiontype -match "install"){
 $checkinstall=test-path "C:\Program Files\Unigine\Superposition Benchmark\bin\launcher.exe"
 $checkinstall2=test-path "C:\Program Files\Unigine\Superposition Benchmark\Superposition.exe"

if(-not($checkinstall -eq $true -and $checkinstall2 -eq $true)){

$id0=(Get-Process cmd).Id
$runcommandin="$bipath /VERYSILENT"
start-process cmd -WindowStyle Maximized
start-sleep -s 2
$id3=(Get-Process cmd).Id|Where-object{$_ -notin $id0}
[Microsoft.VisualBasic.interaction]::AppActivate($id3)|out-null

### click cmd window and hit enter###
[Clicker]::LeftClickAtPoint(50, 1)
start-sleep -s 2
$wshell.SendKeys("~") 

### send command ## 
Set-Clipboard "$runcommandin"
start-sleep -s 5
[System.Windows.Forms.SendKeys]::SendWait("^v")
start-sleep -s 2
[System.Windows.Forms.SendKeys]::SendWait("~")
start-sleep -s 10
 
 taskkill /F /PID $id3


 do{
  start-sleep -s 5
$installcount=((get-process Unigine_Superposition*).id).count
 }until( $installcount -eq 0)

 start-sleep -s 10
}

## check install

 $checkinstall=test-path "C:\Program Files\Unigine\Superposition Benchmark\bin\launcher.exe"
 $checkinstall2=test-path "C:\Program Files\Unigine\Superposition Benchmark\Superposition.exe"
if($checkinstall -eq $true -and $checkinstall2 -eq $true){
$results="OK"
$index="-"   
 }
 else{
$results="NG"
$index="install fail"   
 }

}

#### install end ##

if( $actiontype -match "run"){

$runcommand=".\launcher.exe"

$id0=(Get-Process cmd).Id

set-location -Path "C:\Program Files\Unigine\Superposition Benchmark\bin"
start-process cmd -WindowStyle Maximized
start-sleep -s 2
$id3=(Get-Process cmd).Id|Where-object{$_ -notin $id0}
[Microsoft.VisualBasic.interaction]::AppActivate($id3)|out-null

### click cmd window and hit enter###
[Clicker]::LeftClickAtPoint(50, 1)
start-sleep -s 2
$wshell.SendKeys("~") 

Set-Clipboard "$runcommand"
start-sleep -s 5 
[System.Windows.Forms.SendKeys]::SendWait("^v")
start-sleep -s 2
[System.Windows.Forms.SendKeys]::SendWait("~")
start-sleep -s 10

 taskkill /F /PID $id3

start-sleep -s 2

[Microsoft.VisualBasic.interaction]::AppActivate("Unigine")|out-null
 start-sleep -s 2
[System.Windows.Forms.SendKeys]::SendWait("{tab 2}")
start-sleep -s 2

if( $bitconfig2 -match 1){

[System.Windows.Forms.SendKeys]::SendWait("{UP 10}")  ### selectcustom
start-sleep -s 2
[System.Windows.Forms.SendKeys]::SendWait("{tab}")
start-sleep -s 2
if($bitconfig.length -eq 0 -or $bitconfig -match "DirectX"){
[System.Windows.Forms.SendKeys]::SendWait("{UP}")
}
else{
[System.Windows.Forms.SendKeys]::SendWait("{Down}") ## OpenGL #
}


[System.Windows.Forms.SendKeys]::SendWait("{tab}")  
start-sleep -s 2
[System.Windows.Forms.SendKeys]::SendWait("{UP}")  ### window mode
start-sleep -s 2
[System.Windows.Forms.SendKeys]::SendWait("{tab}")

start-sleep -s 2
[System.Windows.Forms.SendKeys]::SendWait("{UP 10}") 
start-sleep -s 2
 if(  $resx -eq "1920"){
[System.Windows.Forms.SendKeys]::SendWait("{DOWN 6}") ## res setting 1920
}
 if(  $resx -eq "3840"){
[System.Windows.Forms.SendKeys]::SendWait("{DOWN 8}") ## res setting 3840
 }

[System.Windows.Forms.SendKeys]::SendWait("{tab}") 
 
start-sleep -s 2
[System.Windows.Forms.SendKeys]::SendWait("{UP 10}") 
start-sleep -s 2
 if(  $resx -eq "1920"){
[System.Windows.Forms.SendKeys]::SendWait("{DOWN 2}") ## shaders quality of 1920
}
 if(  $resx -eq "3840"){
[System.Windows.Forms.SendKeys]::SendWait("{DOWN 4}") ## shaders quality of 3840
 }

start-sleep -s 2
[System.Windows.Forms.SendKeys]::SendWait("{tab}") 

start-sleep -s 2
[System.Windows.Forms.SendKeys]::SendWait("{DOWN 3}") # texture settings 3840

start-sleep -s 2 
[System.Windows.Forms.SendKeys]::SendWait("{tab 3}") 
start-sleep -s 2 
} ### window mode ##

if( !($bitconfig2 -match 1)){

[System.Windows.Forms.SendKeys]::SendWait("{UP 10}")  ### selectcustom
start-sleep -s 2
  if(  $resx -eq "1920"){
  [System.Windows.Forms.SendKeys]::SendWait("{DOWN 3}") 
  }
  if(  $resx -eq "3840"){
  [System.Windows.Forms.SendKeys]::SendWait("{DOWN 5}") 
  }

start-sleep -s 2
[System.Windows.Forms.SendKeys]::SendWait("{tab}")

if($bitconfig.length -eq 0 -or $bitconfig -match "DirectX"){
[System.Windows.Forms.SendKeys]::SendWait("{UP}")
}
else{
[System.Windows.Forms.SendKeys]::SendWait("{Down}") ## OpenGL #
}

[System.Windows.Forms.SendKeys]::SendWait("{tab}")

&$actionss -para3 nonlog -para5 "settings"

<#
$picfile=$($picpath)+"$($timenow)-$($tcnumber)-$($tcstep)-$($action)-settings.jpg"
[Windows.Forms.SendKeys]::SendWait("{PrtSc}")
Start-Sleep -Seconds 1
$image = [System.Windows.Forms.Clipboard]::GetImage()
$image.Save($picfile)
#>

}

start-sleep -s 2
[System.Windows.Forms.SendKeys]::SendWait(" ")

start-sleep -s 10

if(!(Get-Process superposition)){

&$actionss -para3 nonlog -para5 "warning"

<#
$timenow=get-date -format "yyMMdd_HHmmss" 
$picfile=$($picpath)+"$($timenow)_$($tcnumber)_$($tcstep)_$($action)_warning.jpg"
[Windows.Forms.SendKeys]::SendWait("{PrtSc}")
Start-Sleep -Seconds 1
$image = [System.Windows.Forms.Clipboard]::GetImage()
$image.Save($picfile)
#>

start-sleep -s 2
[System.Windows.Forms.SendKeys]::SendWait("{tab}")
start-sleep -s 1
[System.Windows.Forms.SendKeys]::SendWait("{tab}")
start-sleep -s 2
[System.Windows.Forms.SendKeys]::SendWait(" ")

}


start-sleep -s 30

Set-Window -ProcessName "superposition"  -X -30 -Y 0 
 
 start-sleep -s 2

### screenshot *2 ###

if( !($bitconfig2 -match 2)){ 


&$actionss -para3 nonlog -para5 "run1"

<#
$timenow=get-date -format "yyMMdd_HHmmss"
$picfile1=$($picpath)+"$($timenow)_$($tcnumber)_$($tcstep)_$($action)_run1.jpg"
[Windows.Forms.SendKeys]::SendWait("{PrtSc}")
Start-Sleep -Seconds 1
$image = [System.Windows.Forms.Clipboard]::GetImage()
$image.Save($picfile1)
#>

start-sleep -s 30
  
&$actionss -para3 nonlog -para5 "run2"

<#
$timenow=get-date -format "yyMMdd_HHmmss"
$picfile2=$($picpath)+"$($timenow)_$($tcnumber)_$($tcstep)_$($action)_run2.jpg"
 [Windows.Forms.SendKeys]::SendWait("{PrtSc}")
Start-Sleep -Seconds 1
$image = [System.Windows.Forms.Clipboard]::GetImage()
$image.Save($picfile2)
#>

}

## wait Benchmark finish ##

#(Get-Process "superposition").WaitForExit()
try{
Wait-Process "superposition" -Timeout 600
}catch{

write-host "error to complete bench running"

&$actionss -para3 nonlog -para5 "error"

<#
$timenow=get-date -format "yyMMdd_HHmmss"
$picfile5=$($picpath)+"$($timenow)_$($tcnumber)_$($tcstep)_$($action)_error.jpg"
[Windows.Forms.SendKeys]::SendWait("{PrtSc}")
Start-Sleep -Seconds 1
$image = [System.Windows.Forms.Clipboard]::GetImage()
$image.Save($picfile5)
#>

[Microsoft.VisualBasic.interaction]::AppActivate("Unigine")|out-null
start-sleep -s 2
[System.Windows.Forms.SendKeys]::SendWait(" ")

Stop-Process -Name superposition

}

### only fullscreen save score ; winodw mode no saving #

if( !($bitconfig2 -match 1)){ 


$timenowa=get-date

start-sleep -s 5 
[Microsoft.VisualBasic.interaction]::AppActivate("Unigine")|out-null
 start-sleep -s 2
[System.Windows.Forms.SendKeys]::SendWait("{tab 4}")
 start-sleep -s 2
start-sleep -s 2
[System.Windows.Forms.SendKeys]::SendWait(" ")
start-sleep -s 2
[System.Windows.Forms.SendKeys]::SendWait("~")
start-sleep -s 5
[System.Windows.Forms.SendKeys]::SendWait("{tab}")
start-sleep -s 2
[System.Windows.Forms.SendKeys]::SendWait(" ")


##### copy screenshot and log ###


do{
start-sleep -s 1
$checksave=Get-ChildItem -path "$env:USERPROFILE/Superposition/screenshots\*" |Where-object{$_.lastwritetime -gt $timenowa}
$timegap=(New-TimeSpan -start $timenowa -End (Get-Date)).TotalSeconds
}until($checksave -or $timegap -gt 30)

if($checksave){

$timenow=get-date -format "yyMMdd_HHmmss"
$picfile1=$($picpath)+"$($timenow)-$($tcnumber)-$($tcstep)-$($action)-score.jpg"
$scfile1=$checksave.FullName

#$resultfile=((Get-ChildItem -path "$env:USERPROFILE/Superposition/results")|sort LastWriteTime|select -last 1).fullname

Copy-Item  $scfile1 -Destination $picfile1 -Force

 #copy-item $resultfile $picpath -Force
 }
 else{
    write-host "fail to get save pic"
 }

&$actionss -para3 nonlog -para5 "score_fullscreen"

start-sleep -s 5
  
}


start-sleep -s 2
[Microsoft.VisualBasic.interaction]::AppActivate("Unigine")|out-null
start-sleep -s 1
[System.Windows.Forms.SendKeys]::SendWait("%{F4}")

$picfile="check screen shots"
 }



 }

if($bitype -match "3dmark"){

$action="3DMark install"

#$OSVersion = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\').CurrentBuildNumber

$bitype="3DMark"
#if($OSVersion -ge 22000){$bitype="3DMark_win11"}
if($bitconfig -eq "v2adv"){$bitype="cloudegate"}

## copy unzip ##
  
function netdisk_connect([string]$webpath,[string]$username,[string]$passwd,[string]$diskid){

net use $webpath /delete
net use $webpath /user:$username $passwd /PERSISTENT:yes
net use $webpath /SAVECRED 

if($diskid.length -ne 0){
$diskpath=$diskid+":"
$checkdisk=net use
 if($checkdisk -match $diskpath){net use $diskpath /delete}
  net use $diskpath $webpath
}

}

netdisk_connect -webpath \\192.168.2.249\srvprj\Inventec\Dell -username pctest -passwd pctest -diskid Y

$copytopath="C:\testing_AI\modules\BITools\$($bitype)"
$autopath="Y:\Matagorda\07.Tool\_AutoTool"
$zipfile="Y:\Matagorda\07.Tool\_AutoTool\extra_tools\$($bitype).zip"

$failcopy=""
if(!(test-path $copytopath)){
   Expand-Archive $zipfile -DestinationPath $copytopath

<##
 new-item -ItemType directory $copytopath |Out-Null
 start-sleep -s 5
 $zipfile="$autopath\extra_tools\$($bitype).zip"
 $copytopath="C:\testing_AI\modules\BITools\$($bitype)"
  write-host "unzip $zipfile to $copytopath"
  if( (test-path $copytopath) -and (test-path $zipfile) ){
  try{$shell.NameSpace($copytopath).copyhere($shell.NameSpace($zipfile).Items(),16)}
  catch{
  $failcopy="fail to copy 3DMARK tool"
  $picfile=$failcopy
  }
  }
  #>

  }
  
do{
Start-Sleep -s 5
$checktool=test-path $copytopath
$bipath=(Get-ChildItem "$scriptRoot\BITools\$($bitype)\" -r -file |Where-object{$_.name -match "exe"}).FullName
}until($checktool -and $bipath.Length -gt 0)

##>

if((test-path $env:USERPROFILE\Documents\3DMark\3DMark.log) -or (test-path "C:\Program Files\UL\3DMark\3DMark.exe")){
$getlogs=get-content -path $env:USERPROFILE\Documents\3DMark\3DMark.log
foreach($getlog in $getlogs){
if($getlog -match "Starting 3DMark" ){
$getlog -match "v\d{1,}\.\d{1,}\.\d{1,}"
$3dmarkversion=$matches[0]
$3dmarkversion
}
}

<###
$3dmarkversion= (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*\*" | Where-Object {$_.DisplayName -like "3DMark*"} | Select-Object DisplayName, DisplayVersion).DisplayVersion
if($3dmarkversion.length -eq 0){
$3dmarkversion= (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*" | Where-Object {$_.DisplayName -like "3DMark*"} | Select-Object DisplayName, DisplayVersion).DisplayVersion
}
###>

#$unstallflag="need"
#if($3dmarkversion -eq $null -or ($bitconfig -eq "v2adv" -and $3dmarkversion -eq "v2.10.6762")){$unstallflag="noneed"}
#if($3dmarkversion -eq $null -or ($bitconfig -ne "v2adv" -and $3dmarkversion -ne "v2.10.6762")){$unstallflag="noneed"}

#if($unstallflag -eq "need"){

## uninstall anywey
<#
if($3dmarkversion -eq "v2.10.6762"){$uninstallf ="cloudgate"}
else{$uninstallf = "3dmark"}
set-location "$scriptRoot\BITools\$uninstallf\"
.\3dmark-setup.exe /uninstall /silent
#>

$3dmarkexe=Get-Item "C:\ProgramData\Package Cache\*\3DMARK-setup.exe"|Sort-Object lastwritetime|Select-Object -Last 1
if($3dmarkexe.count -ne 0){
$3dmarkexefull=($3dmarkexe).fullname
$3dmarkexeversion=($3dmarkexe.VersionInfo).ProductVersion
write-host "uninstall 3DMARK version $3dmarkexeversion from $3dmarkexefull"
&$3dmarkexefull  /uninstall /silent
}

do{
start-sleep -s 5
$checkul=(get-process -Name "3DMarkCmd" -ea SilentlyContinue).Id
$checkul2=(get-process -Name "3dmark-setup" -ea SilentlyContinue).Id
#$checkul
#$checkul2
}until($checkul -eq  $null -and $checkul2 -eq  $null)

## close all app windows 

Get-Process |   Where-Object { $_.MainWindowHandle -ne 0  } |
ForEach-Object { 
$handle = $_.MainWindowHandle

# minimize window
$null = [MyNamespace.MyType]::ShowWindowAsync($handle, 2)
}

&$actionss  -para3 nonlog -para5 "3DMark_uninstall"
$picfile=$picfile+@((Get-ChildItem $picpath |Where-object{$_.name -match ".jpg" -and $_.name -match "3DMark_uninstall" }).FullName)

}
##>
#}

start-sleep -s 5
$checkins=test-path "C:\Program Files\UL\3DMark\3DMark.exe"

if($checkins -ne $true){
## install
set-location "$scriptRoot\BITools\$bitype\"
.\3dmark-setup.exe /install /silent

do{
start-sleep -s 5
$checkul=(get-process -Name "3DMarkCmd" -ea SilentlyContinue).Id
$checkul2=(get-process -Name "3dmark-setup" -ea SilentlyContinue).Id
$checkins=test-path "C:\Program Files\UL\3DMark\3DMark.exe"
#$checkul
#$checkul2
}until($checkul -eq  $null -and $checkul2 -eq  $null -and $checkins -eq $true)

start-sleep -s 30

}

if ($bitconfig -eq "pro"){ New-ItemProperty -Path HKCU:Software\UL\3DMark -Name KeyCode -Type String -Value 3DM-PICF-2RQCM-6TKWV-Z3HA4-HE7Z3 -Force }  ## Professional 
elseif ($bitconfig -eq "v2adv"){ New-ItemProperty -Path HKCU:Software\UL\3DMark -Name KeyCode -Type String -Value 3DM-ICF-2RQCM-6TKWV-Z3HAJ-MKML4 -Force }  ## 3DMark-v2-10-6762 Advanced
else{New-ItemProperty -Path HKCU:Software\UL\3DMark -Name KeyCode -Type String -Value 3DM-ICFTP-32P4E-JKXCZ-WUC2H-2VRCE -Force } ## Advanced

remove-item "$env:userprofile\Documents\3DMark\*.3dmark-result" -Force -ErrorAction SilentlyContinue
#remove-item "$env:userprofile\Documents\3DMark\3DMark.log" -Force -ErrorAction SilentlyContinue
remove-item "$env:userprofile\Documents\3DMark\*.xml" -Force -ErrorAction SilentlyContinue
remove-item "$env:userprofile\Documents\*.xml" -Force -ErrorAction SilentlyContinue

start-sleep -s 5

if($option2.length -gt 0){ 
set-location "C:\Program Files\UL\3DMark\"
.\3DMark.exe

## check opening and wait open complete and close###
do{
start-sleep -s 10
$checkopen3d1=(get-process -name EasyFMSI).Id
start-sleep -s 10
 $checkopen3d2=(get-process -name EasyFMSI).Id

}until($checkopen3d1 -eq $null -and $checkopen3d2 -eq $null)

start-sleep -s 60

(get-process -name  "3DMark").CloseMainWindow()

start-sleep -s 5

if($option2 -match "option1"){
$optioncontent=get-content "$env:USERPROFILE\AppData\Local\UL\3DMark\app-settings.json"
(($optioncontent.replace("""VALIDATE_RESULT_ONLINE"":true","""VALIDATE_RESULT_ONLINE"":false")).replace("""HIDE_RESULT_ONLINE"":true","""HIDE_RESULT_ONLINE"":false")).replace("""ENABLE_AUDIO"":false","""ENABLE_AUDIO"":true")|Set-Content "$env:USERPROFILE\AppData\Local\UL\3DMark\app-settings.json"
 }

 
if($option2 -match "option2"){
$optioncontent=get-content "$env:USERPROFILE\AppData\Local\UL\3DMark\app-settings.json"
(($optioncontent.replace("""VALIDATE_RESULT_ONLINE"":true","""VALIDATE_RESULT_ONLINE"":false")).replace("""HIDE_RESULT_ONLINE"":false","""HIDE_RESULT_ONLINE"":true")).replace("""ENABLE_AUDIO"":true","""ENABLE_AUDIO"":false") |Set-Content "$env:USERPROFILE\AppData\Local\UL\3DMark\app-settings.json"

 }

}

## close all app windows 

Get-Process |   Where-Object { $_.MainWindowHandle -ne 0  } |
ForEach-Object { 
$handle = $_.MainWindowHandle

# minimize window
$null = [MyNamespace.MyType]::ShowWindowAsync($handle, 2)
}

## screenshot of desktop

&$actionss  -para3 nonlog -para5 "installcheck"
$picfile=$picfile+@((Get-ChildItem $picpath |Where-object{$_.name -match ".jpg" -and $_.name -match "installcheck" }).FullName)
$picfile=$picfile|Out-String

}

if($bitype -match "pcmark8"){

$action="PCMark8 install and run"

$bitype="PCMark8"

if($bitconfig.length -eq 0){
$diskid="C"
}
elseif($bitconfig -match "storage\-"){
$diskid=($bitconfig.split("-"))[1]
}
else{
$resultNG="NG"
$index="no define running storage Letter"
$noexit_flag="noexit"
}

#check id disk exist #

#$currentdisks= (get-psdrive -psprovider filesystem).name

$currentdisks= ((Get-WmiObject -Class Win32_LogicalDisk |Where-Object{$_.providername -notlike "\\*"}).name).replace(":","")
$currentdiskstring=$currentdisks|Out-String
write-host "current all disks:$currentdiskstring"

if($diskid -and $diskid -in $currentdisks){

write-host "Drive $diskid exists, start to run PCMARK8"

$copytopath="C:\testing_AI\modules\BITools\$($bitype)"


if(!(test-path $copytopath)){

## copy unzip ##
  
function netdisk_connect([string]$webpath,[string]$username,[string]$passwd,[string]$disklet){

net use $webpath /delete
net use $webpath /user:$username $passwd /PERSISTENT:yes
net use $webpath /SAVECRED 

if($disklet -ne 0){
$diskpath=$disklet+":"
$checkdisk=net use
 if($checkdisk -match $diskpath){net use $diskpath /delete}
  net use $diskpath $webpath
}

}

$autopath="Y:\Matagorda\07.Tool\_AutoTool"
$zipfile="Y:\Matagorda\07.Tool\_AutoTool\extra_tools\$($bitype).zip"

netdisk_connect -webpath \\192.168.2.249\srvprj\Inventec\Dell -username pctest -passwd pctest -diskid Y
Expand-Archive $zipfile -DestinationPath $copytopath

do{
Start-Sleep -s 5
$checktool=test-path $copytopath
$bipath=(Get-ChildItem "$scriptRoot\BITools\$($bitype)\" -r -file |Where-object{$_.name -match "PCMark8-setup.exe"}).FullName
}until($checktool -and $bipath.Length -gt 0)

  }
  

start-sleep -s 5
$checkins=test-path "C:\Program Files\Futuremark\PCMark 8\bin\PCMark8.exe"

if($checkins -ne $true){
## install
$starttime=$(Get-Date)
write-host "start install PCMARK8 $(Get-Date)"
set-location "$scriptRoot\BITools\$bitype\"
.\pcmark8-setup.exe /install /silent

do{
start-sleep -s 5
$checkul2=(get-process -Name "PCMARK8-setup" -ea SilentlyContinue).Id
$checkins=test-path "C:\Program Files\Futuremark\PCMark 8\bin\PCMark8.exe"
}until($checkul2 -eq  $null -and $checkins -eq $true)

start-sleep -s 30
$timetake=[math]::Round((New-TimeSpan -start $starttime -end (get-date) ).TotalMinutes, 1)

write-host "Done the install of PCMARK8 $(Get-Date), total spent $($timetake) minutes"
}

start-sleep -s 5

## close all app windows 

Get-Process |   Where-Object { $_.MainWindowHandle -ne 0  } |
ForEach-Object { 
$handle = $_.MainWindowHandle

# minimize window
$null = [MyNamespace.MyType]::ShowWindowAsync($handle, 2)
}

## screenshot of desktop

Start-Process "C:\Program Files\Futuremark\PCMark 8\bin\pcmark8.exe" -WindowStyle Maximized
Start-Sleep -s 60

stop-process -name PCMark8 -Force
Start-Sleep -s 2
New-ItemProperty -Path HKCU:Software\Futuremark\PCMark8 -Name KeyCode -Type String -Value PCM8-PRO-244FK-XLEW5-KSLT7-Y9HLA -Force
Start-Sleep -s 2
start-process "C:\Program Files\Futuremark\PCMark 8\bin\pcmark8.exe" -WindowStyle Maximized
Start-Sleep -s 60
&$actionss  -para3 nonlog -para5 "PCMARK8_Install_Check"

$Handle = Get-Process pcmark8| Where-Object { $_.MainWindowTitle -match $env:TITLE } | ForEach-Object { $_.MainWindowHandle }
if ( $Handle -is [System.Array] ) { $Handle = $Handle[0] }
$WindowRect = New-Object RECT
$GotWindowRect = [Window]::GetWindowRect($Handle, [ref]$WindowRect)
#Write-Host $WindowRect.Left $WindowRect.Top $WindowRect.Right $WindowRect.Bottom

##scale
$bdh=(([System.Windows.Forms.Screen]::AllScreens|Select-Object Bounds).Bounds).Bottom 
$height  = ([string]::Join("`n", (wmic path Win32_VideoController get CurrentVerticalResolution))).split("`n") -match "\d{1,}"
#$sacle=$height[0]/$bdh[0]
$sacle=1 ## for command use, no need to divided with scale ( don't know the reason yet)

$x1=[math]::Round(($WindowRect.Left + $WindowRect.Right)/2/$sacle,0)
$y1=[math]::Round(($WindowRect.Top + $WindowRect.Bottom)/2/$sacle,0)
start-sleep -s 5
[Clicker]::LeftClickAtPoint($x1, $y1)
start-sleep -s 5

[System.Windows.Forms.SendKeys]::SendWait("{tab}")
start-sleep -s 2
[System.Windows.Forms.SendKeys]::SendWait("{tab}")

start-sleep -s 2
[System.Windows.Forms.SendKeys]::SendWait("{tab}")

[System.Windows.Forms.SendKeys]::SendWait("{tab}")

[System.Windows.Forms.SendKeys]::SendWait("{RIGHT}")

[System.Windows.Forms.SendKeys]::SendWait("{RIGHT}")
start-sleep -s 2
[System.Windows.Forms.SendKeys]::SendWait("~")
start-sleep -s 2
[System.Windows.Forms.SendKeys]::SendWait("{tab}")
start-sleep -s 2
[System.Windows.Forms.SendKeys]::SendWait("{tab}")
start-sleep -s 2
[System.Windows.Forms.SendKeys]::SendWait("{tab}")
start-sleep -s 2
[System.Windows.Forms.SendKeys]::SendWait("{tab}")
start-sleep -s 2
[System.Windows.Forms.SendKeys]::SendWait("$diskid")
start-sleep -s 2

[System.Windows.Forms.SendKeys]::SendWait("{tab}")
start-sleep -s 1
[System.Windows.Forms.SendKeys]::SendWait("{tab}")
start-sleep -s 1
[System.Windows.Forms.SendKeys]::SendWait("{tab}")

&$actionss  -para3 nonlog -para5 "PCMARK8_start_run"

[System.Windows.Forms.SendKeys]::SendWait(" ")
start-sleep -s 80

&$actionss  -para3 nonlog -para5 "PCMARK8_running"



}

else{

write-host "Drive $diskid doesnot exist, quit running, go to next step"

$resultNG="NG"
$index="no disk $diskid exist"
$noexit_flag="noexit"
}


}

#region_ending ##
$results="OK"
$Index=$picfile
if($Index.Length -eq 0){
$Index="check screenshots and logs"
}

if($resultNG -ne $null){$results=$resultNG}

######### write log #######

Get-Module -name "outlog"|remove-module
$mdpath=(Get-ChildItem -path "C:\testing_AI\modules\"  -r -file |Where-object{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

#write-host "Do $action!"
outlog $action $results $tcnumber $tcstep $index

start-sleep -s 10

if($noexit_flag.length -eq 0){
exit
}
#endregion

}

  export-modulemember -Function  benchmark