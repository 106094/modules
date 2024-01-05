function passmark_rebooter ([string]$para1, [string]$para2){

    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force;
    $wshell=New-Object -ComObject wscript.shell
      Add-Type -AssemblyName Microsoft.VisualBasic
      Add-Type -AssemblyName System.Windows.Forms

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


$paracheck1=$PSBoundParameters.ContainsKey('para1')
$paracheck2=$PSBoundParameters.ContainsKey('para2')

if($paracheck1 -eq $false -or $para1.Length -eq 0){
$para1="500"
}
if($paracheck2 -eq $false -or $para2.Length -eq 0){
$para2="20"
}


$countn=$para1
$waittime=$para2

### write log first##

if($PSScriptRoot.length -eq 0){
$scriptRoot="C:\testing_AI\modules"
}
else{
$scriptRoot=$PSScriptRoot
}

$action="reboot x $countn (passmark rebooter) "
$tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
$tcnumber=$((get-content $tcpath).split(","))[0]
$tcstep=((get-content $tcpath).split(","))[1]

#$picpath=(Split-Path -Parent $scriptRoot)+"\logs\screenshot\"
$picpath=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\"
if(-not(test-path $picpath)){new-item -ItemType directory -path $picpath |out-null}

    $actionss ="screenshot"
    Get-Module -name $actionss|remove-module
    $mdpath=(Get-ChildItem -path $scriptRoot -r -file |Where-object{$_.name -match "^$actionss\b" -and $_.name -match "psm1"}).fullname
    Import-Module $mdpath -WarningAction SilentlyContinue -Global

$results="check screenshot"
$Index="rebooter_start.jpg"

Get-Module -name "outlog"|remove-module
$mdpath=(Get-ChildItem -path "C:\testing_AI\modules\" -r -file |Where-object{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

#write-host "Do $action!"
outlog $action $results  $tcnumber $tcstep $index


#### start execute rebooter ###

Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force
 $wshell = New-Object -com WScript.Shell
  Add-Type -AssemblyName Microsoft.VisualBasic
     Add-Type -AssemblyName System.Windows.Forms


if(((get-process "rebooter" -ErrorAction SilentlyContinue).Id.count) -ne 0){
Stop-Process -name rebooter -Force
start-sleep -s 5
}


if(test-path "$env:USERPROFILE\Documents\PassMark\Rebooter\Rebooter.log"){
$backuplogtime=Get-Date((Get-ChildItem $env:USERPROFILE\\Documents\PassMark\Rebooter\Rebooter.log).LastWriteTime) -Format "yyMMdd_HHmmss"
Move-Item -Path "$env:USERPROFILE\Documents\PassMark\Rebooter\Rebooter.log" "$env:USERPROFILE\Documents\PassMark\Rebooter\Rebooter_$($backuplogtime).log" -Force
}

if(test-path $env:USERPROFILE\Documents\PassMark\Rebooter\RebooterConfig.ini){
do{
remove-item $env:USERPROFILE\Documents\PassMark\Rebooter\RebooterConfig.ini -Force |Out-Null
start-sleep -s 2
$inidelete=test-path $env:USERPROFILE\Documents\PassMark\Rebooter\RebooterConfig.ini
}until($inidelete -eq $false)
}

$rebt= (Get-ChildItem -path $scriptRoot -Recurse -File -Filter "rebooter.exe").FullName
start-process $rebt
start-sleep -s 5

[Clicker]::LeftClickAtPoint(20,1)
start-sleep -s 2
#$pdid=  (get-process "rebooter").Id
#[Microsoft.VisualBasic.interaction]::AppActivate($pdid)|out-null

$wshell.SendKeys("{tab}")
start-sleep -s 2

$wshell.SendKeys($countn)
start-sleep -s 2
$wshell.SendKeys("{tab}")
start-sleep -s 1
$wshell.SendKeys("{tab}")
start-sleep -s 1
$wshell.SendKeys("{tab}")
start-sleep -s 2

$wshell.SendKeys($waittime)
start-sleep -s 2
$wshell.SendKeys("{tab}")
start-sleep -s 2

$wshell.SendKeys(" ")
start-sleep -s 2
$wshell.SendKeys("{tab}")
start-sleep -s 1
$wshell.SendKeys("{tab}")
start-sleep -s 1
$wshell.SendKeys("{tab}")
start-sleep -s 1

$wshell.SendKeys("~")
start-sleep -s 2
$wshell.SendKeys("{tab}")
start-sleep -s 1
$wshell.SendKeys("{tab}")
start-sleep -s 1
$wshell.SendKeys("{tab}")
start-sleep -s 1
$wshell.SendKeys("{tab}")
start-sleep -s 1
$wshell.SendKeys("{tab}")
start-sleep -s 1
$wshell.SendKeys("{tab}")
start-sleep -s 1

$wshell.SendKeys("~")
start-sleep -s 2
### screentshot ###

$lastid=  (Get-Process cmd |sort StartTime -ea SilentlyContinue |select -last 1).id
 Get-Process -id $lastid  | Set-WindowState -State MINIMIZE
 
##screenshot##
&$actionss  -para3 nonlog -para5 "rebooter_start"

exit

}


  
    export-modulemember -Function passmark_rebooter