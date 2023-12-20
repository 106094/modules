function enable_wu ([string]$para1){

$nonlog_flag=$para1

# set the Windows Update service to "auto"
sc.exe config wuauserv start=auto

# display the status of the service
#sc.exe query wuauserv

# start the service, in case it is not running
sc.exe start wuauserv
sc.exe start BITS

# display the status again, because we're paranoid ::XDD
#sc.exe query wuauserv

start-sleep -s 5

$index=$index+@("wuauserv"+(sc.exe query wuauserv|Select-String "state").ToString())
$index=$index+@("BITS"+(sc.exe query BITS|Select-String "state").ToString())

# double check it's REALLY disabled - Start value should be 0x4
$checkreg=REG.exe QUERY HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\wuauserv /v Start 

if($checkreg -match "0x2"){$results="OK"}else{$results="NG"}

<###
0x2: The service is set to start automatically with Windows.
0x3: The service is set to start manually (on demand).
0x4: The service is disabled and will not start.
##>

if($PSScriptRoot.length -eq 0){
$scriptRoot="C:\testing_AI\modules\"
}
else{
$scriptRoot=$PSScriptRoot
}

$tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
$tcnumber=((get-content $tcpath).split(","))[0]
$tcstep=((get-content $tcpath).split(","))[1]
$action="Enable Windows Update"

if($nonlog_flag.Length -eq 0){

Get-Module -name "outlog"|remove-module
$mdpath=(gci -path "C:\testing_AI\modules\"  -r -file |?{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

#write-host "Do $action!"
outlog $action $results  $tcnumber $tcstep $index
}
  }

  export-modulemember -Function  enable_wu