function DellOptimizer([string]$para1,[int]$para2,[string]$para3){

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

$tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
$tcnumber=((get-content $tcpath).split(","))[0]
$tcstep=((get-content $tcpath).split(","))[1]

$actioncp="startmenuapp"
Get-Module -name $actioncp|remove-module
$mdpath=(Get-ChildItem -path $scriptRoot -r -file |Where-object{$_.name -match "^$actioncp\b" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

&$actioncp -para1 "Optimizer" -para3 "nonlog"

Start-Sleep -s 30

if( (Get-Package -Name "*Dell Optimizer*").version -match "4.2.0.0" ){
    [System.Windows.Forms.SendKeys]::SendWait("{TAB}");
    Start-Sleep -s 5
    [System.Windows.Forms.SendKeys]::SendWait("{ENTER}");
    Start-Sleep -s 5
    [System.Windows.Forms.SendKeys]::SendWait("{ENTER}");
    Start-Sleep -s 5
    [System.Windows.Forms.SendKeys]::SendWait("{ENTER}");
    Start-Sleep -s 5
    [System.Windows.Forms.SendKeys]::SendWait("{ENTER}");
    Start-Sleep -s 5
    [System.Windows.Forms.SendKeys]::SendWait("{ENTER}");
    Start-Sleep -s 5
    [System.Windows.Forms.SendKeys]::SendWait("{TAB 6}");
    Start-Sleep -s 5
    [System.Windows.Forms.SendKeys]::SendWait(" ");
    Start-Sleep -s 5
    [System.Windows.Forms.SendKeys]::SendWait("{TAB 3}");
    Start-Sleep -s 5
    [System.Windows.Forms.SendKeys]::SendWait("{ENTER}");
}else{
    [System.Windows.Forms.SendKeys]::SendWait("{TAB}");
    Start-Sleep -s 5
    [System.Windows.Forms.SendKeys]::SendWait("{ENTER}");
    Start-Sleep -s 5
    [System.Windows.Forms.SendKeys]::SendWait("{ENTER}");
    Start-Sleep -s 5
    [System.Windows.Forms.SendKeys]::SendWait("{ENTER}");
    Start-Sleep -s 5
    [System.Windows.Forms.SendKeys]::SendWait("{ENTER}");
    Start-Sleep -s 5
    [System.Windows.Forms.SendKeys]::SendWait("{ENTER}");
    Start-Sleep -s 5
    [System.Windows.Forms.SendKeys]::SendWait("{ENTER}");
    Start-Sleep -s 5
    [System.Windows.Forms.SendKeys]::SendWait("{TAB 6}");
    Start-Sleep -s 5
    [System.Windows.Forms.SendKeys]::SendWait(" ");
    Start-Sleep -s 5
    [System.Windows.Forms.SendKeys]::SendWait("{TAB 3}");
    Start-Sleep -s 5
    [System.Windows.Forms.SendKeys]::SendWait("{ENTER}");
}

    ######### write log #######
    if($nonlog_flag.Length -eq 0 -or $timespanmin -gt 30){
        Get-Module -name "outlog"|remove-module
        $mdpath=(Get-ChildItem -path "C:\testing_AI\modules\"  -r -file |Where-object{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
        Import-Module $mdpath -WarningAction SilentlyContinue -Global
        
        #write-host "Do $action!"
        outlog $action $results $tcnumber $tcstep $index
    }
}
    
        export-modulemember -Function DellOptimizer