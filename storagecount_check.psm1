
function storagecount_check ([string]$para1,[int]$para2,[string]$para3){

$paracheck1=$PSBoundParameters.ContainsKey('para1')
$paracheck2=$PSBoundParameters.ContainsKey('para2')
$paracheck3=$PSBoundParameters.ContainsKey('para3')

if($paracheck1 -eq $false -or $para1.length -eq 0){
$para1=""
}
if($paracheck2 -eq $false -or $para2 -eq 0){
$para2=1
}
if($paracheck3 -eq $false -or $para3.Length -eq 0){
$para3=""
}
if($PSScriptRoot.length -eq 0){
$scriptRoot="C:\testing_AI\modules"
}
else{
$scriptRoot=$PSScriptRoot
}

$disktype=$para1
$diskcountcri=$para2
$nonlogflag=$para3

$timenow=get-date -format "yyMMdd_HHmmss"
$action="check storage counts"
$tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
$tcnumber=((get-content $tcpath).split(","))[0]
$tcstep=((get-content $tcpath).split(","))[1]
 $picpath=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\"
    if(-not(test-path $picpath)){new-item -ItemType directory -path $picpath |out-null}
 $storagelog= $picpath+"$($timenow)_step$($tcstep)_storageinfo.txt"

 $diskcount_usb=(Get-Disk | Where-Object -FilterScript {$_.Bustype -Eq "USB"}).BusType.count
if($disktype.Length -eq 0){
$diskcount=((get-disk).Number.count)-$diskcount_usb
}
if($disktype.Length -gt 0){
$diskcount=(get-disk).Number.count
$diskcount_SSD=((Get-PhysicalDisk |?{$_.Mediatype -eq "SSD"}).MediaType).count
$diskcount_HD=$diskcount-$diskcount_SSD-$diskcount_usb
if($disktype -match "SSD"){
$diskcount=$diskcount_SSD
}
if($disktype -match "HD"){
$diskcount=$diskcount_HD
}

}
Get-PhysicalDisk|out-string|set-content $storagelog -Force
get-disk|fl|out-string|add-content $storagelog -Force

$index="$($diskcount) $($disktype) disk(s)"


$results="NG"
if($diskcount -ge $diskcountcri){
$results="OK"
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


  export-modulemember -Function storagecount_check