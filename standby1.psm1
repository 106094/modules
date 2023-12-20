
<####

shutdown %windir%\System32\shutdown.exe -s
Reboot %windir%\System32\shutdown.exe -r
Logoff %windir%\System32\shutdown.exe -l
Standby %windir%\System32\rundll32.exe powrprof.dll,SetSuspendState Standby
Hibernate %windir%\System32\rundll32.exe powrprof.dll,SetSuspendState Hibernate

####>

function standby1{

$action="Sleep"

if($PSScriptRoot.length -eq 0){
$scriptRoot="$env:USERPROFILE\desktop\Matagorda\testing_AI\modules"
}
else{
$scriptRoot=$PSScriptRoot
}
$tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
$tcnumber=((get-content $tcpath).split(","))[0]
$tcstep=((get-content $tcpath).split(","))[1]
$Index="-"
$results="-"


Get-Module -name "outlog"|remove-module
$mdpath=(gci -path "C:\testing_AI\modules\" -r -file |?{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

#write-host "Do $action!"
outlog $action $results  $tcnumber $tcstep $index


 $pstpath=(Split-Path -Parent $scriptRoot)+"\modules\PSTools\psshutdown.exe"

  &$pstpath -d -t 0 -accepteula |Out-Null

  exit

  }

    export-modulemember -Function  standby1