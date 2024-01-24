
function screenshot([int]$para1,[string]$para2,[string]$para3,[string]$para4,[string]$para5){

    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force;
    #$wshell=New-Object -ComObject wscript.shell
       Add-Type -AssemblyName System.Windows.Forms,System.Drawing,Microsoft.VisualBasic
       
try{
$source = @"
using System;
using System.Threading.Tasks;
using System.Runtime.InteropServices;
using System.Windows.Forms;
namespace KeySends
{
    public class KeySend
    {
        [DllImport("user32.dll")]
        public static extern void keybd_event(byte bVk, byte bScan, int dwFlags, int dwExtraInfo);
        private const int KEYEVENTF_EXTENDEDKEY = 1;
        private const int KEYEVENTF_KEYUP = 2;
        public static void KeyDown(Keys vKey)
        {
            keybd_event((byte)vKey, 0, KEYEVENTF_EXTENDEDKEY, 0);
        }
        public static void KeyUp(Keys vKey)
        {
            keybd_event((byte)vKey, 0, KEYEVENTF_EXTENDEDKEY | KEYEVENTF_KEYUP, 0);
        }
    }
}
"@
Add-Type -TypeDefinition $source -ReferencedAssemblies "System.Windows.Forms"
}
catch{
#Write-Host "Error: $($_.Exception.Message)"
}
$paracheck1=$PSBoundParameters.ContainsKey('para1')
#$paracheck2=$PSBoundParameters.ContainsKey('para2')
$paracheck3=$PSBoundParameters.ContainsKey('para3')
$paracheck4=$PSBoundParameters.ContainsKey('para4')
$paracheck5=$PSBoundParameters.ContainsKey('para5')

if($paracheck1 -eq $false -or  $para1 -eq 0){
$para1=  [int]3
}

if($para2 -match "show"){
$para2= "showtaskbar"
}
else{
$para2= ""
}

if($paracheck3 -eq $false -or  $para3.Length -eq 0){
$para3= ""
}
if($paracheck4 -eq $false -or  $para4.Length -eq 0){
$para4= ""
}
if($paracheck5 -eq $false -or  $para5.Length -eq 0){
$para5= ""
}

$timeset=[int]$para1
$taskbarpara=$para2
$nonlog_flag=$para3
$exit_flag=$para4
$picnameindex=$para5
$picnameindex=$picnameindex.replace(":","")

if($PSScriptRoot.length -eq 0){
$scriptRoot="C:\testing_AI\modules"
}
else{
$scriptRoot=$PSScriptRoot
}

$tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"

$tcnumber=((get-content $tcpath).split(","))[0]
$tcstep=((get-content $tcpath).split(","))[1]
$action2=((get-content $tcpath).split(","))[2]
$timenow=get-date -format "yyMMdd_HHmmss"
#$picpath=(Split-Path -Parent $scriptRoot)+"\logs\screenshot\"
$picpath=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\"
if(-not(test-path $picpath)){new-item -ItemType directory -path $picpath |out-null}
$picfile=$picpath+"$($timenow)_step$($tcstep)_$($action2).jpg"
if($picnameindex.length -gt 0){$picfile=$picpath+"$($timenow)_step$($tcstep)_$($action2)_$($picnameindex).jpg"}

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

### minimized cmd window ###

#$lastid=  (Get-Process cmd |sort StartTime -ea SilentlyContinue |select -last 1).id
 #Get-Process -id $lastid  | Set-WindowState -State MINIMIZE
 
start-sleep -s $timeset

### show taskbar###

if($taskbarpara -match "show"){

    [KeySends.KeySend]::KeyDown("LWin")
    [KeySends.KeySend]::KeyDown("B")
    [KeySends.KeySend]::KeyUp("LWin")
    [KeySends.KeySend]::KeyUp("B")
    Start-Sleep -s 2
    [KeySends.KeySend]::KeyDown("LWin")
    [KeySends.KeySend]::KeyUp("LWin")
    Start-Sleep -s 2
    [KeySends.KeySend]::KeyDown("LWin")
    [KeySends.KeySend]::KeyUp("LWin")
     Start-Sleep -s 2
}

Start-Sleep -s 2

#$screens = [Windows.Forms.Screen]::AllScreens
#$width  = ([System.Windows.Forms.SystemInformation]::PrimaryMonitorSize|select Width).width
#$height = ([System.Windows.Forms.SystemInformation]::PrimaryMonitorSize|select Height).Height

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

$currentDPI = (Get-ItemProperty -Path "HKCU:\Control Panel\Desktop\WindowMetrics" -Name AppliedDPI).AppliedDPI

$dpisets=@(96,120,144,168)
$sclsets=@(100,125,150,175)

$index = $dpisets.IndexOf($currentDPI)
$calcu = $sclsets[$index] /100

$bounds.Width = $curwidth * $calcu
$bounds.Height = $curheight * $calcu

$bmp = New-Object System.Drawing.Bitmap($curwidth, $curheight)
$graphics = [System.Drawing.Graphics]::FromImage($bmp)
$graphics.CopyFromScreen($bounds.X, $bounds.Y, 0, 0, $bounds.Size)
$bmp.Save($picfile)
Start-Sleep -s 2
#$graphics.Dispose()
#$bmp.Dispose()

$Index=$picfile

if(test-path $picfile ){$results="OK"} else{$results="NG"}

if($nonlog_flag.Length -eq 0){

Get-Module -name "outlog"|remove-module
$mdpath=(Get-ChildItem -path "C:\testing_AI\modules\" -r -file |Where-object{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

#write-host "Do $action!"
outlog $action2 $results $tcnumber $tcstep $index
}

if($exit_flag.Length -ne 0){
exit
}

}

    export-modulemember -Function screenshot
