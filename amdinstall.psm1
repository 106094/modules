
function amdinstall([string]$para1,[string]$para2){
    
    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force;
    $wshell=New-Object -ComObject wscript.shell
      Add-Type -AssemblyName Microsoft.VisualBasic
      Add-Type -AssemblyName System.Windows.Forms
      
#region functions

Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

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
#endregion 
      
$installername=$para1
$nonlog_flag=$para2

if($PSScriptRoot.length -eq 0){
$scriptRoot="C:\testing_AI\modules"
}
else{
$scriptRoot=$PSScriptRoot
}

$actionss ="screenshot"
Get-Module -name $actionss|remove-module
$mdpath=(Get-ChildItem -path $scriptRoot -r -file |?{$_.name -match "^$actionss\b" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global
  

$action="AMDdInstall"

$tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
$tcnumber=((get-content $tcpath).split(","))[0]
$tcstep=((get-content $tcpath).split(","))[1]

$picpath=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\"
if(-not(test-path $picpath)){new-item -ItemType directory -path $picpath |out-null}

$installfile=(Get-ChildItem $picpath  -Recurse -filter "*amd-software*").FullName
$installfile2=(Get-ChildItem $picpath  -Recurse -filter "*amd-software*").basename
if($installername.Length -ne 0){
$installfile=(Get-ChildItem $picpath -Recurse |?{$_.name -match "$installername"} ).FullName
$installfile2=(Get-ChildItem $picpath -Recurse |?{$_.name -match "$installername"}).basename
}

&$installfile 

do{
start-sleep -s 1
$installerid=(get-process -name "$installfile2").Id
$windowTitle=(get-process -name "$installfile2").mainwindowtitle
}until ($installerid -and $windowTitle)


$windowHandle = (get-process -name "$installfile2").MainWindowHandle
$windowRect = New-Object RECT

 [Win32]::GetWindowRect($windowHandle, [ref]$windowRect)

    $left = $windowRect.Left
    $top = $windowRect.Top


[Microsoft.VisualBasic.interaction]::AppActivate($installerid)|out-null
  Start-Sleep -s 2
[Clicker]::LeftClickAtPoint($left+50,$top+50)
  Start-Sleep -s 2
  
   [System.Windows.Forms.SendKeys]::SendWait("{tab}")
   [System.Windows.Forms.SendKeys]::SendWait("{tab}")  

   &$actionss -para3 nonlog -para5 "install_setup"

   [System.Windows.Forms.SendKeys]::SendWait("~")

   do{
     start-sleep -s 5
    $installer=get-process -name AMDSoftwareInstaller -ErrorAction SilentlyContinue
    $installer0=get-process -name $installfile2 -ErrorAction SilentlyContinue
   }until($installer -and !($installer0))
 
   start-sleep -s 10 
    &$actionss -para3 nonlog -para5 "AMDSoftwareInstaller_starting"

    ## pcai ##
    
$funcpcai="pcai"
Get-Module -name $funcpcai|remove-module
$mdpath=(Get-ChildItem -path $scriptRoot -r -file |?{$_.name -match "^$funcpcai\b" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

&$funcpcai -para1 AMDInstall -para4 nc -para5 nolog


######### write log #######

if($nonlog_flag.Length -eq 0 -or $timespanmin -gt 30){
Get-Module -name "outlog"|remove-module
$mdpath=(Get-ChildItem -path "C:\testing_AI\modules\"  -r -file |?{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

#write-host "Do $action!"
outlog $action $results $tcnumber $tcstep $index
}
  }

    export-modulemember -Function amdinstall