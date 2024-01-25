function mouse_action ([int]$para1,[string]$para2,[string]$para3,[string]$para4,[int]$para5){

    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force;
    $wshell=New-Object -ComObject wscript.shell
      Add-Type -AssemblyName Microsoft.VisualBasic
      Add-Type -AssemblyName System.Windows.Forms
      Add-Type -AssemblyName System.Windows.Forms,System.Drawing
    #import mouse_event
    Add-Type -MemberDefinition '[DllImport("user32.dll")] public static extern void mouse_event(int flags, int dx, int dy, int cButtons, int info);' -Name U32 -Namespace W;
   # 6 is 0x02 | 0x04, LMBDown | LMBUp from the documentation
   ## https://msdn.microsoft.com/en-us/library/windows/desktop/ms646260(v=vs.85).aspx
      
if($PSScriptRoot.length -eq 0){
$scriptRoot="C:\testing_AI\modules"
}
else{
$scriptRoot=$PSScriptRoot
}

$tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
$tcnumber=((get-content $tcpath).split(","))[0]
$tcstep=((get-content $tcpath).split(","))[1]

$picpath=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\"
if(-not(test-path $picpath)){new-item -ItemType directory -path $picpath |out-null}

$actionmd ="screenshot"
Get-Module -name $actionmd|remove-module
$mdpath=(Get-ChildItem -path $scriptRoot -r -file |Where-object{$_.name -match "^$actionmd\b" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

$screen = [System.Windows.Forms.Screen]::PrimaryScreen
$bounds = $screen.Bounds
$width  = $bounds.Width
$height = $bounds.Height

$coorlog=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\coor.txt"

#$width  = (([string]::Join("`n", (wmic path Win32_VideoController get CurrentHorizontalResolution))).split("`n") -match "\d{1,}")[0]
#$height  = (([string]::Join("`n", (wmic path Win32_VideoController get CurrentVerticalResolution))).split("`n") -match "\d{1,}")[0]

$paracheck1=$PSBoundParameters.ContainsKey('para1')
$paracheck2=$PSBoundParameters.ContainsKey('para2')
$paracheck3=$PSBoundParameters.ContainsKey('para3')
$paracheck4=$PSBoundParameters.ContainsKey('para4')
$paracheck5=$PSBoundParameters.ContainsKey('para5')

if($paracheck1 -eq $false -or $para1 -eq 0){
$para1=0
}
if($paracheck2 -eq $false -or $para2.length -eq 0){
$para2= [int64]([System.Windows.Forms.Cursor]::Position.X)
}
if($para2 -match "bylog"){
$para2=[int64](((get-content $coorlog) -split ",")[0])
}

if($para2 -match "\%"){
$para2=([int64]($para2.Replace("%",""))/100)*$width
}

if($paracheck3 -eq $false -or $para3.length -eq 0){
$para3=[int64]([System.Windows.Forms.Cursor]::Position.Y)
}
if($para3 -match "bylog"){
$para3=[int64](((get-content $coorlog) -split ",")[1])
}

if($para3 -match "\%"){
$para3=([int64]($para3.Replace("%",""))/100)*$height
}

if($paracheck4 -eq $false -or $para4.length -eq 0){
$para4=""
}
if($paracheck5 -eq $false -or $para5 -eq 0){
$para5=[int64]2
}

$clicktime=$para1
$dx=[int64]$para2
$dy=[int64]$para3
$exitflag=$para4
$waittime=$para5


$cSource3 = @'
using System;
using System.Drawing;
using System.Runtime.InteropServices;
using System.Windows.Forms;
public class Clicker3
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
Add-Type -TypeDefinition $cSource3 -ReferencedAssemblies System.Windows.Forms,System.Drawing

$cSource2 = @'
using System;
using System.Drawing;
using System.Runtime.InteropServices;
using System.Windows.Forms;
public class Clicker2
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


public static void Moving(int x, int y)
{
    //Move the mouse
    INPUT[] input = new INPUT[3];
    input[0].mi.dx = x*(65535/System.Windows.Forms.Screen.PrimaryScreen.Bounds.Width);
    input[0].mi.dy = y*(65535/System.Windows.Forms.Screen.PrimaryScreen.Bounds.Height);
    input[0].mi.dwFlags = MOUSEEVENTF_MOVED | MOUSEEVENTF_ABSOLUTE;
    SendInput(3, input, Marshal.SizeOf(input[0]));

}


}
'@
Add-Type -TypeDefinition $cSource2 -ReferencedAssemblies System.Windows.Forms,System.Drawing

# [Clicker3]::LeftClickAtPoint(0, 0)  ## click
# [Clicker2]::Moving(0, 0)  ## moving

if($clicktime -eq 0){ $action="mouse moving to $dx，$dy "}
if($clicktime -gt 0) { $action="mouse click $clicktime times at $dx，$dy"}
if($clicktime -eq -1) { $action="mouse left down at $dx，$dy"}
if($clicktime -eq -2) { $action="mouse left up at $dx，$dy"}

## before mouse action screen shot ##

&$actionmd  -para3 nonlog -para5 "mouseaction_before"

## mouse action ##

Start-Sleep -s 5

if($clicktime -eq 0){
[Clicker2]::Moving($dx, $dy)
$errorcodeis=$LASTEXITCODE
}

if($clicktime -gt 0){

do{
[Clicker3]::LeftClickAtPoint($dx, $dy)
#$errorcodeis=$LASTEXITCODE
$clicktime=$clicktime-1
}until($clicktime -eq 0)
}

if($clicktime -eq -1){
#left mouse down
[W.U32]::mouse_event(2,0,0,0,0);
#$errorcodeis=$LASTEXITCODE
}

if($clicktime -eq -2){
#left mouse down
[W.U32]::mouse_event(4,0,0,0,0);
#$errorcodeis=$LASTEXITCODE
}

$errorcodeis=$?
Write-Output "mouse click errorcode is $errorcodeis"
start-sleep -s $waittime

## after mouse action screen shot ##

&$actionmd  -para3 nonlog -para5 "mouseaction_after"

######### write log #######

if($errorcodeis -eq 1){$results="OK"}
else{$results="NG"}

#Write-Host "errorcode is $errorcodeis, $action, $results"

$index="check screenshots"

Get-Module -name "outlog"|remove-module
$mdpath=(Get-ChildItem -path "C:\testing_AI\modules\"  -r -file |Where-object{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

#write-host "Do $action!"
outlog $action $results $tcnumber $tcstep $index

if($exitflag.length -gt 0){
exit
}

  }

    export-modulemember -Function mouse_action


   
