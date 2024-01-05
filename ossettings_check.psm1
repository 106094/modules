
function ossettings_check ([string]$para1,[string]$para2,[string]$para3){
      
    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force;
    $wshell=New-Object -ComObject wscript.shell
      Add-Type -AssemblyName Microsoft.VisualBasic
      Add-Type -AssemblyName System.Windows.Forms
      Add-Type -AssemblyName System.Windows.Forms,System.Drawing
      
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
     
$paracheck=$PSBoundParameters.ContainsKey('para1')

if( $paracheck -eq $false -or $para1.length -eq 0 ){
#write-host "no defined, setting 1 min after login"
$para1="start ms-settings:"
}
    $checkosset=$para1
    $keyword=$para2
    $nonlog_flag=$para3

### OS settings: start ms-settings:
### ms-settings:windowsupdate
### ms-settings:activation
## https://4sysops.com/wiki/list-of-ms-settings-uri-commands-to-open-specific-settings-in-windows-10/#:~:text=Press%20Win%2BR%20to%20open,type%20the%20ms%2Dsettings%20command


if($PSScriptRoot.length -eq 0){
$scriptRoot="C:\testing_AI\modules"
}
else{
$scriptRoot=$PSScriptRoot
}

$tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
$tcnumber=((get-content $tcpath).split(","))[0]
$tcstep=((get-content $tcpath).split(","))[1]
$action="ossettings_check-$checkosset"

$actionmd ="screenshot"
Get-Module -name $actionmd|remove-module
$mdpath=(get-childitem -path $scriptRoot -r -file |where-object{$_.name -match "^$actionmd\b" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

if($checkosset -match "coreiso"){
$processname = "SecHealthUI"
$explorerpath="windowsdefender://coreisolation"
}

if($checkosset -match "windowsupdate"){
$processname = "SystemSettings"
$explorerpath="ms-settings:windowsupdate"
}
if($checkosset -match "activation"){
$processname = "SystemSettings"
$explorerpath="ms-settings:activation"
}
if($checkosset -match "installedapp"){
$processname = "SystemSettings"
$explorerpath="ms-settings:appsfeatures"
}
if($checkosset -match "accounts"){
$processname = "SystemSettings"
$explorerpath="ms-settings:yourinfo"
}


Start-Process $explorerpath -Verb Open -WindowStyle Maximized
start-sleep -s 10

$wid=(Get-Process ApplicationFrameHost |Sort-Object starttime|Select-Object -Last 1 ).Id
$wshell.AppActivate($wid)

 Get-Process -id $wid  | Set-WindowState -State MAXIMIZE

 if($explorerpath -eq "ms-settings:appsfeatures"){
    [System.Windows.Forms.SendKeys]::Sendwait($keyword)
    start-sleep -s 5
    [System.Windows.Forms.SendKeys]::Sendwait("{TAB 3}")
    start-sleep -s 5
    [System.Windows.Forms.SendKeys]::Sendwait($keyword)
 }


start-sleep -s 3

### screenshot""

#$timenow=get-date -format "yyMMdd_HHmmss"
#$picpath=(Split-Path -Parent $scriptRoot)+"\logs\screenshot\"
$picpath=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\"
if(-not(test-path $picpath)){new-item -ItemType directory -path $picpath |out-null}

## screen shot ##

&$actionmd  -para3 nonlog -para5 $checkosset

stop-process  -name $processname -Force

$picfile=(get-childitem $picpath |where-object{$_.name -match ".jpg" -and $_.name -match $checkosset }).FullName

if($picfile ){$results="OK"} else{$results="NG"}
 
 $Index="check screenshots"
######### write log  #######

if($nonlog_flag.Length -eq 0){
Get-Module -name "outlog"|remove-module
$mdpath=(get-childitem -path "C:\testing_AI\modules\"  -r -file |where-object{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

#write-host "Do $action!"
outlog $action $results $tcnumber $tcstep $index

  }

  }

  
    export-modulemember -Function ossettings_check