
function wait_action ([string]$para1,[int]$para2,[int]$para3,[string]$para4,[string]$para5){

$paracheck1=$PSBoundParameters.ContainsKey('para1')
$paracheck2=$PSBoundParameters.ContainsKey('para2')


if($paracheck1 -eq $false -or $para1.length -eq 0){
$para1=""
}
if($paracheck2 -eq $false -or $para2 -eq 0){
$para2=1
}
if($paracheck3 -eq $false -or $para3 -eq 0){
$para3=60
}
if($paracheck4 -eq $false -or $para4.length -eq 0){
$para4=""
}
if($paracheck5 -eq $false -or $para5.length -eq 0){
$para5=""
}
if($PSScriptRoot.length -eq 0){
$scriptRoot="C:\testing_AI\modules"
}
else{
$scriptRoot=$PSScriptRoot
}

$processname="$para1"
$waitinterval=[int]$para2*60
$waitmax=[int]$para3
$exitflag=$para4
$nonlogflag=$para5

$timenow=get-date

$action="wait for $processname process end"
$tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
$tcnumber=((get-content $tcpath).split(","))[0]
$tcstep=((get-content $tcpath).split(","))[1]

if($processname.Length -eq 0){
$results="NG"
$index="no define waiting action"
}
else{


$actionct=((get-process -name $processname*).Id).count

if($exitflag.Length -gt 0 -and $actionct -ne 0){
exit
}


do{
start-sleep -s $waitinterval
$actionct=((get-process -name $processname*).Id).count
$timegap=[math]::Round( ((New-TimeSpan -Start $timenow -End (Get-Date)).TotalMinutes),1)

}until($actionct -eq 0 -or $timegap -gt $waitmax)

$results="OK"
$index="wait $actionc ended, it takes $($timegap) minutes"

if($timegap -gt $waitmax){
$results="NG"
$index="wait $actionc ended more than $($timegap) minutes"

}

}

if($nonlogflag.length -eq 0){

Get-Module -name "outlog"|remove-module
$mdpath=(gci -path "C:\testing_AI\modules\" -r -file |?{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

#write-host "Do $action!"
outlog $action $results $tcnumber $tcstep $index
}

}


  export-modulemember -Function wait_action