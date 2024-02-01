function specview_dl ([string]$para1,[string]$para2){

    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force;
    $wshell=New-Object -ComObject wscript.shell
      Add-Type -AssemblyName Microsoft.VisualBasic
      Add-Type -AssemblyName System.Windows.Forms

  #region import functions
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

    if($PSScriptRoot.length -eq 0){
        $scriptRoot="C:\testing_AI\modules"
    }else{
        $scriptRoot=$PSScriptRoot
    }

    $spectype="SPECviewperf2020"

        if( $para1 -match "work"){
            $spectype="SPECworkstation"
        }
  
    $nonlog_flag=$para2
    
    ##selenium is not working        
    

    $actionss="screenshot"
    Get-Module -name $actionss|remove-module
    $mdpath=(Get-ChildItem -path $scriptRoot -r -file |Where-object{$_.name -match "^$actionss\b" -and $_.name -match "psm1"}).fullname
    Import-Module $mdpath -WarningAction SilentlyContinue -Global

    $actionsfe ="filexplorer"
    Get-Module -name $actionsfe|remove-module
    $mdpath=(get-childitem -path $scriptRoot -r -file |where-object{$_.name -match "^$actionsfe\b" -and $_.name -match "psm1"}).fullname
    Import-Module $mdpath -WarningAction SilentlyContinue -Global
        
    $action="$spectype Download from website"
    $tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
    $tcnumber=((get-content $tcpath).split(","))[0]
    $tcstep=((get-content $tcpath).split(","))[1]
    $picpath=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\"
    if(-not(test-path $picpath)){new-item -ItemType directory -path $picpath |out-null}

    $results="OK"
    $index="download ok"
    
    $website="https://gwpg.spec.org/benchmarks/benchmark/specviewperf-2020-v3-1/"
    $filename="$spectype*.exe"
    if($spectype -eq "SPECworkstation"){
    $website="https://gwpg.spec.org/benchmarks/benchmark/specworkstation-3_1/"
    $filename="$spectype*.zip"
    }

    start-process msedge $website -WindowStyle Maximized
    start-sleep -s 20
    $id=(Get-Process msedge |Where-object{($_.MainWindowTitle).length -gt 0}).Id
     start-sleep -s 2
     Get-Process -id $id | Set-WindowState -State MAXIMIZE
     $Handles = Get-Process msedge| Where-Object { $_.MainWindowTitle -match $env:TITLE } | where-Object { $_.MainWindowHandle -ne 0}
     $Handle=$Handles.MainWindowHandle
     $WindowRect = New-Object RECT
     $GotWindowRect = [Window]::GetWindowRect($Handle, [ref]$WindowRect)
     $clickx=($WindowRect.right)/2
     $clicky= 10
 
     [Microsoft.VisualBasic.interaction]::AppActivate($id)|out-null
     start-sleep -s 2
     [Clicker]::LeftClickAtPoint($clickx, $clicky)
     start-sleep -s 2
     [System.Windows.Forms.SendKeys]::SendWait("{tab 10}")
     &$actionss  -para3 nonlog -para5 "start"

     [System.Windows.Forms.SendKeys]::SendWait("~")
     start-sleep -s 2
     [System.Windows.Forms.SendKeys]::SendWait("{tab 4}")
     &$actionss  -para3 nonlog -para5 "next1"

     [System.Windows.Forms.SendKeys]::SendWait("~")
     start-sleep -s 2
     [System.Windows.Forms.SendKeys]::SendWait("{tab}")
     start-sleep -s 1
     [System.Windows.Forms.SendKeys]::SendWait("{right}")

     [System.Windows.Forms.SendKeys]::SendWait("{tab}")   

     [System.Windows.Forms.SendKeys]::SendWait(" ")
     start-sleep -s 1
     [System.Windows.Forms.SendKeys]::SendWait("{tab 3}")
     &$actionss  -para3 nonlog -para5 "startdownload"

     $starttime=Get-Date

     [System.Windows.Forms.SendKeys]::SendWait("~")
     start-sleep -s 60
     &$actionss  -para3 nonlog -para5 "downloading"

    do{
        Start-Sleep -s 60
        $timepassed= (New-TimeSpan -start $starttime -end (get-date)).TotalMinutes
       $checkdownload=test-path -Path "$env:USERPROFILE\Downloads\$filename"
       #https://spec.cs.miami.edu/downloads/gpc/opc/viewperf/SPECviewperf2020.3.1.exe
      }until ($checkdownload -or $timepassed -gt 180)

      if($checkdownload){
      write-output "$spectype download complete: $(get-date)"
      Move-Item "$env:USERPROFILE\Downloads\$filename" -Destination "$env:USERPROFILE\desktop" -Force
      &$actionsfe -para1 "$env:USERPROFILE\desktop\" -para2 "nolog"
      $copytopath="C:\testing_AI\modules\BITools\$spectype"
      if(!(test-path $copytopath)){new-item -ItemType directory -path $copytopath |out-null}
      Move-Item "$env:USERPROFILE\desktop\$filename" -Destination $copytopath -Force
      }
      else{
       $results="NG"
       $index="fail to download $spectype in $($timepassed) minites"
       }

       (get-process -name msedge -ea SilentlyContinue).CloseMainWindow()
    
    ### write to log ###
    
    if($nonlog_flag.Length -eq 0 -and !$writelog){
    Get-Module -name "outlog"|remove-module
    $mdpath=(get-childitem -path "C:\testing_AI\modules\" -r -file |where-object{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
    Import-Module $mdpath -WarningAction SilentlyContinue -Global

    #write-host "Do $action!"
    outlog $action $results $tcnumber $tcstep $index
    }
    
 }
  
  export-modulemember -Function specview_dl