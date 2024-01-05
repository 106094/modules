
function edge_update {
 
  Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force;
    $wshell=New-Object -ComObject wscript.shell
      Add-Type -AssemblyName Microsoft.VisualBasic
      Add-Type -AssemblyName System.Windows.Forms
      
      $ping = New-Object System.Net.NetworkInformation.Ping

if($PSScriptRoot.length -eq 0){
$scriptRoot="C:\testing_AI\modules"
}
else{
$scriptRoot=$PSScriptRoot
}

$tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
$tcnumber=((get-content $tcpath).split(","))[0]
$tcstep=((get-content $tcpath).split(","))[1]
$action=((get-content $tcpath).split(","))[2]

 #$testconnect=($ping.Send("www.google.com", 1000)).Status

 $testconnect= Invoke-WebRequest -Uri "www.msn.com" -UseBasicParsing 

 #!($testconnect -match "Success")
   if( !($testconnect)){
       $results="-"
       $index="not connect to internet, no update"

       }

else{
#region if connectting to internet

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


### edge initialization -  open and close ####

Start-Process msedge.exe
start-sleep -s 10

 (get-process -name msedge).CloseMainWindow()
 start-sleep -s 5

Start-Process msedge.exe
start-sleep -s 10

 (get-process -name msedge).CloseMainWindow()
  start-sleep -s 5
 if( ((Get-Process msedge).id).count -gt 0){Stop-Process -name msedge -ErrorAction SilentlyContinue -Force}
 start-sleep -s 5


### start to setting##
function openedge{
Start-Process msedge.exe 
 start-sleep -s 20
 $id=(Get-Process msedge |?{($_.MainWindowTitle).length -gt 0}).Id
  start-sleep -s 2
  Get-Process -id $id | Set-WindowState -State MAXIMIZE

[Microsoft.VisualBasic.interaction]::AppActivate($id)|out-null
 start-sleep -s 2
[System.Windows.Forms.SendKeys]::SendWait("{esc}")
 start-sleep -s 2
[System.Windows.Forms.SendKeys]::SendWait("{esc}")
  start-sleep -s 2
  
   Set-Clipboard -Value "edge://settings/help"
   start-sleep -s 5

[System.Windows.Forms.SendKeys]::SendWait("^l")
  start-sleep -s 2
[System.Windows.Forms.SendKeys]::SendWait("^v")
  start-sleep -s 2
[System.Windows.Forms.SendKeys]::SendWait("~")
  start-sleep -s 5
  ## backup
  

[System.Windows.Forms.SendKeys]::SendWait("^l")
  start-sleep -s 2
[System.Windows.Forms.SendKeys]::SendWait("^a")
  start-sleep -s 2
[System.Windows.Forms.SendKeys]::SendWait("^c")
  start-sleep -s 2
  $webadd=Get-Clipboard
   start-sleep -s 2

  if(!($webadd -like "edge://settings/help")){
   do{
 [Clicker]::LeftClickAtPoint(100,100)
  start-sleep -s 2
  [System.Windows.Forms.SendKeys]::SendWait("%e")
  start-sleep -s 2
[System.Windows.Forms.SendKeys]::SendWait("b")
  start-sleep -s 2
[System.Windows.Forms.SendKeys]::SendWait("m")
  start-sleep -s 5
  [System.Windows.Forms.SendKeys]::SendWait("^l")
  start-sleep -s 2
[System.Windows.Forms.SendKeys]::SendWait("^a")
  start-sleep -s 2
[System.Windows.Forms.SendKeys]::SendWait("^c")
  start-sleep -s 2
  $webadd2=Get-Clipboard
   start-sleep -s 2
   }until($webadd2 -like "edge://settings/help")
  }

  }
    
  openedge

  $reconnect_time=0

  do{   

    $id=(Get-Process msedge |?{($_.MainWindowTitle).length -gt 0}).Id
    if(!$id){openedge}
     $id=(Get-Process msedge |?{($_.MainWindowTitle).length -gt 0}).Id
   [Microsoft.VisualBasic.interaction]::AppActivate($id)|out-null
   start-sleep -s 2

   Set-Clipboard -Value "about"
   start-sleep -s 5
    
  [System.Windows.Forms.SendKeys]::SendWait("^f")
  start-sleep -s 2
[System.Windows.Forms.SendKeys]::SendWait("^v")
  start-sleep -s 2
[System.Windows.Forms.SendKeys]::SendWait("~")
  start-sleep -s 2
[System.Windows.Forms.SendKeys]::SendWait("{esc}")

 start-sleep -s 2
[System.Windows.Forms.SendKeys]::SendWait("^a")
  start-sleep -s 2
[System.Windows.Forms.SendKeys]::SendWait("^c")
  start-sleep -s 5
[System.Windows.Forms.SendKeys]::SendWait("{esc}")

$content=Get-Clipboard
  start-sleep -s 5
 # $content

 if($content -like "* then refresh the page*"){
 [System.Windows.Forms.SendKeys]::SendWait("{F5}")
   start-sleep -s 30
 }

 if($content -like "*Unable to connect to the Internet*"){
 ipconfig /renew
  start-sleep -s 10
  $reconnect_time++  

[System.Windows.Forms.SendKeys]::SendWait("{f5}")
 
   Set-Clipboard -Value "about"
   start-sleep -s 5
    
[Microsoft.VisualBasic.interaction]::AppActivate($id)|out-null
   start-sleep -s 2
[System.Windows.Forms.SendKeys]::SendWait("^f")
  start-sleep -s 2
[System.Windows.Forms.SendKeys]::SendWait("^v")
  start-sleep -s 2
[System.Windows.Forms.SendKeys]::SendWait("~")
  start-sleep -s 2
[System.Windows.Forms.SendKeys]::SendWait("{esc}")

 start-sleep -s 2
[System.Windows.Forms.SendKeys]::SendWait("^a")
  start-sleep -s 2
[System.Windows.Forms.SendKeys]::SendWait("^c")
  start-sleep -s 5
[System.Windows.Forms.SendKeys]::SendWait("{esc}")

$content=Get-Clipboard
  start-sleep -s 5


 }
 if($content -like "*restart Microsoft Edge*") {   

   Set-Clipboard -Value "restart"
   start-sleep -s 5
    
[Microsoft.VisualBasic.interaction]::AppActivate($id)|out-null
   start-sleep -s 2
[System.Windows.Forms.SendKeys]::SendWait("^f")
  start-sleep -s 2
[System.Windows.Forms.SendKeys]::SendWait("^v")
  start-sleep -s 2
[System.Windows.Forms.SendKeys]::SendWait("~")
  start-sleep -s 2
[System.Windows.Forms.SendKeys]::SendWait("{esc}")
  start-sleep -s 2
[System.Windows.Forms.SendKeys]::SendWait("~")
 start-sleep -s 10

}



}until($content -like "*restart Microsoft Edge*" -or $content -like "*Microsoft Edge is up to date*"  -or $reconnect_time -gt 1 -or $content -like "*Unable to connect to the internet*")

if(!($content -like "*Microsoft Edge is up to date*" -and $reconnect_time -le 1) -and !($content -like "*Unable to connect to the internet*") ){
 



 ###### check version ###
  
    $id=(Get-Process msedge |?{($_.MainWindowTitle).length -gt 0}).Id
    if(!$id){openedge}
     $id=(Get-Process msedge |?{($_.MainWindowTitle).length -gt 0}).Id

   Set-Clipboard -Value "about"
   start-sleep -s 5
    
[Microsoft.VisualBasic.interaction]::AppActivate($id)|out-null
   start-sleep -s 2
[System.Windows.Forms.SendKeys]::SendWait("^f")
  start-sleep -s 2
[System.Windows.Forms.SendKeys]::SendWait("^v")
  start-sleep -s 2
[System.Windows.Forms.SendKeys]::SendWait("~")
  start-sleep -s 2
[System.Windows.Forms.SendKeys]::SendWait("{esc}")
 start-sleep -s 2
[System.Windows.Forms.SendKeys]::SendWait("^a")
  start-sleep -s 2
[System.Windows.Forms.SendKeys]::SendWait("^c")
  start-sleep -s 5
$content=Get-Clipboard

}

if($content -like "*Microsoft Edge is up to date*"  -and $reconnect_time -le 1 ){

$index=$content -match "\d{1,}\.\d{1,}\.\d{1,}\.\d{1,}"
write-host "check version: $index"

do{

Start-Sleep -s 5
$version=(Get-Item "C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe").VersionInfo.FileVersion
$versionc=[string]::Join(".",($version -split "\."|select -First 3))
}until( $index -match $version)

$results="OK"

}

if($content -like "*Unable to connect to the internet*"  -and $reconnect_time -le 1 ){

$ver=$content -match "\d{1,}\.\d{1,}\.\d{1,}\.\d{1,}"
$results="NG"
$index="fail to connect internet, update and check fail; current version is $ver"
}

if($reconnect_time -gt 1){
$ver=$content -match "\d{1,}\.\d{1,}\.\d{1,}\.\d{1,}"
$results="NG"
$index="fail to update and check edge; current version is $ver"
}

 (get-process -name msedge).CloseMainWindow() 

#region#####selenium prepare ##

$actionsln ="selenium_prepare"
Get-Module -name $actionsln|remove-module
$mdpath=(Get-ChildItem -path $scriptRoot -r -file |?{$_.name -match "^$actionsln\b" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global
&$actionsln -para1 edge -para2 nonlog

#endregion

#endregion
}

######### write log #######

Get-Module -name "outlog"|remove-module
$mdpath=(Get-ChildItem -path "C:\testing_AI\modules\"  -r -file |?{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

#write-host "Do $action!"
outlog $action $results $tcnumber $tcstep $index

   }

    export-modulemember -Function edge_update