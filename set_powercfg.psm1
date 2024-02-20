function set_powercfg ([string]$para1,[string]$para2 ){
     
     $powermode=$para1
     $nonlog_flag=$para2

if($PSScriptRoot.length -eq 0){
$scriptRoot="C:\testing_AI\modules"
}
else{
$scriptRoot=$PSScriptRoot
}

if($powermode.Length -eq 0){
    $powermode="balanced"
}

$tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
$tcnumber=((get-content $tcpath).split(","))[0]
$tcstep=((get-content $tcpath).split(","))[1]
$action=((get-content $tcpath).split(","))[2]

$picpath=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\"
if(-not(test-path $picpath)){new-item -ItemType directory -path $picpath |out-null}
$results="OK"

$logtxt1=$picpath+"$($tcstep)_powercfg_before.txt"
$logtxt2=$picpath+"$($tcstep)_powercfg_after.txt"

new-item -path $logtxt|Out-Null
new-item -path $logtxt2|Out-Null

$powerlist=powercfg -list
$powermode1=$powerlist|Out-String

$matchline=$powerlist -match $powermode|Out-String
$pattern = "[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}"

if ($matchline -match $pattern) {
    $guid = $matches[0]
    $index= "set power mode to $($powermode) GUID: $($guid)"
} else {
    $results="NG"
    $index= "No GUID found in the string."
}

try{
    powercfg /setactive $guid
}catch{
    $results="NG"
    $index="fail to change power mode"
}

$powerlist=powercfg -list
$powermode2=$powerlist|Out-String

add-content -path $logtxt1 -value $powermode1 -Force
add-content -path $logtxt2 -value $powermode2 -Force

######### write log #######
if($nonlog_flag.Length -eq 0){
    Get-Module -name "outlog"|remove-module
    $mdpath=(Get-ChildItem -path "C:\testing_AI\modules\"  -r -file |Where-object{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
    Import-Module $mdpath -WarningAction SilentlyContinue -Global
    
    #write-host "Do $action!"
    outlog $action $results $tcnumber $tcstep $index

}

  }
    export-modulemember -Function set_powercfg