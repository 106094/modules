function unigine_valley_end {

Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force
 $wshell = New-Object -com WScript.Shell
  Add-Type -AssemblyName Microsoft.VisualBasic
     Add-Type -AssemblyName System.Windows.Forms

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

if($PSScriptRoot.length -eq 0){
$scriptRoot="C:\testing_AI\modules"
}
else{
$scriptRoot=$PSScriptRoot
}

$lastid=  (Get-Process cmd |sort StartTime -ea SilentlyContinue |select -last 1).id
 Get-Process -id $lastid  | Set-WindowState -State MINIMIZE

$action="unigine_valley_end"
$tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
$tcnumber=((get-content $tcpath).split(","))[0]
$tcstep=((get-content $tcpath).split(","))[1]

#$width  = ([string]::Join("`n", (wmic path Win32_VideoController get CurrentHorizontalResolution))).split("`n") -match "\d{1,}"|select -First 1
#$height  = ([string]::Join("`n", (wmic path Win32_VideoController get CurrentVerticalResolution))).split("`n") -match "\d{1,}"|select -First 1
$picpath=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\"
if(-not(test-path $picpath)){new-item -ItemType directory -path $picpath |out-null}
 
$actionss ="screenshot"
Get-Module -name $actionss|remove-module
$mdpath=(gci -path $scriptRoot -r -file |?{$_.name -match "^$actionss\b" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

$screen = [System.Windows.Forms.Screen]::PrimaryScreen
$bounds = $screen.Bounds
$width=$bounds.Width
$height=$bounds.Height


##### screenshot *2 ###

<##### screenshot *2 by F12###
 $pngfile=(gci -path "$env:USERPROFILE/valley/screenshots").fullname
 $id2=(Get-Process -name Valley).Id
  $id2title=(Get-Process -name Valley).MainWindowTitle
 Get-Process -id $id2 | Set-WindowState -State MAXIMIZE
 start-sleep -s 10
  $wshell.AppActivate($id2title)
   start-sleep -s 5 
[System.Windows.Forms.SendKeys]::SendWait("{F12}")
  $timenow=get-date -format "yyMMdd_HHmmss"
      start-sleep -s 10
  $picfile1=$($picpath)+"$($timenow)-$($tcnumber)-$($tcstep)-$($action)-1.jpg"
  [System.Windows.Forms.SendKeys]::SendWait("{F12}")
  $timenow=get-date -format "yyMMdd_HHmmss"
   start-sleep -s 10
    $picfile2=$($picpath)+"$($timenow)-$($tcnumber)-$($tcstep)-$($action)-2.jpg"    
 $pngfile1=((gci -path "$env:USERPROFILE/valley/screenshots")|sort LastWriteTime|select -last 2|select -first 1).fullname
  $pngfile2=((gci -path "$env:USERPROFILE/valley/screenshots")|sort LastWriteTime|select -last 1).fullname  
  $picfile=""
  if( $pngfile -ne 0 -and  $pngfile1 -notin  $pngfile){ copy-item $pngfile1 $picfile1 -Force; $picfile=$picfile1}
  if( $pngfile -ne 0 -and  $pngfile2 -notin  $pngfile){ copy-item $pngfile2 $picfile2 -Force; $picfile=$picfile1+"`n"+$picfile2}
##### screenshot *2 by F12###>
  
  #$vid= (Get-Process -name "valley").Id
#$wshell.AppActivate($vid)
  
  start-sleep -s 10
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

##### screen shot by Windows ###
&$actionss  -para3 nonlog -para5 "1"
$picfile1=(gci $picpath |?{$_.name -match ".jpg"} |sort lastwritetime|select -Last 1).FullName
start-sleep -s 10

&$actionss  -para3 nonlog -para5 "2"
$picfile2=(gci $picpath |?{$_.name -match ".jpg"} |sort lastwritetime|select -Last 1).FullName 

$picfile=[string]::join("`n",$picfile1,$picfile2)
### close unigine valley benchmark ###

 $id2=(Get-Process -name Valley).Id
  $id2title=(Get-Process -name Valley).MainWindowTitle

if( $wshell.AppActivate($id2title) -eq $true ){
   start-sleep -s 2
  $wshell.SendKeys("%{F4}")
}

$i=0
do{
  start-sleep -s 2
 $id2=(Get-Process -name Valley -ea SilentlyContinue).Id 
 $i++
 }until ( $id2 -eq $null -or $i -gt 30)

 
 $id3=(get-process -name browser_x86).Id
  $id3title=(Get-Process -name browser_x86).MainWindowTitle

if( $wshell.AppActivate($id3title) -eq $true ){
   start-sleep -s 2
  $wshell.SendKeys("%{F4}")
}

$j=0
do{
  start-sleep -s 2
  $id3=(get-process -name browser_x86).Id
 $j++
 }until ( $id3 -eq $null -or $j -gt 30)

 if($i -le 30 -and $j -le 30){$results="chceck screenshot"}
 else{$results="NG - window not closed"}
 
 $index=$picfile

###### move js file back  ###

move-item "C:\testing_AI\settings\valley-ui-logic.js" "C:\Program Files (x86)\Unigine\Valley Benchmark 1.0\data\launcher\js\valley-ui-logic.js"-Force

start-sleep -s 2

### close ###

 taskkill /IM browser_x86.exe /F 

### write log ##

Get-Module -name "outlog"|remove-module
$mdpath=(gci -path "C:\testing_AI\modules\" -r -file |?{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

#write-host "Do $action!"
outlog $action $results  $tcnumber $tcstep $index


}


  
    export-modulemember -Function unigine_valley_end