function taskschedule_attime_repeat{
param(
    [double] $para1,
    [double] $para2,
    [string] $para3,
    [string] $para4
    )
    

start-process cmd -ArgumentList '/c schtasks /delete /TN "Auto_Run" -f' 
start-sleep -s 5

<#
$user = "$env:userdomain\$env:USERNAME" 
$credentials = Get-Credential -Credential $username 
$password = $credentials.GetNetworkCredential().Password
#>

$paracheck1=$PSBoundParameters.ContainsKey('para1')
$paracheck2=$PSBoundParameters.ContainsKey('para2')
$paracheck3=$PSBoundParameters.ContainsKey('para3')
$paracheck4=$PSBoundParameters.ContainsKey('para4')


if($paracheck1 -eq $false -or  $para1 -eq 0 ){
$para1=5
}
if($paracheck2 -eq $false -or  $para2 -eq 0 ){
$para2=5

}
$bgset=$null
if($paracheck3 -eq $false  -or  $para3.length -eq 0 ){
$para3="na"

}
if($paracheck4 -eq $false -or  $para4 -eq 0 ){
$para4=""

}



$timeset=[double]$para1
$timeset2=[double]$para2
$bgset=$para3
$nonlog_flag=$para4


$action = New-ScheduledTaskAction -Execute "C:\testing_AI\AutoRun.bat"
$etime=(Get-Date).AddMinutes($timeset)
$trigger = New-ScheduledTaskTrigger -Once -At $etime  -RepetitionInterval ([TimeSpan]::FromMinutes($timeset2))
$Stset = New-ScheduledTaskSettingsSet -Priority 0 -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
$user=[System.Security.Principal.WindowsIdentity]::GetCurrent().Name

if($bgset -eq "na"){$STPrin= New-ScheduledTaskPrincipal   -User $user  -RunLevel Highest}
else{$STPrin= New-ScheduledTaskPrincipal   -User $user  -RunLevel Highest -LogonType S4U}

Register-ScheduledTask -Action $action -Trigger $trigger -Settings $Stset -Force -TaskName "Auto_Run" -Principal $STPrin

start-sleep -s 5


   $taskExists =Get-ScheduledTask | Where-Object {$_.TaskName -like "Auto_Run" } 
   if($taskExists){ $results  ="OK"} else{$results  ="NG"}

######## record log #######

if($PSScriptRoot.length -eq 0){
$scriptRoot="$env:USERPROFILE\desktop\Auto\Matagorda\testing_AI\modules\"
}
else{
$scriptRoot=$PSScriptRoot
}

$tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"

$tcnumber=((get-content $tcpath).split(","))[0]
$tcstep=((get-content $tcpath).split(","))[1]
$action="taskschedule setup - setup after $timeset mins and repeat every $timeset2 mins "
$Index="-"


if($nonlog_flag.Length -eq 0){

    Get-Module -name "outlog"|remove-module
    $mdpath=(gci -path "C:\testing_AI\modules\" -r -file |?{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
    Import-Module $mdpath -WarningAction SilentlyContinue -Global
    #write-host "Do $action!"
    outlog $action $results $tcnumber $tcstep $index
}

}




  export-modulemember -Function taskschedule_attime_repeat