
function windowsupdate_checkcomplete {
    
    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force;
    $wshell=New-Object -ComObject wscript.shell
      Add-Type -AssemblyName Microsoft.VisualBasic
      Add-Type -AssemblyName System.Windows.Forms
    

if($PSScriptRoot.length -eq 0){
$scriptRoot="C:\testing_AI\modules"
}
else{
$scriptRoot=$PSScriptRoot
}

$action="windowsupdate"
#$time=get-date -Format "yyyy/M/d HH:mm"

$tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
$tcnumber=((get-content $tcpath).split(","))[0]
$tcstep=((get-content $tcpath).split(","))[1]
$log1=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\checkwu.txt"
$log2=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\checkhotfox.txt"

get-WindowsUpdate|set-content $log1 
get-hotfix|set-content $log2
   

######### write log #######

Get-Module -name "outlog"|remove-module
$mdpath=(Get-ChildItem -path "C:\testing_AI\modules\"  -r -file |?{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

#write-host "Do $action!"
outlog $action $results $tcnumber $tcstep $index


  }

    export-modulemember -Function windowsupdate_checkcomplete