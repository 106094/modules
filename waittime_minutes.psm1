
function waittime_minutes ([int]$para1){


$paracheck1=$PSBoundParameters.ContainsKey('para1')


if($paracheck1 -eq $false -or $para1 -eq 0){
$para1=[int]1
}

$results="NG"

$waittime=$para1*60

$timenow1=get-date -Format "yyyy/M/d HH:mm:ss"

start-sleep -s $waittime


if($? -match $true){$results="OK"}

if($PSScriptRoot.length -eq 0){
$scriptRoot="C:\testing_AI\modules"
}
else{
$scriptRoot=$PSScriptRoot
}


$timenow2=get-date -Format "yyyy/M/d HH:mm:ss"
$action="wait for $para1 minutes from $timenow1 to $timenow2"
$tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
$tcnumber=((get-content $tcpath).split(","))[0]
$tcstep=((get-content $tcpath).split(","))[1]

$Index="-"

Get-Module -name "outlog"|remove-module
$mdpath=(Get-ChildItem -path "C:\testing_AI\modules\" -r -file |?{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

#write-host "Do $action!"
outlog $action $results $tcnumber $tcstep $index


}


  export-modulemember -Function waittime_minutes