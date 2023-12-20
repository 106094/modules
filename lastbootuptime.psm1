function lastbootuptime{


if($PSScriptRoot.length -eq 0){
$scriptRoot="C:\testing_AI\modules\"
}
else{
$scriptRoot=$PSScriptRoot
}

$lastboot=Get-CimInstance -ClassName Win32_OperatingSystem | Select LastBootUpTime
$lastbootuptime=  get-date ($lastboot.LastBootUpTime) -Format "M/d HH:mm:ss"
$uptime = [DateTime]$reboottime - ($lastboot.LastBootUpTime)

if($uptime.TotalSeconds -le 0 ){$results="OK"}else{$results="NG"}

$Index="last BootUp at "+$lastbootuptime

<##
$logspath=(Split-Path -Parent $scriptRoot)+"\logs\logs_timemap.csv" 
$reboottime=(import-csv $logspath|?{$_.actions -match "reboot"}|select -Last 1).Time

$update=import-csv $logspath
($update|?{$_.actions -match "reboot"}|select -Last 1).Index="last BootUp at "+$lastbootuptime
($update|?{$_.actions -match "reboot"}|select -Last 1).Results=$results
$update  | export-csv -path  $logspath -Encoding OEM -NoTypeInformation  #### no new line ### no append ####
###>

$action="check last bootup time"

$tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
$tcnumber=((get-content $tcpath).split(","))[0]
$tcstep=((get-content $tcpath).split(","))[1]

Get-Module -name "outlog"|remove-module
$mdpath=(gci -path "C:\testing_AI\modules\" -r -file |?{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

#write-host "Do $action!"
outlog $action $results $tcnumber $tcstep $index

}

  export-modulemember -Function  lastbootuptime