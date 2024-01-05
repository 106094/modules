
function sleepstudy1 {

$action="sleepstudy1"
$now=get-date -format "yyMMdd_HHmmss"

if($PSScriptRoot.length -eq 0){
$scriptRoot="C:\testing_AI\modules"
}
else{
$scriptRoot=$PSScriptRoot
}

$output=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\$($now)_sleepstudy.html"
$outpath=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\"
if(-not(test-path $outpath)){
new-item -ItemType -directory -Path $outpath -Force -ea SilentlyContinue |Out-Null
}
powercfg /SleepStudy /output $output
 
 $checkdone="NG"
 $waitc=0
 do{
 start-sleep -s 2
 if(test-path $output){$checkdone="OK"}
  $waitc++
 } until($checkdone -eq "OK" -or $waitc -gt 100)

 
  start-sleep -s 5

 $tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
 $tcnumber=((get-content $tcpath).split(","))[0]
 $tcstep=((get-content $tcpath).split(","))[1]
 $index=$output
 $Results=$checkdone 
 

Get-Module -name "outlog"|remove-module
$mdpath=(Get-ChildItem -path "C:\testing_AI\modules\" -r -file |?{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

#write-host "Do $action!"
outlog $action $result  $tcnumber $tcstep $index


  
}



    export-modulemember -Function sleepstudy1