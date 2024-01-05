
function　create_systemimage ([string]$para1){
      
    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force;
    $wshell=New-Object -ComObject wscript.shell
       $shell=New-Object -ComObject shell.application
          Add-Type -AssemblyName Microsoft.VisualBasic
          Add-Type -AssemblyName System.Windows.Forms
          Add-Type -AssemblyName System.Windows.Forms,System.Drawing
      

$clickSource = @'
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
Add-Type -TypeDefinition $clickSource -ReferencedAssemblies System.Windows.Forms,System.Drawing

# [Clicker]::LeftClickAtPoint(0, 0)  ## click

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
     
   $nonlog_flag=$para1

 #  Control Panel\System and Security\Backup and Restore (Windows 7)

if($PSScriptRoot.length -eq 0){
$scriptRoot="C:\testing_AI\modules"
}
else{
$scriptRoot=$PSScriptRoot
}

$screen = [System.Windows.Forms.Screen]::PrimaryScreen
$bounds = $screen.Bounds
$width  = $bounds.Width
$height = $bounds.Height

#$width  = (([string]::Join("`n", (wmic path Win32_VideoController get CurrentHorizontalResolution))).split("`n") -match "\d{1,}")[0]
#$height  = (([string]::Join("`n", (wmic path Win32_VideoController get CurrentVerticalResolution))).split("`n") -match "\d{1,}")[0]

$action="Create_SystemImage_by ControlPanel"
$tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
$tcnumber=((get-content $tcpath).split(","))[0]
$tcstep=((get-content $tcpath).split(","))[1]

$picpath=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\"
if(-not(test-path $picpath)){new-item -ItemType directory -path $picpath |out-null}

$actionmd="screenshot"
Get-Module -name $actionmd|remove-module
$mdpath=(Get-ChildItem -path $scriptRoot -r -file |?{$_.name -match "^$actionmd\b" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global


### open control panel ##

control /name Microsoft.BackupAndRestore -WindowStyle Maximized
Start-Sleep -s 2

$wid=(get-process *|?{$_.MainWindowTitle -match "backup and restore"}).Id
$wshell.AppActivate($wid)

 Get-Process -id $wid  | Set-WindowState -State MAXIMIZE
Start-Sleep -s 2

<#

$ctlpath="Control Panel\System and Security\Backup and Restore (Windows 7)" 

Start-Process control -Verb Open -WindowStyle Maximized
start-sleep -s 5

$wid=(get-process *|?{$_.MainWindowTitle -match "control panel"}).Id
$wshell.AppActivate($wid)

 Get-Process -id $wid  | Set-WindowState -State MAXIMIZE
Start-Sleep -s 2


[Clicker]::LeftClickAtPoint(20, 0) 
Start-Sleep -s 2

$wshell.SendKeys("^l")
Set-Clipboard $ctlpath
Start-Sleep -s 5
$wshell.SendKeys("^v")
Start-Sleep -s 1
$wshell.SendKeys("~")
Start-Sleep -s 1
#>


$wshell.SendKeys("^l")
Start-Sleep -s 2
$wshell.SendKeys("{tab 3}")
Start-Sleep -s 1
$wshell.SendKeys("~")

Start-Sleep -s 30  ## it takes more time for 1st time open probably need scan disk


$wshell.SendKeys("t") ## t for select net disk ;h for hard disk; d for dvd
Start-Sleep -s 1
$wshell.SendKeys("{tab}")
Start-Sleep -s 1

## check image 1##

&$actionmd  -para3 nonlog -para5 "step1"

$wshell.SendKeys("~")

$usern=$env:USERNAME
$datetime=get-date -Format "yyMMdd_HHmmss"
$backuppath="\\192.168.2.249\Acronis\For_TC_BackupImage\$($usern)_$($datetime)"
mkdir $backuppath |Out-Null

Set-Clipboard -value $backuppath
Start-Sleep -s 5
$wshell.SendKeys("^v")
Start-Sleep -s 2
$wshell.SendKeys("{tab 2}")

Set-Clipboard -value "pctest"
Start-Sleep -s 5
$wshell.SendKeys("^v")
Start-Sleep -s 2
$wshell.SendKeys("{tab}")

Set-Clipboard -value "pctest"
Start-Sleep -s 5
$wshell.SendKeys("^v")
Start-Sleep -s 2
$wshell.SendKeys("{tab}")
Start-Sleep -s 2

## check image 2##

&$actionmd  -para3 nonlog -para5 "step2"

start-sleep -s 2

$wshell.SendKeys("~")
start-sleep -s 5

 
 ## close control table ##
 (Get-Process -id $wid -ea SilentlyContinue).CloseMainWindow()


## active Create image window ###
$cwid=(get-process *|?{$_.MainWindowTitle -match "Create a system image"}).Id
start-sleep -s 2
$wshell.AppActivate($cwid)
start-sleep -s 5

## check image 3##
&$actionmd  -para3 nonlog -para5 "step3"


## active last window ###

start-sleep -s 2
$wshell.SendKeys("%n")
start-sleep -s 2


## check image 4##
&$actionmd  -para3 nonlog -para5 "step4"


start-sleep -s 2
$wshell.SendKeys("%n")
start-sleep -s 2

## check image 5##
&$actionmd  -para3 nonlog -para5 "step5"


start-sleep -s 2
$wshell.SendKeys("%s")
start-sleep -s 2

## check image 6##

&$actionmd  -para3 nonlog -para5 "step6"


start-sleep -s 10
 
 ### sdclt ###

 $sdcltct = ((get-process sdclt -ea SilentlyContinue).Id).count
 
 $clickx=[int64]$width/2
 $clicky=[int64]$height/2

 if(  $sdcltct -gt 0){
 
 Start-Sleep -S 3600 ## wait one hour

 $n=0

 do{
 
 $n++

 Start-Sleep -s 180

 $sdcltct = ((get-process sdclt -ea SilentlyContinue).Id).count
 
 
&$actionmd  -para3 nonlog -para5 "imagebackup_$($n)"
 
 Start-Sleep -s 5

[Clicker]::LeftClickAtPoint($clickx, $clicky) 

 Start-Sleep -s 1

$wid2=(get-process *|?{$_.MainWindowTitle -match "create"}).Id
$wshell.AppActivate($wid2)

 Start-Sleep -s 5
 
$wshell.SendKeys("%n")
&$actionmd  -para3 nonlog -para5 "Close repair disk"


$wshell.SendKeys("C")
&$actionmd  -para3 nonlog -para5 "Close"



 $sdcltct = ((get-process sdclt -ea SilentlyContinue).Id).count

 }until($sdcltct -eq 0)

 <### explore ###
 $usern=$env:USERNAME

 $backuppath=(Get-ChildItem -path "X:\WindowsImageBackup\$usern\Backup*" -directory).FullName

 ### add acl ##
$sharepath =  $backuppath
$Acl = Get-ACL $SharePath
$AccessRule= New-Object System.Security.AccessControl.FileSystemAccessRule("everyone","FullControl","ContainerInherit,Objectinherit","none","Allow")
$Acl.AddAccessRule($AccessRule)
Set-Acl $SharePath $Acl
 ### add acl ##>

 ## close all file explore ##

 # create a new .NET type for  close  app windows
$signature = @"
[DllImport("user32.dll")]public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);
"@
Add-Type -MemberDefinition $signature -Name MyType -Namespace MyNamespace

 $shell.Windows() |?{$_.name -eq "File Explorer"}| ForEach-Object { $_.Quit() }
 
 $sname=$env:COMPUTERNAME
 do{
  start-sleep -s 10
   $backuppath2=(Get-ChildItem -path "$backuppath\WindowsImageBackup\$($sname)\Backup*" -directory).FullName
 }until( $backuppath2.Length -gt 0)


Write-Host "open folder of  $backuppath2"
 start explorer  "$backuppath2"  -WindowStyle Maximized

  start-sleep -s 10

  <###
 start-sleep -s 5
 $wshell.SendKeys("~")
 start-sleep -s 2
 $wshell.SendKeys("~")
 start-sleep -s 2
 ##>

 
 ### brint file explorer to front ##

$windows = $shell.Windows()

foreach ($window in $windows) {
  if ($window.Name -eq "File Explorer") {
    $hwnd = $window.HWND
    Add-Type @"
        using System;
        using System.Runtime.InteropServices;
        public class Utils {
            [DllImport("user32.dll")]
            public static extern bool SetForegroundWindow(IntPtr hWnd);
        }
"@
    [void][Utils]::SetForegroundWindow($hwnd)
  }
}


&$actionmd  -para3 nonlog -para5 "imagebackup_explorer"


 $shell.Windows() |?{$_.name -eq "File Explorer"}| ForEach-Object { $_.Quit() }


 $reesults="wait check"
 $index="check backup image at $backuppath2"

 }
 else{
 
 $reesults="NG"
 $index="fail to backup image"
 }


######### write log  #######

if($nonlog_flag.Length -eq 0){
Get-Module -name "outlog"|remove-module
$mdpath=(Get-ChildItem -path "C:\testing_AI\modules\"  -r -file |?{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

#write-host "Do $action!"
outlog $action $results $tcnumber $tcstep $index

  }

  }

  
    export-modulemember -Function create_systemimage