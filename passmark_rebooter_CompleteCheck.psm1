function passmark_rebooter_CompleteCheck {

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


$action="Passmark Rebooter job completed"
$tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
$tcnumber=((get-content $tcpath).split(","))[0]
$tcstep=((get-content $tcpath).split(","))[1]

$picpath=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\"
if(-not(test-path $picpath)){new-item -ItemType directory -path $picpath |out-null}

    $actionss ="screenshot"
    Get-Module -name $actionss|remove-module
    $mdpath=(Get-ChildItem -path $scriptRoot -r -file |Where-object{$_.name -match "^$actionss\b" -and $_.name -match "psm1"}).fullname
    Import-Module $mdpath -WarningAction SilentlyContinue -Global

 $doneflag=$null

if(test-path "$env:HOMEPATH\Documents\PassMark\Rebooter\Rebooter.log"){
 $checkdone= get-content $env:HOMEPATH\Documents\PassMark\Rebooter\Rebooter.log
 if(  $checkdone -match "FINISHED REBOOT CYCLE"){
 $doneflag="done"
 $backuplogtime=Get-Date((Get-ChildItem $env:HOMEPATH\\Documents\PassMark\Rebooter\Rebooter.log).LastWriteTime) -Format "yyMMdd_HHmm"
 #$logpath=(Split-Path -Parent $scriptRoot)+"\logs\Rebooter\"
 $logpath=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\Rebooter\"
 $newlogname=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\Rebooter\Rebooter_TC$($tcnumber)_$($tcstep)_$($backuplogtime).log"
 if(-not(test-path $logpath)){new-item -ItemType directory $logpath -Force |Out-Null}
copy-Item -Path "$env:HOMEPATH\Documents\PassMark\Rebooter\Rebooter.log"  $newlogname -Force

$rblog=get-content $newlogname

$newlogs=$null
$lasttime=$null
$lastcount=999999

$newlogname2="$($logpath)rebooter_check.csv"
$newlogname3="$($logpath)rebooter_check2.csv"

set-content $newlogname2 -value {"raw","Count","logtime","countseconds","timegap"}
set-content $newlogname3 -value {"raw","Count","logtime","countseconds","timegap"}

$rblog|%{

if($_ -match "STARTING COUNTDOWN" -or $_ -match "LAST REBOOT" ){
#$_

$count=$_.split(" ")[-1]

$datetime=$_.split(" ")[1]+" "+$_.split(" ")[2]

if([int]$count -gt [int]$lastcount){

if($lasttime -ne $null){
$timegap=New-TimeSpan -Start $lasttime -End $datetime
$timegap2="$(($timegap.Minutes)) : $(($timegap.Seconds))"
$timegaps=$timegap.TotalSeconds

}
else{$timegap2="-";$timegaps=0}


#echo "$(($timegap.Minutes)) : $(($timegap.Seconds))"

$newlogs=$newlogs+@( 
   [pscustomobject]@{
       
       raw=$_
       Count=$count
       logtime=$datetime
       countseconds=$timegaps
       timegap= $timegap2

       }
       )

}

}

$lastcount=$count

$lasttime=$datetime
}

$newlogs| export-csv -path $newlogname2 -Encoding OEM -NoTypeInformation -Append
    
$newlogs|sort  countseconds -Descending  | export-csv -path $newlogname3 -Encoding OEM -NoTypeInformation -Append


 }
}

if( $doneflag -ne "done"){
exit
}

if($wshell.AppActivate('Rebooter - Final Reboot Complete') -eq $true ){



### screentshot ###

$lastid=  (Get-Process cmd |sort StartTime -ea SilentlyContinue |select -last 1).id
 Get-Process -id $lastid  | Set-WindowState -State MINIMIZE

 ##screenshot##
&$actionss  -para3 nonlog

### close message box ###

 $wshell.AppActivate('Rebooter - Final Reboot Complete')
  start-sleep -s 1
 $wshell.SendKeys("~")
 start-sleep -s 2
 ### close rebooter window ###

if($wshell.AppActivate('PassMark Rebooter') -eq $true ){
 
 $wshell.AppActivate('PassMark Rebooter') 
   start-sleep -s 1
  $wshell.SendKeys("%{F4}")
    start-sleep -s 2
  if( $wshell.AppActivate('PassMark Rebooter') -eq $false){
  $results="OK"
  $index= $newlogname

  }

}

}

else{
exit
}

### write log ##


Get-Module -name "outlog"|remove-module
$mdpath=(Get-ChildItem -path "C:\testing_AI\modules\" -r -file |Where-object{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

#write-host "Do $action!"
outlog $action $results  $tcnumber $tcstep $index

}


  
    export-modulemember -Function passmark_rebooter_CompleteCheck