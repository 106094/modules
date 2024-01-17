
function nViewconfig_revise ([string]$para1){
    
    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force;
    Add-Type -AssemblyName Microsoft.VisualBasic
    Add-Type -AssemblyName System.Windows.Forms
   
$nonlog_flag=$para1

if($PSScriptRoot.length -eq 0){
$scriptRoot="C:\testing_AI\modules"
}
else{
$scriptRoot=$PSScriptRoot
}

$action="nViewconfig revise"

$tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
$tcnumber=((get-content $tcpath).split(","))[0]
$tcstep=((get-content $tcpath).split(","))[1]

$configpath=(Get-ChildItem -path "$env:userprofile\AppData\Local\nViewCpl1\nvwdmcpl.exe_Url_*\" -Recurse -Filter "user.config").fullname

$keywords="HideTipsAtLaunch"
$configcontents=get-content $configpath
$k=999
$newconfigcontents=foreach($configcontent in $configcontents){
   $k++
if($configcontent -match $keywords){
    $l=$k
    $k=0
}
if($k -eq 1){
    $configcontent=$configcontent.replace("False","True")
}
$configcontent
}
$newconfigcontents|set-content $configpath -Force

#check
$configcontents=get-content $configpath
$results="NG"
$index="setting fail"
if( $configcontents[$l+1] -match "true"){
 $results="OK"
 $index="setting ok"
}

######### write log #######

if($nonlog_flag.Length -eq 0){
Get-Module -name "outlog"|remove-module
$mdpath=(Get-ChildItem -path "C:\testing_AI\modules\"  -r -file |Where-Object{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

#write-host "Do $action!"
outlog $action $results $tcnumber $tcstep $index
}

  }

    export-modulemember -Function nViewconfig_revise