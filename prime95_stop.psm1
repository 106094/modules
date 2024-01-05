function prime95_stop {

Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force
 $wshell = New-Object -com WScript.Shell
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


$lastid=  (Get-Process cmd |sort StartTime -ea SilentlyContinue |select -last 1).id
 Get-Process -id $lastid  | Set-WindowState -State MINIMIZE

$action="prime95_check"
$tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
$tcnumber=((get-content $tcpath).split(","))[0]
$tcstep=((get-content $tcpath).split(","))[1]

$timenow=get-date -format "yyMMdd_HHmm"
#$picpath=(Split-Path -Parent $scriptRoot)+"\logs\screenshot\"
$picpath=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\"
#$logpath=(Split-Path -Parent $scriptRoot)+"\logs\prime95\"
$logpath=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\prime95\"
if(-not(test-path $picpath)){new-item -ItemType directory -path $picpath |out-null}
#$picfile=$picpath+"$timenow-$tcnumber-$tcstep-$action.jpg"
$logfile=$logpath+"$($timenow)-$($tcnumber)-$($tcstep)-$($action)_result.txt"
if(-not(test-path $picpath)){new-item -ItemType directory $picpath |out-null}
if(-not(test-path $logpath)){new-item -ItemType directory $logpath |out-null}

    $actionss ="screenshot"
    Get-Module -name $actionss|remove-module
    $mdpath=(Get-ChildItem -path $scriptRoot -r -file |?{$_.name -match "^$actionss\b" -and $_.name -match "psm1"}).fullname
    Import-Module $mdpath -WarningAction SilentlyContinue -Global

### stop prime95 ###

if( $wshell.AppActivate('Prime95') -eq $true ){
   start-sleep -s 1
  $wshell.SendKeys("%")
    start-sleep -s 2
  $wshell.SendKeys("T")
    start-sleep -s 2
  $wshell.SendKeys("o")
    start-sleep -s 5
    if( $wshell.AppActivate('Stop one or all workers') -eq $true ){
  $wshell.SendKeys("~")
    start-sleep -s 2
    }

}


### screentshot ###

 &$actionss  -para3 nonlog

### close prime95 ###

$index=$null

if( $wshell.AppActivate('Prime95') -eq $true ){
   start-sleep -s 1
  $wshell.SendKeys("%")
    start-sleep -s 2
  $wshell.SendKeys("T")
    start-sleep -s 2
  $wshell.SendKeys("x")
    start-sleep -s 5
    if( $wshell.AppActivate('Stop one or all workers') -eq $true ){
  $wshell.SendKeys("~")
    start-sleep -s 2
    }

}

start-sleep -s 2
$results="Pass"
$index=$logfile

$content=get-content "C:\testing_AI\modules\BITools\Prime95\results.txt"

if($content -match "fail"){
 $results="Fail"
   foreach($line in $content){
    if($line -match "fail" ){
      $index=$index+"`n"+$line
        }
   }
    $index= $index.trim()
   }

   copy-item "C:\testing_AI\modules\BITools\Prime95\results.txt" $logfile -Force

### write log ##

Get-Module -name "outlog"|remove-module
$mdpath=(Get-ChildItem -path "C:\testing_AI\modules\" -r -file |?{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

#write-host "Do $action!"
outlog $action $results  $tcnumber $tcstep $index


}




  
    export-modulemember -Function prime95_stop