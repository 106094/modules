
function　controlpanel ([string]$para1,[string]$para2,[string]$para3){
      
    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force;
    $wshell=New-Object -ComObject wscript.shell
     $shell=New-Object -ComObject shell.application
      Add-Type -AssemblyName Microsoft.VisualBasic
       Add-Type -AssemblyName System.Windows.Forms
        Add-Type -AssemblyName System.Windows.Forms,System.Drawing
    
    $ctppath=$para1
    $noclose_flag=$para2
    $nonlog_flag=$para3
     
$actionss="screenshot"
Get-Module -name $actionss|remove-module
$mdpath=(Get-ChildItem -path $scriptRoot -r -file |?{$_.name -match "^$actionss\b" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global


if($PSScriptRoot.length -eq 0){
$scriptRoot="C:\testing_AI\modules"
}
else{
$scriptRoot=$PSScriptRoot
}

$tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
$tcnumber=((get-content $tcpath).split(","))[0]
$tcstep=((get-content $tcpath).split(","))[1]
$action=((get-content $tcpath).split(","))[2]

$picpath=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\"
if(-not(test-path $picpath)){new-item -ItemType directory -path $picpath |out-null}

#$controlpn="Control Panel\Programs\Programs and Features"
$action=($ctppath.split("\"))[-1]

Start-Process control -Verb Open -WindowStyle Maximized
start-sleep -s 5
$wshell.SendKeys("% ")
$wshell.SendKeys("x")
start-sleep -s 2
$wshell.SendKeys("^l")
Set-Clipboard $ctppath
Start-Sleep -s 5
$wshell.SendKeys("^v")
Start-Sleep -s 1
$wshell.SendKeys("~")
Start-Sleep -s 5

&$actionss -para3 nonlog $para5 $action

if($noclose_flag.Length -eq 0){
$wshell.SendKeys("% ")
$wshell.SendKeys("c")
}

######### write log #######

if($nonlog_flag.Length -eq 0){

Get-Module -name "outlog"|remove-module
$mdpath=(Get-ChildItem -path "C:\testing_AI\modules\"  -r -file |?{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

#write-host "Do $action!"
outlog $action $results $tcnumber $tcstep $index
}

   }

    export-modulemember -Function controlpanel