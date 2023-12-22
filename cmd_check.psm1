function cmd_check ([string]$para1,[string]$para2 ){
     
     $checkline=$para1
     $action1=$para2

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
  
    if($checkline.length -ne 0){
    
    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force;
    $wshell=New-Object -ComObject wscript.shell
      Add-Type -AssemblyName Microsoft.VisualBasic
      Add-Type -AssemblyName System.Windows.Forms
 
 write-host "check ""$checkline"", action ""$action1"""        

$id2= (Get-Process cmd |sort StartTime -ea SilentlyContinue |select -first 1).id 

  [Microsoft.VisualBasic.interaction]::AppActivate($id2)|out-null
 
 Get-Process -id $id2 | Set-WindowState -State MAXIMIZE
  start-sleep -s 2

 $i=0

 do{
 
  [Microsoft.VisualBasic.interaction]::AppActivate($id2)|out-null
  start-sleep -s 2
 [Clicker]::LeftClickAtPoint(1,1)

start-sleep -s 2
$wshell.SendKeys("E")
start-sleep -s 2
$wshell.SendKeys("S")
start-sleep -s 2
$wshell.SendKeys("~")
start-sleep -s 2
$index1=Get-Clipboard

$i++
  }until ($index1 -match $checkline -or $i -gt 30)

   

 if($action1 -match "enter"){
  
  [Microsoft.VisualBasic.interaction]::AppActivate($id2)|out-null
  start-sleep -s 5
  $wshell.SendKeys("~")

    start-sleep -s 5

    ### check if cmd window still here ###
$id3= (Get-Process cmd |sort StartTime -ea SilentlyContinue |select -first 1).id 

if($id3 -eq $id2){
  [Microsoft.VisualBasic.interaction]::AppActivate($id2)|out-null
 
 [Clicker]::LeftClickAtPoint(1,1)

start-sleep -s 2
$wshell.SendKeys("E")
start-sleep -s 2
$wshell.SendKeys("S")
start-sleep -s 2
$wshell.SendKeys("~")
start-sleep -s 2
$index=Get-Clipboard
}

else{
$index=$index="[cmd window gone after] "+$index1

}

 }

  if(-not($action1 -match "enter")){
  
  [Microsoft.VisualBasic.interaction]::AppActivate($id2)|out-null
   start-sleep -s 2
  $wshell.SendKeys("$action1")
  start-sleep -s 2
  [Microsoft.VisualBasic.interaction]::AppActivate($id2)|out-null
    $wshell.SendKeys("~")
    
    start-sleep -s 5
      ### check if cmd window still here ###
$id3= (Get-Process cmd |sort StartTime -ea SilentlyContinue |select -first 1).id 

if($id3 -eq $id2){
  [Microsoft.VisualBasic.interaction]::AppActivate($id2)|out-null
 
 [Clicker]::LeftClickAtPoint(1,1)

start-sleep -s 2
$wshell.SendKeys("E")
start-sleep -s 2
$wshell.SendKeys("S")
start-sleep -s 2
$wshell.SendKeys("~")
start-sleep -s 2
$index=Get-Clipboard
}

else{
$index="[cmd window gone after] "+$index1

}


 }

 
if($index -match $checkline){$results="OK"}
else{
$results="NG"
}

  
######### write log  #######

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


Get-Module -name "outlog"|remove-module
$mdpath=(gci -path "C:\testing_AI\modules\"  -r -file |?{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

#write-host "Do $action!"
outlog $action $results $tcnumber $tcstep $index

  }

else {
  
[System.Windows.Forms.MessageBox]::Show($this,"No checkpoint, please check!")   

exit
  }


  }
    export-modulemember -Function cmd_check