
function gpumon ([string]$para1){
      
  Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force;
  #$wshell=New-Object -ComObject wscript.shell
    Add-Type -AssemblyName Microsoft.VisualBasic
     Add-Type -AssemblyName System.Windows.Forms
      Add-Type -AssemblyName System.Windows.Forms,System.Drawing
  
  #region import functions
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

Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public class SetWindowHelper {
    [DllImport("user32.dll")]
    public static extern bool GetWindowRect(IntPtr hWnd, out myRECT myrect);
}

public struct myRECT {
    public int Left;
    public int Top;
    public int Right;
    public int Bottom;
}
"@

#endregion
            
   
if($PSScriptRoot.length -eq 0){
$scriptRoot="C:\testing_AI\modules"
}
else{
$scriptRoot=$PSScriptRoot
}

$actiontype=$para1

$tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
$tcnumber=((get-content $tcpath).split(","))[0]
$tcstep=((get-content $tcpath).split(","))[1]
$action=((get-content $tcpath).split(","))[2]

$picpath=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\"
if(-not(test-path $picpath)){new-item -ItemType directory -path $picpath |out-null}

$results= "OK"
$index="check screenshot and log"

$actionss ="screenshot"
Get-Module -name $actionss|remove-module
$mdpath=(get-childitem -path $scriptRoot -r -file |where-object{$_.name -match "^$actionss\b" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

$checkgfx=(Get-WmiObject -Class Win32_VideoController | Select-Object Name,AdapterCompatibility).name
if($checkgfx -match "amd"){
$results="na"
$index="AMD Gfx Driver, by pass"+"`n" `
+"Refer to https://developer.nvidia.com/rtx/path-tracing/nvapi/get-started, NVAPI is NVIDIA's core software development kit, that supported on NVIDIA graphics card."
}

else{

function opengpumon {
start-sleep -s 5
$checkrunning=get-process -name GPUMon -ErrorAction SilentlyContinue
if(!$checkrunning){

&"$scriptRoot\GPUMon\GPUMon.exe"
start-sleep -s 20
}

$gpumid=(get-process -name GPUMon).Id
[Microsoft.VisualBasic.Interaction]::AppActivate($gpumid)
start-sleep -s 2
$windowHandle = (Get-Process -Name "GPUMON").MainWindowHandle
$myrect = New-Object myRECT
[SetWindowHelper]::GetWindowRect($windowHandle, [ref]$myrect)

$windowx = $myrect.Left
$windowy = $myrect.Top

[Clicker]::LeftClickAtPoint($windowx+30, $windowy+5)
  Start-Sleep -s 2

  }

if($actiontype -match "start"){    

opengpumon

[System.Windows.Forms.SendKeys]::SendWait("{tab 14}")
 Start-Sleep -s 2
 
## screenshot ##

&$actionss  -para3 nonlog -para5 "$actiontype_tab14"

 [System.Windows.Forms.SendKeys]::SendWait("~")
  Start-Sleep -s 2

$gpumid=(get-process -name GPUMon -ErrorAction SilentlyContinue).Id

if(-not($gpumid)){
opengpumon

[System.Windows.Forms.SendKeys]::SendWait("{tab 13}")
    Start-Sleep -s 2
    
&$actionss  -para3 nonlog -para5 "$actiontype_tab13"

     
 [System.Windows.Forms.SendKeys]::SendWait("~")
   Start-Sleep -s 2
 }
 
$gpumid=(get-process -name GPUMon).Id

if($gpumid){

## screenshot ##

&$actionss  -para3 nonlog -para5 "clickstart"

#$picfile3=(get-childitem $picpath |where-object{$_.name -match ".jpg" -and $_.name -match "clickstart" }|sort-object lastwritetime|select-object -last1).FullName

start-sleep -s 1
[System.Windows.Forms.SendKeys]::SendWait("~")

}
else{
$results= "NG"
$index="fail to start log"
}

}

if($actiontype -match "end"){

$gpumid=(get-process -name GPUMon).Id
 if($gpumid){

$tiemcheck1=get-date

do{
start-sleep -s 2
$checklogs=get-childitem -path C:\testing_AI\* -Recurse  -File -Filter "GPUMon.log"|sort-object lastwritetime|select-object -last 1
$checktime=$checklogs.lastwritetime
$timespan=(New-TimeSpan -start $tiemcheck1 -end  $checktime).TotalSeconds
}until($timespan -gt 10)

$newlog=$checklogs.fullname

opengpumon

[System.Windows.Forms.SendKeys]::SendWait("~")
 Start-Sleep -s 2         
 
&$actionss  -para3 nonlog -para5 $actiontype


(get-process -name GPUMon).CloseMainWindow()

$timestmp=Get-Date -Format "yyMMdd_HHmmss"

Move-Item  $newlog "$picpath\$($timestmp)_GPUMon.log" -Force


}

else{
$results= "NG"
$index="no GPUMon is running"
}

}

if($actiontype -match "GPUsettings"){

opengpumon
  
&$actionss  -para3 nonlog -para5 "open"

[System.Windows.Forms.SendKeys]::SendWait("{tab 3}")
 Start-Sleep -s 2
 
[System.Windows.Forms.SendKeys]::SendWait(" ")
 
&$actionss  -para3 nonlog -para5 "$($actiontype)_L0s_check"
 
[System.Windows.Forms.SendKeys]::SendWait(" ")
 
&$actionss  -para3 nonlog -para5 "$($actiontype)_L0s_uncheck"

[System.Windows.Forms.SendKeys]::SendWait("{tab}")
 
[System.Windows.Forms.SendKeys]::SendWait(" ")
 
 &$actionss  -para3 nonlog -para5 "$($actiontype)_L1_check"
 
[System.Windows.Forms.SendKeys]::SendWait(" ")

 &$actionss  -para3 nonlog -para5 "$actiontype_L1_uncheck"
 
[System.Windows.Forms.SendKeys]::SendWait("{tab 3}")
## screenshot ##

[System.Windows.Forms.SendKeys]::SendWait("{F4}")
&$actionss  -para3 nonlog -para5 "$($actiontype)_width_expand"

[System.Windows.Forms.SendKeys]::SendWait("{F4}")
 Start-Sleep -s 2
   [System.Windows.Forms.SendKeys]::SendWait("{tab}")
      Start-Sleep -s 2
     [System.Windows.Forms.SendKeys]::SendWait("{F4}")
&$actionss  -para3 nonlog -para5 "$($actiontype)_gen_expand"

[System.Windows.Forms.SendKeys]::SendWait("{F4}")
 Start-Sleep -s 2

 (Get-Process -name gpumon).CloseMainWindow()

}


}
######### write log #######

Get-Module -name "outlog"|remove-module
$mdpath=(get-childitem -path "C:\testing_AI\modules\"  -r -file |where-object{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

#write-host "Do $action!"
outlog $action $results $tcnumber $tcstep $index


 }

  export-modulemember -Function gpumon