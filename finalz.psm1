
function finalz{


Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force
 $wshell = New-Object -com WScript.Shell
  Add-Type -AssemblyName Microsoft.VisualBasic
     Add-Type -AssemblyName System.Windows.Forms

######  basic check folders ######


if($PSScriptRoot.length -eq 0){
$scriptRoot="C:\testing_AI\modules\"
}
else{
$scriptRoot=$PSScriptRoot
}

#$daver_path=(Split-Path -Parent $scriptRoot)+"\logs\basic\" 
#if(-not(test-path $daver_path)){new-item -ItemType directory $daver_path |Out-Null }



########## save log ########

$action="finalization"

$tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
$tcnumber=((get-content $tcpath).split(","))[0]
$tcstep=((get-content $tcpath).split(","))[1]
$index="-"
$results="OK" 

Get-Module -name "outlog"|remove-module
$mdpath=(gci -path "C:\testing_AI\modules\" -r -file |?{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

#write-host "Do $action!"
outlog $action $results  $tcnumber $tcstep $index
  

}


    export-modulemember -Function finalz


