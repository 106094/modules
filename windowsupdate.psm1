
function windowsupdate {
    
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


$action="windowsupdate"
$tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
$tcnumber=((get-content $tcpath).split(","))[0]
$tcstep=((get-content $tcpath).split(","))[1]
$picpath=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\"
if(-not(test-path $picpath)){new-item -ItemType directory -path $picpath |out-null}
$log1=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\$($tcstep)_checkwu.txt"
$log2=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\$($tcstep)_checkhotfox.txt"
$log3=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\$($tcstep)_windowsupdatelog.txt"
if(!(test-path $log1)){new-item -path $log1|out-null}
if(!(test-path $log2)){new-item -path $log2|out-null}
if(!(test-path $log3)){new-item -path $log3|out-null}
#Set-PSRepository -Name PSGallery -installationPolicy Trusted
#Install-Module PSWindowsUpdate  -WarningAction Continue
#get-WindowsUpdate|set-content $log1 
#get-hotfix|set-content $log2
#Install-WindowsUpdate -MicrosoftUpdate -AcceptAll -AutoReboot
  
$func="enable_wu"
Get-Module -name $func|remove-module
$mdpath=(Get-ChildItem -path $scriptRoot -r -file |Where-object{$_.name -match "^$func\b" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

$func_dw="disable_wu"
Get-Module -name $func_dw|remove-module
$mdpath=(Get-ChildItem -path $scriptRoot -r -file |Where-object{$_.name -match "^$func_dw\b" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

$func_pcai="pcai"
Get-Module -name $func_pcai|remove-module
$mdpath=(Get-ChildItem -path $scriptRoot -r -file |Where-object{$_.name -match "^$func_pcai\b" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global


#close oobe
stop-process -name WWAHost -Force -ErrorAction SilentlyContinue
stop-process -name WebExperienceHostApp -Force -ErrorAction SilentlyContinue


&$func -para1 "nonlog"
start-sleep -s 5


if($checkoobe){

$actionss="screenshot"
Get-Module -name $actionss|remove-module
$mdpath=(Get-ChildItem -path $scriptRoot -r -file |Where-object{$_.name -match "^$actionss\b" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

&$actionss  -para3 nonlog -para5 "oobe"
stop-process -name WWAHost -Force
&$actionss  -para3 nonlog -para5 "oobe_close"

}

Start-Process ms-settings:windowsupdate
start-sleep -s 10

Get-Process -id (get-process -name ApplicationFrameHost).Id | Set-WindowState -State MAXIMIZE
start-sleep -s 10

&$func_pcai -para1 mssettings_wu_new -para4 nc -para5 nolog

stop-process -Name SystemSettings -Force

$checkwudone=Get-ChildItem $picpath -file -r |Where-object{$_.name -match "wucheck_finish" -and $_.name -match ".png"}
$checkwurun=Get-ChildItem $picpath -file -r |Where-object{$_.name -match "wucheck_running" -and $_.name -match ".png"}

### command to update ##
if(!$checkwudone -and $checkwurun.count -lt 4){
Copy-Item C:\testing_AI\modules\pswindowsupdate -Destination "$env:ProgramFiles\WindowsPowerShell\Modules" -Recurse -force
#Install-Module PSWindowsUpdate  -WarningAction Continue
$windowsupdatecmd=Install-WindowsUpdate -MicrosoftUpdate -AcceptAll -AutoReboot
$windowsupdatelog=$windowsupdatecmd|out-string
get-date|add-content $log3
$windowsupdatelog|add-content $log3
start-sleep -Seconds 10
 Restart-Computer -Force
}
else{
get-WindowsUpdate|Out-String|add-content $log1 
get-hotfix|Out-String|add-content $log2
$results="OK"
$index="windwosupdate completed, check pcai results and logs"
$timenow=get-date -format "yyMMdd_HHmmss"
$newname1=$($timenow)+"_"+$(Get-ChildItem $log1).Name
$newname2=$($timenow)+"_"+$(Get-ChildItem $log2).Name
$newname3=$($timenow)+"_"+$(Get-ChildItem $log3).Name
rename-item -path $log1 -newname $newname1
rename-item -path $log2 -newname $newname2
rename-item -path $log3 -newname $newname3
}
#get-WindowsUpdate
#get-hotfix

## update end

&$func_dw -para1 "nonlog"
start-sleep -s 5

######### write log #######

Get-Module -name "outlog"|remove-module
$mdpath=(Get-ChildItem -path "C:\testing_AI\modules\"  -r -file |Where-object{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

#write-host "Do $action!"
outlog $action $results $tcnumber $tcstep $index


  }

    export-modulemember -Function windowsupdate