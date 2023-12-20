
function perc_check ([string]$para1){

$paracheck1=$PSBoundParameters.ContainsKey('para1')
$paracheck2=$PSBoundParameters.ContainsKey('para2')
$paracheck3=$PSBoundParameters.ContainsKey('para3')

if($paracheck1 -eq $false -or $para1.length -eq 0){
$para1=""
}

if($PSScriptRoot.length -eq 0){
$scriptRoot="C:\testing_AI\modules"
}
else{
$scriptRoot=$PSScriptRoot
}

$nonlogflag=$para1

$action="check PERC exist"
$tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
$tcnumber=((get-content $tcpath).split(","))[0]
$tcstep=((get-content $tcpath).split(","))[1]
 $picpath=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\"
    if(-not(test-path $picpath)){new-item -ItemType directory -path $picpath |out-null}
 percelog= $picpath+"$($timenow)_step$($tcstep)_percinfo.txt"

$inidrv=(gci "C:\testing_AI\logs\ini*" -r -Filter "*DriverVersion.csv"|Sort-Object lastwritetime|select -last 1).FullName
$percname=(import-csv $inidrv|?{$_.DeviceName -match "^PERC"}).devicename

$results="OK"
$index="$percname"
if(!$percname -or $percname.length -eq 0){
$results="NG"
$index="no PERC"
}

Write-Host "$results, $index"

if($nonlogflag.length -eq 0){

Get-Module -name "outlog"|remove-module
$mdpath=(gci -path "C:\testing_AI\modules\" -r -file |?{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

#write-host "Do $action!"
outlog $action $results $tcnumber $tcstep $index
}

}


  export-modulemember -Function perc_check