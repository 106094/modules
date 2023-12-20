function taskschedule_waketorun{
param(
    [double] $para1,
    [string] $para2
    )
    

$paracheck1=$PSBoundParameters.ContainsKey('para1')
$paracheck2=$PSBoundParameters.ContainsKey('para2')

if($paracheck1 -eq $false -or  $para1 -eq 0){
$para1= 1
}
$bgset=$null
if($paracheck2 -eq $false  -or  $para2.length -eq 0 ){
$para2="na"
}

$timeset=[double]$para1
$bgset=$para2

start-process cmd -ArgumentList '/c schtasks /delete /TN "Auto_Run" -f' 
start-sleep -s 5

$action = New-ScheduledTaskAction -Execute "C:\testing_AI\AutoRun.bat"

$etime=(Get-Date).AddMinutes(1)
$TimeSpan = New-TimeSpan -Minutes ($timeset+3)
$TimeSpan2 = New-TimeSpan -Minutes ($timeset+10)

$etime=(Get-Date).AddMinutes(1)
$trigger = New-ScheduledTaskTrigger -Once -At $etime 
$Stset = New-ScheduledTaskSettingsSet -Priority 0 -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -WakeToRun -IdleDuration $TimeSpan -IdleWaitTimeout $TimeSpan2 -RunOnlyIfIdle
$user=[System.Security.Principal.WindowsIdentity]::GetCurrent().Name

if($bgset -eq "na"){$STPrin= New-ScheduledTaskPrincipal   -User $user  -RunLevel Highest}
else{$STPrin= New-ScheduledTaskPrincipal   -User $user  -RunLevel Highest -LogonType S4U}

Register-ScheduledTask -Action $action -Trigger $trigger -Settings $Stset -Force -TaskName "Auto_Run"  -Principal $STPrin

start-sleep -s 10

   $taskready =(Get-ScheduledTask | Where-Object {$_.TaskName -like "Auto_Run" } ).State
   if($taskready -eq "Ready"){ $results  ="OK"} else{$results  ="NG"}
   

if($PSScriptRoot.length -eq 0){
$scriptRoot="$env:USERPROFILE\desktop\Auto\Matagorda\testing_AI\modules\"
}
else{
$scriptRoot=$PSScriptRoot
}

$tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"

$tcnumber=((get-content $tcpath).split(","))[0]
$tcstep=((get-content $tcpath).split(","))[1]
$action="taskschedule setup - wake to run after $timeset mins"
$Index="-"

Get-Module -name "outlog"|remove-module
$mdpath=(gci -path "C:\testing_AI\modules\" -r -file |?{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

#write-host "Do $action!"
outlog $action $results $tcnumber $tcstep $index

}




  export-modulemember -Function taskschedule_waketorun