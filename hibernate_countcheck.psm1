function hibernate_countcheck(){


    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force;
    $wshell=New-Object -ComObject wscript.shell
      Add-Type -AssemblyName Microsoft.VisualBasic
      Add-Type -AssemblyName System.Windows.Forms

$waitflag="C:\testing_AI\logs\S4count.txt"
$counta=get-content $waitflag

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


if($PSScriptRoot.length -eq 0){
$scriptRoot="C:\testing_AI\modules\"
}
else{
$scriptRoot=$PSScriptRoot
}


$tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
$tcnumber=((get-content $tcpath).split(","))[0]
$tcstep=((get-content $tcpath).split(","))[1]
$action="hibernate cycle count $counta check"

$logfile=(Split-Path -Parent $scriptRoot)+"\logs\logs_timemap.csv"
$lastlogtime = (import-csv $logfile |?{$_.actions -match "s4" -or $_.actions -match "hibernate"}|select -Last 1).Time

$s4count=(Get-WinEvent -FilterHashtable @{ LogName='System'; StartTime=$lastlogtime; Id='42' } -ErrorAction SilentlyContinue).count
$checkexe=((get-process -name pwrtest -ErrorAction SilentlyContinue).Id).count

if($s4count -lt $counta -and $checkexe -eq 0){

start-process cmd -ArgumentList '/c schtasks /DISABLE /TN "Auto_Run" -f' 
[System.Windows.Forms.MessageBox]::Show($this, "S4 Main Program stops, please check")   
exit
}

if( $s4count -eq $null -or $s4count -lt $counta){
exit
}

else{

start-sleep -s 100  ## wait enter desktop ##

$results="OK"
$index=$counta

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

$cmdids=  (Get-Process cmd).id

foreach($cmdid in $cmdids) {
  
  $contents=$null

  Start-Sleep -Seconds 2
  
  [Microsoft.VisualBasic.interaction]::AppActivate($cmdid)|out-null
  Get-Process -id $cmdid  | Set-WindowState -State MAXIMIZE
   Start-Sleep -Seconds 1
   [Clicker]::LeftClickAtPoint(1,1)
    start-sleep -s 1

    $wshell.SendKeys("E")
    start-sleep -s 1
    $wshell.SendKeys("S")
    start-sleep -s 1
    $wshell.SendKeys("~")
    start-sleep -s 1
    $contents=Get-Clipboard
    start-sleep -s 2

    if($contents -match "pwrtest"){
    
   #[Microsoft.VisualBasic.interaction]::AppActivate($lastid)|out-null
   #Start-Sleep -Seconds 1
  
        $timenow=get-date -format "yyMMdd_HHmmss"
        #$picpath=(Split-Path -Parent $scriptRoot)+"\logs\screenshot\"
        $picpath=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\"
        if(-not(test-path $picpath)){new-item -ItemType directory -path $picpath |out-null}
        $picfile=$picpath+"$timenow-$tcnumber-$tcstep-$action.jpg"

        Add-Type -AssemblyName System.Windows.Forms,System.Drawing

        #$screens = [Windows.Forms.Screen]::AllScreens

        #$width  = ([System.Windows.Forms.SystemInformation]::PrimaryMonitorSize|select Width).width
        #$height = ([System.Windows.Forms.SystemInformation]::PrimaryMonitorSize|select Height).Height

        $width  = ([string]::Join("`n", (wmic path Win32_VideoController get CurrentHorizontalResolution))).split("`n") -match "\d{1,}"
        $height  = ([string]::Join("`n", (wmic path Win32_VideoController get CurrentVerticalResolution))).split("`n") -match "\d{1,}"

        $bounds   = [Drawing.Rectangle]::FromLTRB(0, 0, [int64] $width.trim() , [int64] $height.trim() )
        $bmp      = New-Object System.Drawing.Bitmap ([int]$bounds.width), ([int]$bounds.height)
        $graphics = [Drawing.Graphics]::FromImage($bmp)

        $graphics.CopyFromScreen($bounds.Location, [Drawing.Point]::Empty, $bounds.size)

        $bmp.Save($picfile)

        $graphics.Dispose()
        $bmp.Dispose()

        start-sleep -s 1
        taskkill /PID $cmdid /F 


    }
    else{   Get-Process -id $cmdid  | Set-WindowState -State MINIMIZE }

}


}

######## record log #######


Get-Module -name "outlog"|remove-module
$mdpath=(gci -path "C:\testing_AI\modules\" -r -file |?{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

#write-host "Do $action!"
outlog $action $results $tcnumber $tcstep $index

Remove-Item -path $waitflag -Force

#Remove-Item -Path "$env:USERPROFILE\desktop\S4.log" -force  -ErrorAction SilentlyContinue| out-null

}

  export-modulemember -Function  hibernate_countcheck