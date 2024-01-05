

function feedbackstop([string]$para1){
         
    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force;
    $wshell=New-Object -ComObject wscript.shell
      $shell=New-Object -ComObject shell.application
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


 # create a new .NET type for  close  app windows
$signature = @"
[DllImport("user32.dll")]public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);
"@
Add-Type -MemberDefinition $signature -Name MyType -Namespace MyNamespace

#endregion

   $nonlog_flag=$para1
  
if($PSScriptRoot.length -eq 0){
$scriptRoot="C:\testing_AI\modules"
}
else{
$scriptRoot=$PSScriptRoot
}
 

$action="FeedbackHub_stop"
$tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
$tcnumber=((get-content $tcpath).split(","))[0]
$tcstep=((get-content $tcpath).split(","))[1]

$picpath=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\"
if(-not(test-path $picpath)){new-item -ItemType directory -path $picpath |out-null}


    $actionss ="screenshot"

    Get-Module -name $actionss|remove-module
    $mdpath=(Get-ChildItem -path $scriptRoot -r -file |?{$_.name -match "^$actionss\b" -and $_.name -match "psm1"}).fullname
    Import-Module $mdpath -WarningAction SilentlyContinue -Global

    
    $actionpcai ="pcai"
    Get-Module -name $actionpcai|remove-module
    $mdpath=(Get-ChildItem -path $scriptRoot -r -file |?{$_.name -match "^$actionpcai\b" -and $_.name -match "psm1"}).fullname
    Import-Module $mdpath -WarningAction SilentlyContinue



<## no working ##
$fbhid=(get-process pilotshubapp).id
Get-Process -id $fbhid | Set-WindowState -State MAXIMIZE
 start-sleep -s 1
$wshell.AppActivate($fbhid)
##>

<##working tab ##
Add-Type @"
  using System;
  using System.Runtime.InteropServices;
  public class Tricks {
    [DllImport("user32.dll")]
    public static extern IntPtr GetForegroundWindow();
}
"@

$winc= Get-Process | Where-Object {$_.MainWindowTitle -ne ""} | Measure-Object | Select-Object -ExpandProperty Count
$x=0
do{
$x++
[System.Windows.Forms.SendKeys]::SendWait("%{tab $x}")
start-sleep -s 2
$a = [tricks]::GetForegroundWindow()
$processnamefront = (get-process | ? { $_.mainwindowhandle -eq $a }).ProcessName
$processhandlefront = (get-process | ? { $_.mainwindowhandle -eq $a }).Handles
$processnamefront
}until($processnamefront -match "ApplicationFrameHost" -or $x -ge $winc)
##working tab ##>

stop-process -Name SystemSettings -Force -ea SilentlyContinue 
start-sleep -s 2

$fid=(Get-Process "ApplicationFrameHost").Id
[Microsoft.VisualBasic.interaction]::AppActivate($fid)|out-null

  start-sleep -s 3

  
 &$actionpcai -para1 "FeedbackHubstoprec" -para4 "nc" -para5 "nolog"

  #region replaced by pcai action
<#
    [System.Windows.Forms.SendKeys]::SendWait("+{TAB}")
        
    &$actionss -para3 non_log -para5 "stop_recording_selected"
    
   [System.Windows.Forms.SendKeys]::SendWait(" ")
   #>
   
   start-sleep -s 3
   
    &$actionss -para3 non_log -para5 "recording_stopped"

   <##

   
 [System.Windows.Forms.SendKeys]::SendWait("{tab 10}")
 
   start-sleep -s 3


    [System.Windows.Forms.SendKeys]::SendWait(" ") ## open folder
     start-sleep -s 3
     
    [System.Windows.Forms.SendKeys]::SendWait("% ")  
    [System.Windows.Forms.SendKeys]::SendWait("x")   ## maximun file explorer
      start-sleep -s 1

    [System.Windows.Forms.SendKeys]::SendWait("^l")
      start-sleep -s 1
    [System.Windows.Forms.SendKeys]::SendWait("^c") ## copy path
      start-sleep -s 5
    $recpath=Get-Clipboard
     start-sleep -s 5
    
    write-host "log path : $recpath"
    ### check if save recording file success ##
