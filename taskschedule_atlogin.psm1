
function taskschedule_atlogin{

param(
    [double] $para1,
    [string] $para2,
    [string] $para3
    )
    
start-process cmd -ArgumentList '/c schtasks /delete /TN "Auto_Run" -f' 
start-sleep -s 5

#$PSBoundParameters
$paracheck=$PSBoundParameters.ContainsKey('para1')
$paracheck2=$PSBoundParameters.ContainsKey('para2')

if( $paracheck -eq $false -or $para1 -eq 0 ){
#write-host "no defined, setting 1 min after login"
$para1=1
}

if($paracheck2 -eq $false  -or  $para2.length -eq 0 ){
$para2="na"
}


$timeset=[double]$para1
$bgset=$para2
$nonlog_flag=$para3

$TimeSpan = New-TimeSpan -Minutes $timeset
$action = New-ScheduledTaskAction -Execute "C:\testing_AI\AutoRun.bat"
$trigger = New-JobTrigger -AtLogOn -RandomDelay $TimeSpan #00:05:00
$Stset = New-ScheduledTaskSettingsSet -Priority 0 -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
$user=[System.Security.Principal.WindowsIdentity]::GetCurrent().Name

if($bgset -eq "na"){$STPrin= New-ScheduledTaskPrincipal   -User $user  -RunLevel Highest}
else{$STPrin= New-ScheduledTaskPrincipal   -User $user  -RunLevel Highest -LogonType S4U}

Register-ScheduledTask -Action $action -Trigger $trigger -Settings $Stset -Force -TaskName "Auto_Run" -Principal $STPrin

   start-sleep -s 10

   $taskready =(Get-ScheduledTask | Where-Object {$_.TaskName -like "Auto_Run" } ).State
   if($taskready -eq "Ready"){ $results  ="OK"} else{$results  ="NG"}
   
if($PSScriptRoot.length -eq 0){$PSScriptRoot="$env:USERPROFILE\desktop\Auto\Matagorda\testing_AI\modules"}
$tcpath=(Split-Path -Parent $PSScriptRoot)+"\currentjob\TC.txt"
$tcnumber=((get-content $tcpath).split(","))[0]
$tcstep=((get-content $tcpath).split(","))[1]
$action="taskschedule setup - after login $timeset mins"
$Index="-"

if($nonlog_flag.length -eq 0){

Get-Module -name "outlog"|remove-module
$mdpath=(gci -path "C:\testing_AI\modules\" -r -file |?{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

#write-host "Do $action!"
outlog $action $results $tcnumber $tcstep $index
}

}





  export-modulemember -Function taskschedule_atlogin