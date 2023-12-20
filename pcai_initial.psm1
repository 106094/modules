
function pcai_initial ([string]$para1){
    
    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force;
    $wshell=New-Object -ComObject wscript.shell
      Add-Type -AssemblyName Microsoft.VisualBasic
       Add-Type -AssemblyName System.Windows.Forms
        Add-Type -AssemblyName System.Windows.Forms,System.Drawing
    
        
$paracheck=$PSBoundParameters.ContainsKey('para1')

if( $paracheck -eq $false -or $para1.length -eq 0 ){
$para1=""
}

$nolog_flag=$para1

if($PSScriptRoot.length -eq 0){
$scriptRoot="C:\testing_AI\modules"
}
else{
$scriptRoot=$PSScriptRoot
}

$tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
$tcnumber=((get-content $tcpath).split(","))[0]
$tcstep=((get-content $tcpath).split(","))[1]


$ping = New-Object System.Net.NetworkInformation.Ping

#$checklink=$ping.Send("www.google.com", 1000)
$checklink= Invoke-WebRequest -Uri "www.msn.com"

#!($checklink.Status -eq "success")
if(!($checklink)){
$results="-"
$index="no internet, bypassed"
}
else{

$pcaipath=(gci C:\testing_AI\modules\PC_AI_Tool*\AutoTool.exe).FullName

$rule1=Get-NetFirewallRule -DisplayName "AutoTool"
if($rule1){Remove-NetFirewallRule -DisplayName "AutoTool"}
start-sleep -s 2
New-NetFirewallRule -DisplayName "AutoTool" -Direction Inbound -Program "$pcaipath" -Action Allow


### revise pcai open settings ###
$atconfig=get-content C:\testing_AI\modules\PC_AI_Tool*\AutoTool.exe.Config
$atconfig1=$atconfig.replace("add key=""Launch with windows"" value=""True""","add key=""Launch with windows"" value=""False""")
#$atconfig2=$atconfig1.replace("add key=""AutoLogin"" value=""Yes"" ","add key=""AutoLogin"" value=""No""")
set-content C:\testing_AI\modules\PC_AI_Tool*\AutoTool.exe.Config -Value $atconfig1

#netsh advfirewall firewall add rule name="AutoTool" dir=in action=allow program="$pcaipath" enable=yes   ## unblock firewell cmd
#netsh advfirewall firewall Delete rule name="AutoTool"  #Remove Allowed App cmd

start-sleep -s 10

###Testnet hostsettings##

$checkhost=get-content C:\Windows\System32\drivers\etc\hosts
if(!($checkhost -like "*172.16.21.249*")){
add-content C:\Windows\System32\drivers\etc\hosts -value "172.16.21.249	swtool.allion.com" -Force
}

## connect testing net ##

$modname="net_connecting"
Get-Module -name $modname|remove-module -ErrorAction SilentlyContinue
$mdpath=(gci -path $scriptRoot -r -file |?{$_.name -match "^$modname\b" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

&$modname -para2 nolog

## open once pcai ###

&$pcaipath
start-sleep -s 60

$checkrun=get-process -name "AutoTool"

if($checkrun){

$results="OK"
$index="check screenshot"

Get-Module -name screenshot|remove-module
$mdpath=(gci -path $scriptRoot -r -file |?{$_.name -match "^screenshot\b" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

 screenshot -para1 20 -para3 nolog -para5 "PCAI_initial"

 (get-process -Name "AutoTool"　-ea SilentlyContinue).CloseMainWindow()
}

else{
$results="NG"
$index="fail to open PCAI autotool"

}


 }
######### write log #######

if($nolog_flag.length -eq 0){

Get-Module -name "outlog"|remove-module
$mdpath=(gci -path "C:\testing_AI\modules\"  -r -file |?{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

#write-host "Do $action!"
outlog $action $results $tcnumber $tcstep $index
}


  }

    export-modulemember -Function pcai_initial