##>

$logfile=(Split-Path -Parent $scriptRoot)+"\logs\logs_timemap.csv"
$recstart=(Get-ChildItem $logfile).LastWriteTime

$digpath="$env:userprofile\AppData\Local\Packages\Microsoft.WindowsFeedbackHub_*\RoamingState\DiagnosticLogs"
$digpath2="$env:userprofile\AppData\Local\Packages\Microsoft.WindowsFeedbackHub_*\LocalCache\DiagnosticLogs"
$digpath3="$env:userprofile\Documents\FeedbackHub\DiagnosticLogs"
$recfilec=0
$timestart=get-date

  do{
  start-sleep -s 30
  $timeend=Get-Date
  $passtime=[math]::Round((New-TimeSpan -start $timestart -end $timeend).TotalMinutes,1)
  $nowtime=get-date -format "HH:mm:ss"
  if(test-path $digpath){
   $recfiles= (Get-ChildItem $digpath\*\*  -Directory |?{$_.name -match "Repro"}|?{$_.LastWriteTime -gt $recstart})
  $recfilec=$recfiles.count
   if($recfilec -eq 0){ write-host " $($nowtime): $digpath not found yet "}
    else{ write-host "$($nowtime): found report folder - $digpath"}
  }

  if($recfilec -eq 0 -and (test-path $digpath2)){
  
  $recfiles= (Get-ChildItem $digpath2\*\*  -Directory |?{$_.name -match "Repro"}|?{$_.LastWriteTime -gt $recstart})
  $recfilec=$recfiles.count
  if($recfilec -eq 0){ write-host "$($nowtime): $digpath2 not found yet"}
    else{ write-host "$($nowtime): found report folder - $digpath2"}
  }
  

  if($recfilec -eq 0 -and (test-path $digpath3)){
  
  $recfiles= (Get-ChildItem $digpath3\*\*  -Directory |?{$_.name -match "Repro"}|?{$_.LastWriteTime -gt $recstart})
  $recfilec=$recfiles.count  
  if($recfilec -eq 0){ write-host "$($nowtime): $digpath3 not found yet"}
  else{ write-host "$($nowtime): found report folder - $digpath3 "}
  }

  }until($recfilec -gt 0 -or $passtime -gt 60 )
 
 
    ### close feedback hub #
    
  Stop-Process -Id $fid

  if($recfilec -gt 0){
  start-sleep -s 10

  $fullpathrec=$recfiles.FullName 
  $fullpathrec2=Split-Path $fullpathrec
   
    write-host "new record path : $fullpathrec2"

    $timenow=get-date -format "yyMMdd_HHmmss"
    $recpath=$picpath+"$($timenow)_step$($tcstep)_feedbackhub_recpath.txt"
    set-content $recpath -value $fullpathrec2

    explorer "$fullpathrec2"

      start-sleep -s 5
      
    [System.Windows.Forms.SendKeys]::SendWait("% ") 
      start-sleep -s 1
    [System.Windows.Forms.SendKeys]::SendWait("x")  

     <##
   Set-Clipboard $fullpathrec2
   
     start-sleep -s 5

    [System.Windows.Forms.SendKeys]::SendWait("^v")
      start-sleep -s 1
    [System.Windows.Forms.SendKeys]::SendWait("~")    
     start-sleep -s 2
     ##>                                        

      &$actionss -para3 non_log -para5 "record_logpath"

 ### close file explore windows

 $shell.Windows() |?{$_.name -eq "File Explorer"}| ForEach-Object { $_.Quit() }
      start-sleep -s 5

 #  $fbhid=(get-process pilotshubapp).id
  #  stop-process -id $fbhid -force

    $results="check recording logs"
    $index=$fullpathrec2
}
else{
    $results="NG"
    $index="no DiagnosticLogs results is found in 1 hour"
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
Export-ModuleMember -Function feedbackstop