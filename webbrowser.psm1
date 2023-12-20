
function webbrowser ([string]$para1,[int]$para2,[string]$para3){

Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force;
 $checkdouble=(get-process cmd*).HandleCount.count
  Add-Type -AssemblyName Microsoft.VisualBasic
  Add-Type -AssemblyName System.Windows.Forms
  $shell=New-Object -ComObject shell.application
    $wshell=New-Object -ComObject wscript.shell

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

$paracheck1=$PSBoundParameters.ContainsKey('para1')
$paracheck2=$PSBoundParameters.ContainsKey('para2')
$paracheck3=$PSBoundParameters.ContainsKey('para3')

if( $paracheck1 -eq $false -or $para1.length -eq 0 ){
#write-host "no defined, setting 1 min after login"
$para1="www.google.com"
}

if( $paracheck2 -eq $false -or $para2 -eq 0 ){
#write-host "no defined, setting 1 min after login"
$para2=10
}

if( $paracheck3 -eq $false -or $para3.length -eq 0 ){
#write-host "no defined, setting 1 min after login"
$para3="close"
}


$address=[string]$para1
$timeofscreenshout=[int]$para2
$closeorleaveit=[string]$para3

if($PSScriptRoot.length -eq 0){
$scriptRoot="C:\testing_AI\modules"
}
else{
$scriptRoot=$PSScriptRoot
}

$tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
$tcnumber=((get-content $tcpath).split(","))[0]
$tcstep=((get-content $tcpath).split(","))[1]
$action=((get-content $tcpath).split(","))[2]
$timenow=get-date -format "yyMMdd_HHmmss"
#$picpath=(Split-Path -Parent $scriptRoot)+"\logs\screenshot\"
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

### skip edge initialization solution ####
Start-Process msedge.exe 
  start-sleep -s 10
 (get-process -name msedge).CloseMainWindow() 
   start-sleep -s 5

## start ##
Start-Process msedge.exe $address
Start-Sleep -s 10
[Microsoft.VisualBasic.interaction]::AppActivate("edge")|out-null
(Get-Process -name "msedge" )|?{$_.MainWindowHandle -ne 0} | Set-WindowState -State  MAXIMIZE


#$screens = [Windows.Forms.Screen]::AllScreens

#$width  = ([System.Windows.Forms.SystemInformation]::PrimaryMonitorSize|select Width).width
#$height = ([System.Windows.Forms.SystemInformation]::PrimaryMonitorSize|select Height).Height
#$width  = (([string]::Join("`n", (wmic path Win32_VideoController get CurrentHorizontalResolution))).split("`n") -match "\d{1,}")[0]
#$height  = (([string]::Join("`n", (wmic path Win32_VideoController get CurrentVerticalResolution))).split("`n") -match "\d{1,}")[0]

if([int64]($width.trim()) -lt 1920 -and [int64]($height.trim()) -lt 1080){

[Microsoft.VisualBasic.interaction]::AppActivate("edge")|out-null
[System.Windows.Forms.SendKeys]::SendWait("^{-}") 
[System.Windows.Forms.SendKeys]::SendWait("^{-}") 
[System.Windows.Forms.SendKeys]::SendWait("^{-}") 
Start-Sleep -s 5
}


if($timeofscreenshout -ne 0){

start-sleep $timeofscreenshout

&$actionss  -para3 nonlog
$picfile=(gci $picpath |?{$_.name -match ".jpg"} |sort lastwritetime|select -Last 1).FullName

}

if([int64]($width.trim()) -lt 1920 -and [int64]($height.trim()) -lt 1080){
[Microsoft.VisualBasic.interaction]::AppActivate("edge")|out-null

[System.Windows.Forms.SendKeys]::SendWait("^{+}") 
[System.Windows.Forms.SendKeys]::SendWait("^{+}") 
[System.Windows.Forms.SendKeys]::SendWait("^{+}") 
Start-Sleep -s 5
}


######### write log #######

$action="webbrowser (with scrennshot)"

if($timeofscreenshout -ne 0){
$results="check pictures"
$index=$picfile
}
else{
$results=""
$index=""
}

Get-Module -name "outlog"|remove-module
$mdpath=(gci -path "C:\testing_AI\modules\"  -r -file |?{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

#write-host "Do $action!"
outlog $action $results $tcnumber $tcstep $index


if($closeorleaveit -match "close" -or $closeorleaveit.Length -eq 0){

if((get-process).name -match "msedge"){
(get-process "msedge" -ea SilentlyContinue).CloseMainWindow()}

start-sleep 3

if((get-process).name -match "msedge"){
stop-process -name "msedge"}

}


  }

    export-modulemember -Function  webbrowser