function disable_wu ([string]$para1){

$nonlog_flag=$para1

# set the Windows Update service to "disabled"
sc.exe config wuauserv start=disabled

# display the status of the service
#sc.exe query wuauserv

# stop the service, in case it is running
sc.exe stop wuauserv
#stop Background Intelligent Transfer Service (BITS) 
sc.exe stop BITS

# display the status again, because we're paranoid ::XDD
#sc.exe query wuauserv

start-sleep -s 5

$index=$index+@("wuauserv"+(sc.exe query wuauserv|Select-String "state").ToString())
$index=$index+@("BITS"+(sc.exe query BITS|Select-String "state").ToString())

# double check it's REALLY disabled - Start value should be 0x4
$checkreg=REG.exe QUERY HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\wuauserv /v Start 

if($checkreg -match "0x4"){$results="OK"}else{$results="NG"}


if($PSScriptRoot.length -eq 0){
$scriptRoot="$env:USERPROFILE\desktop\Auto\Matagorda\testing_AI\modules\"
}
else{
$scriptRoot=$PSScriptRoot
}


$tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
$tcnumber=((get-content $tcpath).split(","))[0]
$tcstep=((get-content $tcpath).split(","))[1]
$action="Disable Windows Update"

if($nonlog_flag.Length -eq 0){

Get-Module -name "outlog"|remove-module
$mdpath=(Get-ChildItem -path "C:\testing_AI\modules\"  -r -file |?{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

#write-host "Do $action!"
outlog $action $results  $tcnumber $tcstep $index
}
  }

  export-modulemember -Function  disable_wu