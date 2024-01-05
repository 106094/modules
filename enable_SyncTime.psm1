function enable_SyncTime{

Set-ItemProperty -Path  "HKLM:\SYSTEM\CurrentControlSet\Services\w32time\Parameters" -Name "Type" -Value "NTP"
$setvalue=(Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\w32time\Parameters"|select Type).type

if($PSScriptRoot.length -eq 0){
$scriptRoot="$env:USERPROFILE\desktop\Auto\Matagorda\testing_AI\modules\"
}
else{
$scriptRoot=$PSScriptRoot
}


$tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
$tcnumber=((get-content $tcpath).split(","))[0]
$tcstep=((get-content $tcpath).split(","))[1]

$action="Enable Sync Time"
$index=$setvalue

if($setvalue -eq "NTP"){$results="OK"} 
else{$results="NG"}

Get-Module -name "outlog"|remove-module
$mdpath=(Get-ChildItem -path "C:\testing_AI\modules\"  -r -file |Where-object{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

#write-host "Do $action!"
outlog $action $results  $tcnumber $tcstep $index

  }

  export-modulemember -Function enable_SyncTime