
function controlpanel_superposition {
    
    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force;
    $wshell=New-Object -ComObject wscript.shell
      Add-Type -AssemblyName Microsoft.VisualBasic
      Add-Type -AssemblyName System.Windows.Forms

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


$pcaimd="pcai"
Get-Module -name $pcaimd|remove-module
$mdpath=(Get-ChildItem -path $scriptRoot -r -file |Where-object{$_.name -match "^$pcaimd\b" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

$tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
$tcnumber=((get-content $tcpath).split(","))[0]
$tcstep=((get-content $tcpath).split(","))[1]

$path_setting1="C:\ProgramData\NVIDIA Corporation\Drs"
$path_setting2=(Get-ChildItem "$env:userprofile\AppData\Local\Packages\NVIDIACorp*\SystemAppData\Helium\" -directory).fullname
$path_run=(Get-ChildItem "C:\Program Files\WindowsApps\NVIDIACorp.NVIDIAControlPane*\" -directory).fullname
 
### find the system gfx model ##
 $drvname=((Get-WmiObject Win32_VideoController | Select-Object name|Where-object{$_.name -match "NVIDIA"} ).name)[0]

 if( $drvname){
 
$action="NVControlpanelSettings"

## pcai nv_controlpanel_start

&$pcaimd -para1 nv_controlpanel_start -para4 nc -para5 nolog

### copy settigns ##
$settingf1=(Get-ChildItem C:\testing_AI\settings\nv_Controlpanel\$drvname\* -file).fullname
$settingf1| %{Copy-Item $_ -Destination $path_setting1 -Force }

#$settingf2=(Get-ChildItem C:\testing_AI\settings\nv_Controlpanel\$drvname\SystemAppData\Helium\* -file).fullname
#$settingf2| %{Copy-Item $_ -Destination $path_setting2 -Force }
#set-location $path_run
#start-process .\nvcplui.exe -WindowStyle Maximized
#start-sleep -s 10

## pcai nv_controlpanel_check
&$pcaimd -para1 nv_controlpanel_check -para4 nc -para5 nolog

}
else{
## amd
$action="AMDControlpanelSettings"

$startmenuappmd="startmenuapp"
Get-Module -name $startmenuappmd|remove-module
$mdpath=(Get-ChildItem -path $scriptRoot -r -file |Where-object{$_.name -match "^$startmenuappmd\b" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

&$startmenuappmd -para1 "AMD software" -para3 nonlog

#Set-Window -processname RadeonSoftware -x 0 -y 0
$idamd=(get-process -name RadeonSoftware).Id

 Get-Process -id $idamd | Set-WindowState -State MAXIMIZE

&$pcaimd -para1 amdcontrol_panel -para4 nc -para5 nolog

}

$results="-"
$index="check pcai steps"

######### write log #######

Get-Module -name "outlog"|remove-module
$mdpath=(Get-ChildItem -path "C:\testing_AI\modules\"  -r -file |Where-object{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

#write-host "Do $action!"
outlog $action $results $tcnumber $tcstep $index


  }

    export-modulemember -Function controlpanel_superposition