
function sendkeys ([string]$para1,[int]$para2,[string]$para3,[string]$para4){
    
    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force;
    $wshell=New-Object -ComObject wscript.shell
      Add-Type -AssemblyName Microsoft.VisualBasic
      Add-Type -AssemblyName System.Windows.Forms
   
$paracheck=$PSBoundParameters.ContainsKey('para1')
$paracheck2=$PSBoundParameters.ContainsKey('para2')

if( $paracheck -eq $false -or $para1.length -eq 0 ){
#write-host "no defined, setting 1 min after login"
$para1="no_define"
}

if( $paracheck -eq $false -or $para1.length -eq 0 ){
#write-host "no defined, setting 1 min after login"
$para2=1
}

$keysend=$para1
$waittime=$para2
$nonlog_flag=$para3
$no_capture=$para4

if($PSScriptRoot.length -eq 0){
$scriptRoot="C:\testing_AI\modules"
}
else{
$scriptRoot=$PSScriptRoot
}

$action="sendkeys of $para1"

$tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
$tcnumber=((get-content $tcpath).split(","))[0]
$tcstep=((get-content $tcpath).split(","))[1]
$picpath=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\"
if(-not(test-path $picpath)){new-item -ItemType directory -path $picpath |out-null}

    $actionss ="screenshot"
    Get-Module -name $actionss|remove-module
    $mdpath=(Get-ChildItem -path $scriptRoot -r -file |?{$_.name -match "^$actionss\b" -and $_.name -match "psm1"}).fullname
    Import-Module $mdpath -WarningAction SilentlyContinue -Global
  
 ## screenshot before sendkeys ##
if($no_capture.Length -eq 0){
    &$actionss  -para3 nonlog -para5 before
}


  

[void] [System.Reflection.Assembly]::LoadWithPartialName("'System.Windows.Forms")
#send keys 
start-sleep -s 3
[System.Windows.Forms.SendKeys]::Sendwait($keysend);   
$returncode=($?).tostring().trim()
if($returncode -eq "True"){$results="OK"}else{$results="NG"}
$index="-"
  
 ## screenshot after sendkeys ##
if($no_capture.Length -eq 0){
    start-sleep -s $waittime
    &$actionss  -para3 nonlog -para5 after
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

    export-modulemember -Function sendkeys