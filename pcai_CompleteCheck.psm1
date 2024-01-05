

function pcai_CompleteCheck {
    
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

$action="pcai_CompleteCheck"
$tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
$tcnumber=((get-content $tcpath).split(","))[0]
$tcstep=((get-content $tcpath).split(","))[1]

#$picpath=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\"+"$($tcstep)-pcai_screenshots\"
#if(-not(test-path $picpath)){new-item -ItemType directory -path $picpath  -Force |out-null}


$checkrun=(get-process -Name "AutoTool").Id

if($checkrun -ne $null){
## pcai still running
exit
}

else{
start-sleep -s 10

$pcairesult=(Get-ChildItem -path C:\testing_AI\modules\PC_AI_Tool_20221220\Main\Windows\Report\* -Directory|sort creationtime |select -last 1).fullname
Move-Item $pcairesult $picpath -Force
move-item C:\testing_AI\logs\*.png  $picpath -Force

 $results="OK"
 $index="PCAI running ok, check screenshots and result html"
 }

######### write log #######

Get-Module -name "outlog"|remove-module
$mdpath=(Get-ChildItem -path "C:\testing_AI\modules\"  -r -file |?{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

#write-host "Do $action!"
outlog $action $results $tcnumber $tcstep $index


  }

    export-modulemember -Function pcai_CompleteCheck