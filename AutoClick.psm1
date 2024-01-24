
function AutoClick([int]$para1) {
    
    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force;
    #$wshell=New-Object -ComObject wscript.shell
      Add-Type -AssemblyName Microsoft.VisualBasic
      Add-Type -AssemblyName System.Windows.Forms
        Add-Type -AssemblyName Microsoft.VisualBasic
   
   
if($PSScriptRoot.length -eq 0){
$scriptRoot="C:\testing_AI\modules"
}
else{
$scriptRoot=$PSScriptRoot
}

$action="AutoClick"

$tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
$tcnumber=((get-content $tcpath).split(","))[0]
$tcstep=((get-content $tcpath).split(","))[1]

$picpath=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\"
if(-not(test-path $picpath)){new-item -ItemType directory -path $picpath |out-null}

$actionss ="screenshot"
Get-Module -name $actionss|remove-module
$mdpath=(Get-ChildItem -path $scriptRoot -r -file |Where-object{$_.name -match "^$actionss\b" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

$paracheck=$PSBoundParameters.ContainsKey('para1')

if($paracheck -eq $false -or  $para1 -eq 0 ){
    $para1= 100
}


$Autocount = $para1

#--------------------------------------------------------------------------------

Start-Sleep -s 5

C:\testing_AI\modules\Auto-Click\Auto-Click.exe

Start-Sleep -s 20

[System.Windows.Forms.SendKeys]::Sendwait($Autocount)

&$actionss -para3 "nonlog" -para5 "CountSetting"

[System.Windows.Forms.SendKeys]::Sendwait("{Enter}")

$backgroundProcesses = Get-Process -Name "actexec" | Where-Object { $_.MainWindowTitle -ne "" }

while(!($backgroundProcesses)){
    Start-Sleep -s 10
    $backgroundProcesses = Get-Process -Name "actexec" | Where-Object { $_.MainWindowTitle -ne "" }
}

&$actionss -para3 "nonlog" -para5 "Auto-Click-Complete"

if($Autocount % 2 -eq 0){
  [System.Windows.Forms.SendKeys]::Sendwait("{ESC}")
}

Start-Sleep -s 5

[System.Windows.Forms.SendKeys]::Sendwait("{Enter}")

Start-Sleep -s 5

[System.Windows.Forms.SendKeys]::Sendwait("N")



######### write log #######
Get-Module -name "outlog"|remove-module
$mdpath=(Get-ChildItem -path "C:\testing_AI\modules\"  -r -file |Where-object{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

#write-host "Do $action!"
outlog $action $results $tcnumber $tcstep $index


  }

    export-modulemember -Function AutoClick