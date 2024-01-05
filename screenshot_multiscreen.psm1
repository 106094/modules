
function screenshot_multiscreen([int]$para1,[string]$para2,[string]$para3,[string]$para4,[string]$para5){

    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force;
    $wshell=New-Object -ComObject wscript.shell
       Add-Type -AssemblyName System.Windows.Forms,System.Drawing,Microsoft.VisualBasic
       

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

function screenshotmulti ($path) {

    [void] [Reflection.Assembly]::LoadWithPartialName("System.Drawing")
    [void] [Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
    $left = [Int32]::MaxValue
    $top = [Int32]::MaxValue
    $right = [Int32]::MinValue
    $bottom = [Int32]::MinValue

    foreach ($screen in [Windows.Forms.Screen]::AllScreens)
    {
        if ($screen.Bounds.X -lt $left)
        {
            $left = $screen.Bounds.X;
        }
        if ($screen.Bounds.Y -lt $top)
        {
            $top = $screen.Bounds.Y;
        }
        if ($screen.Bounds.X + $screen.Bounds.Width -gt $right)
        {
            $right = $screen.Bounds.X + $screen.Bounds.Width;
        }
        if ($screen.Bounds.Y + $screen.Bounds.Height -gt $bottom)
        {
            $bottom = $screen.Bounds.Y + $screen.Bounds.Height;
        }
    }

    $bounds = [Drawing.Rectangle]::FromLTRB($left, $top, $right, $bottom);
    $bmp = New-Object Drawing.Bitmap $bounds.Width, $bounds.Height;
    $graphics = [Drawing.Graphics]::FromImage($bmp);

    $graphics.CopyFromScreen($bounds.Location, [Drawing.Point]::Empty, $bounds.size);

    $bmp.Save($path);

    $graphics.Dispose();
    $bmp.Dispose();
}


$paracheck1=$PSBoundParameters.ContainsKey('para1')
$paracheck2=$PSBoundParameters.ContainsKey('para2')
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
   if($picnameindex.length -gt 0){$picfile=$picpath+"$($tcstep)_$($action2)_$($picnameindex).jpg"}


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
    Start-Sleep -s 1
    [KeySends.KeySend]::KeyDown("LWin")
    [KeySends.KeySend]::KeyUp("LWin")
    Start-Sleep -s 1
    [KeySends.KeySend]::KeyDown("LWin")
    [KeySends.KeySend]::KeyUp("LWin")
     Start-Sleep -s 2
}

Start-Sleep -s 2

<#


   $picfile="$($tcstep)_$($action2)"
   if($picnameindex.length -gt 0){$picfile="$($tcstep)_$($action2)_$($picnameindex)"}


$load1=[void] [Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
$load2=[Reflection.Assembly]::LoadWithPartialName("System.Drawing")
$screens = [system.windows.forms.screen]::AllScreens
$moct=0

foreach($screen in $screens){

  $bounds=$Screen.Bounds
  
   $bmp = New-Object Drawing.Bitmap $bounds.width, $bounds.height
   $graphics = [Drawing.Graphics]::FromImage($bmp)

   $graphics.CopyFromScreen($bounds.Location, [Drawing.Point]::Empty, $bounds.size)

   
   $timenow=get-date -format "yyMMdd_HHmmss"

   if($Screen.Primary -eq $true){$picfile= $picpath+"$($timenow)_$picfile_#Pri#"+$moct+".jpg"}
   else{$picfile= $picpath+"$($timenow)_#"+$moct+".jpg"}
  
   Start-Sleep -s 2
   $bmp.Save($picfile)

   $graphics.Dispose()
   $bmp.Dispose()
   Start-Sleep -s 2

   $moct++
   $Indexa=$Indexa+@($picfile)
   
}
#>

screenshotmulti $picfile

Start-Sleep -s 2

$results="NG"
$Index="check screenshots"

if(test-path $picfile){
$results="OK"
$Index=$picfile
}

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

    export-modulemember -Function screenshot_multiscreen
