function timesync{

w32tm /unregister
w32tm /register

$status=(get-service  -Include w32time).Status
#w32tm /config /syncfromflags:domhier /update
if ($status -match "stop"){
net start w32time
}
$difftime=w32tm /stripchart /computer:"time.nist.gov" /samples:3 /dataonly
write-host "time-gap before $difftime"

#w32tm /config /manualpeerlist:"ntpserver.contoso.com,0x8 clock.adatum.com,0x2" /syncfromflags:manual /update
w32tm /config /manualpeerlist:"time.nist.gov" /syncfromflags:manual /update
#reg query HKLM\SYSTEM\CurrentControlSet\Services\W32Time\Parameters
#w32tm /query /configuration 
w32tm /resync /rediscover
$difftime=w32tm /stripchart /computer:"time.nist.gov" /samples:3 /dataonly

$difftime= $difftime -join "`n"

$action="Time Sync to nist"

$tcpath=(Split-Path -Parent $PSScriptRoot)+"\currentjob\TC.txt"
$tcnumber=((get-content $tcpath).split(","))[0]
$tcstep=((get-content $tcpath).split(","))[1]
$Index=$difftime
$results="OK" 

net stop w32time

start-sleep -s 10

Get-Module -name "outlog"|remove-module
$mdpath=(Get-ChildItem -path "C:\testing_AI\modules\" -r -file |Where-object{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

#write-host "Do $action!"
outlog $action $results $tcnumber $tcstep $index


  }
  
  export-modulemember -Function timesync