function DMaction ([string]$para1 , [string]$para2, [string]$para3 , [string]$para4){
    #--import
    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force;
    $shell=New-Object -ComObject shell.application
    $wshell=New-Object -ComObject wscript.shell
    Add-Type -AssemblyName Microsoft.VisualBasic
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Windows.Forms,System.Drawing

    #region import
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


 Add-Type @"
using System;
using System.Runtime.InteropServices;
public class PInvoke {
    [DllImport("user32.dll")] public static extern IntPtr GetDC(IntPtr hwnd);
    [DllImport("gdi32.dll")] public static extern int GetDeviceCaps(IntPtr hdc, int nIndex);
}
"@
$hdc = [PInvoke]::GetDC([IntPtr]::Zero)
$curwidth = [PInvoke]::GetDeviceCaps($hdc, 118) # width
$curheight = [PInvoke]::GetDeviceCaps($hdc, 117) # height

$screen = [System.Windows.Forms.Screen]::PrimaryScreen
$bounds = $screen.Bounds

#endregion



    $paracheck1=$PSBoundParameters.ContainsKey('para1')

    #SATASettings
    if($paracheck1 -eq $false -or $para1.Length -eq 0){
        $para1="Scan"
    }

    $action = $para1
    $expand_flag=$para2
    $deviceName = $para3
    $driverpath = $para4

    if($PSScriptRoot.length -eq 0){
        $scriptRoot="C:\testing_AI\modules"
    }else{
        $scriptRoot=$PSScriptRoot
    }

    $actionss="screenshot"
    Get-Module -name $actionss |remove-module
    $mdpath=(Get-ChildItem -path $scriptRoot -r -file |Where-object{$_.name -match "^$actionss\b" -and $_.name -match "psm1"}).fullname
    Import-Module $mdpath -WarningAction SilentlyContinue -Global

    $action="Device Manager Check"
    $tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
    $tcnumber=((get-content $tcpath).split(","))[0]
    $tcstep=((get-content $tcpath).split(","))[1]
    $dd=get-date -format "yyMMdd_HHmmss"

    #$picpath=(Split-Path -Parent $scriptRoot)+"\logs\screenshot\"
    $picpath=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)"
    if(-not(test-path $picpath)){new-item -ItemType directory -path $picpath |out-null}




    function driveraction(){
        devmgmt.msc
 
        start-sleep -s 5

        $dmid=  (Get-Process mmc |sort starttime |select -last 1).id
 
        $wshell.AppActivate('Device Manager') 

        Get-Process -id  $dmid  | Set-WindowState -State  MAXIMIZE

        start-sleep -s 2     
     
        [Microsoft.VisualBasic.interaction]::AppActivate($dmid)|out-null
        start-sleep -s 2

        [Clicker]::LeftClickAtPoint(50, 1)

        ## show hidden ##
        if($expand_flag.Length -eq 0){
        Start-Sleep -Seconds 2
            $wshell.sendkeys("%v")
             start-sleep -s 2
               $wshell.sendkeys("w")
               }

               start-sleep -s 2
            $wshell.sendkeys("{tab}")
            start-sleep -s 2 

        if($expand_flag.Length -eq 0){
        &$actionss  -para3 nonlog -para5 "DevicecManager"
        $picfile=(Get-ChildItem $picpath |Where-object{$_.name -match ".jpg" -and $_.name -match "DeviceManager" }).FullName
          start-sleep -s 2
          }

        if($expand_flag.length -gt 0){
 

        if ($expand_flag -match "display"){$ccatg="Win32_VideoController"}  
        if ($expand_flag -match "network"){$ccatg="Win32_NetworkAdapter"} 
        if ($expand_flag -match "storage controllers"){$ccatg="Win32_SCSIController"}  #Win32_IDEController
        if ($expand_flag -match "disk"){$ccatg="Win32_DiskDrive"}

        $datenow=get-date -format "yyMMdd_HHmmss"
         #$dirverinfo="$picpath\$($datenow)_step$($tcstep)_$($expand_flag)_DriverInfo.txt"
         #new-item $dirverinfo -Force |Out-Null

          $catdrivers = Get-WmiObject $ccatg  | Where-Object { $_.ConfigManagerErrorCode -eq 0 }
           $catcount=$catdrivers.count

         $wshell.AppActivate('Device Manager') 
           start-sleep -s 2
             $wshell.sendkeys($expand_flag)
             start-sleep -s 2
              $wshell.sendkeys("{right}")


        Set-Clipboard $null
       
          $wshell.AppActivate('Device Manager') 
         start-sleep -s 1
           $wshell.sendkeys("$deviceName")
             start-sleep -s 1
               $wshell.sendkeys("~")
               start-sleep -s 5
                $wshell.sendkeys("+{tab}")
                 start-sleep -s 1

                 while(!(Get-Clipboard)){
                     $wshell.sendkeys("{right}")
                     start-sleep -s 1
                     $wshell.sendkeys("{tab 2}")
                     start-sleep -s 1
                     $wshell.sendkeys("^c")
                     start-sleep -s 2
                     $wshell.sendkeys("+{tab}")
                     start-sleep -s 2
                     $wshell.sendkeys("+{tab}")
                 }
                  $wshell.sendkeys("{left}")
        }
         #$wshell.AppActivate('Device Manager') 
  
         #start-sleep -s 1

         #$wshell.sendkeys("%{F4}")

        #if($wshell.AppActivate('Device Manager') -eq $true){stop-process -name mmc}
    }




    screenshot -para3 nolog -para5 "beforeAction"
    #Region Action -----------------------------------------------

    if($action -eq "Scan"){
        Start-Sleep -s 5

        [System.Windows.Forms.SendKeys]::SendWait("{tab}")
        Start-Sleep -s 2
        [System.Windows.Forms.SendKeys]::SendWait("%a")
        Start-Sleep -s 2
        [System.Windows.Forms.SendKeys]::SendWait("a")
        Start-Sleep -s 2
        [System.Windows.Forms.SendKeys]::SendWait("{Enter}")
    }


    if($action -eq "DriverDetails"){
       driveraction
       Start-Sleep -s 5
       [System.Windows.Forms.SendKeys]::SendWait("i")
       Start-Sleep -s 5
       screenshot -para3 nolog -para5 "DriverDetails"
    }
    if($action -eq "UpdateDriver"){
       driveraction
       Start-Sleep -s 5
       [System.Windows.Forms.SendKeys]::SendWait("p")

       Start-Sleep -s 3
       [System.Windows.Forms.SendKeys]::SendWait("{Down}")
       Start-Sleep -s 3
       [System.Windows.Forms.SendKeys]::SendWait("{Enter}")
       Start-Sleep -s 3
       [System.Windows.Forms.SendKeys]::SendWait($driverpath)
       Start-Sleep -s 3
       [System.Windows.Forms.SendKeys]::SendWait("{Enter}")
       Start-Sleep -s 3
       screenshot -para3 nolog -para5 "InstallResult"
       Start-Sleep -s 3
       [System.Windows.Forms.SendKeys]::SendWait("{ESC}")
    }
    if($action -eq "Rollback"){
       driveraction
       Start-Sleep -s 5
       [System.Windows.Forms.SendKeys]::SendWait("r")

       Start-Sleep -s 5
       [System.Windows.Forms.SendKeys]::SendWait("{tab}")
       Start-Sleep -s 5
       [System.Windows.Forms.SendKeys]::SendWait(" ")
       Start-Sleep -s 5
       [System.Windows.Forms.SendKeys]::SendWait("{tab 2}")
       Start-Sleep -s 5
       [System.Windows.Forms.SendKeys]::SendWait("{ENTER}")
    }
    if($action -eq "DisableDevice"){
       driveraction
       Start-Sleep -s 5
       [System.Windows.Forms.SendKeys]::SendWait("d")

       Start-Sleep -s 5
       [System.Windows.Forms.SendKeys]::SendWait("y")
    }
    if($action -eq "EnableDevice"){
       driveraction
       Start-Sleep -s 5
       [System.Windows.Forms.SendKeys]::SendWait("e")
    }
    if($action -eq "UninstallDevice"){
       driveraction
       Start-Sleep -s 5
       [System.Windows.Forms.SendKeys]::SendWait("u")

       Start-Sleep -s 5
       [System.Windows.Forms.SendKeys]::SendWait("{TAB 2}")
       Start-Sleep -s 3
       [System.Windows.Forms.SendKeys]::SendWait("{Enter}")
    }


    #EndRegion-----------------------------------------------
    screenshot -para3 nolog -para5 "AfterAction"
}


Export-ModuleMember -Function DMaction