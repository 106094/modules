
function runtc13513([double]$para1,[string]$para2){

Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force
 $wshell = New-Object -com WScript.Shell
  Add-Type -AssemblyName Microsoft.VisualBasic
     Add-Type -AssemblyName System.Windows.Forms

$paracheck1=$PSBoundParameters.ContainsKey('para1')
$paracheck2=$PSBoundParameters.ContainsKey('para2')

if($paracheck1 -eq $false){
$para1="10"
}
if($paracheck2 -eq $false -or $para2.Length -eq 0){
[System.Windows.Forms.MessageBox]::Show($this,"No command line defined, tool stops!")   
exit
}


$min=[double]$para1
$cmd=$para2

 $startflag="C:\testing_AI\logs\wait.txt"

if(-not (Test-Path $startflag)){
$endtime=(get-date).AddMinutes($min)
$recordtime= (get-date).ToString()
New-Item -path  $startflag  -value "TC13513 cycling start from $($recordtime)" -Force |out-null

$timeset=[double]$para1
$TimeSpan = New-TimeSpan -Minutes 1
$action = New-ScheduledTaskAction -Execute "C:\testing_AI\AutoRun.bat"
$trigger = New-JobTrigger -AtLogOn -RandomDelay $TimeSpan #00:05:00
$Stset = New-ScheduledTaskSettingsSet -Priority 0 -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
$STPrin= New-ScheduledTaskPrincipal   -User "$env:USERDOMAIN\$env:USERNAME"  -RunLevel Highest
Register-ScheduledTask -Action $action -Trigger $trigger -Settings $Stset -Force -TaskName "Auto_Run" -Principal $STPrin

}

$starttime=(Get-ChildItem  $startflag).CreationTime
$timegap= (NEW-TIMESPAN –Start $starttime –End (get-date)).TotalMinutes

#$now=get-date
if($timegap -gt $min){

#[System.Windows.Forms.MessageBox]::Show($this,"tc13513 Complete!")

######### write log #######

if($PSScriptRoot.length -eq 0){
$scriptRoot="C:\testing_AI\modules"
}
else{
$scriptRoot=$PSScriptRoot
}

$tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
$tcnumber=((get-content $tcpath).split(","))[0]
$tcstep=((get-content $tcpath).split(","))[1]


$index=get-content $startflag
$results="OK"

Get-Module -name "outlog"|remove-module
$mdpath=(Get-ChildItem -path "C:\testing_AI\modules\"  -r -file |Where-object{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

#write-host "Do $action!"
outlog $action $results $tcnumber $tcstep $index

start-process cmd -ArgumentList '/c schtasks /delete /TN "Auto_Run" -f' 
Remove-Item $startflag -Force

}
else{
$cmd_location=Split-Path $cmd
set-location $cmd_location
$cmd2=$cmd.replace($cmd_location,".")
&$cmd2
exit
}


}

    export-modulemember -Function  runtc13513