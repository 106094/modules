﻿

function iometer_initial ([string]$para1,[string]$para2){
    
    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force;
    $wshell=New-Object -ComObject wscript.shell
    $shell=New-Object -ComObject shell.application
    Add-Type -AssemblyName Microsoft.VisualBasic
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Windows.Forms,System.Drawing 

    $paracheck=$PSBoundParameters.ContainsKey('para1')

    if( $paracheck -eq $false -or $para1.length -eq 0 ){
        $para1=""
    }

    $Toolpath=$para1
    $nolog_flag=$para2

    if($PSScriptRoot.length -eq 0){
        $scriptRoot="C:\testing_AI\modules"
    }
    else{
        $scriptRoot=$PSScriptRoot
    }


    $actionss="screenshot"
    Get-Module -name $actionss|remove-module
    $mdpath=(Get-ChildItem -path $scriptRoot -r -file |Where-object{$_.name -match "^$actionss\b" -and $_.name -match "psm1"}).fullname
    Import-Module $mdpath -WarningAction SilentlyContinue -Global

    $tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
    $tcnumber=((get-content $tcpath).split(","))[0]
    $tcstep=((get-content $tcpath).split(","))[1]

    $iometerpath=(Get-ChildItem "$Toolpath\IOMETER.exe").FullName

    $iometerpath2=(Get-ChildItem "$Toolpath\dynamo.exe").FullName

    ## firewell open for auto tool ##

    #$checkrule=(Show-NetFirewallRule |select DisplayName |Where-object{$_.displayname -eq "AutoTool"}).count

    if (Get-NetFirewallRule -displayname "Iometer"){
        Remove-NetFirewallRule -DisplayName "Iometer"
        start-sleep -s 2
    }

    New-NetFirewallRule -DisplayName "Iometer" -Direction Inbound -Program  $iometerpath -Action Allow
    start-sleep -s 10

    if (Get-NetFirewallRule -displayname "dynamo"){
        Remove-NetFirewallRule -DisplayName "dynamo"
        start-sleep -s 2
    }

    New-NetFirewallRule -DisplayName "dynamo" -Direction Inbound -Program $iometerpath2 -Action Allow
    start-sleep -s 10

    ## open once iometer ###

    &$iometerpath
    start-sleep -s 10

    &$actionss -para3 nolog -para5 "open"

     [System.Windows.Forms.SendKeys]::SendWait("{ENTER}")
 

    &$actionss -para3 nolog -para5 "open2"

    (get-process -Name "IOMETER"　-ea SilentlyContinue).CloseMainWindow()

    $results="-"
    $index="check screenshot"


    ######### write log #######

    if($nolog_flag.length -eq 0){
        Get-Module -name "outlog"|remove-module
        $mdpath=(Get-ChildItem -path "C:\testing_AI\modules\"  -r -file |Where-object{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
        Import-Module $mdpath -WarningAction SilentlyContinue -Global

        #write-host "Do $action!"
        outlog $action $results $tcnumber $tcstep $index
    }
}

    export-modulemember -Function iometer_initial