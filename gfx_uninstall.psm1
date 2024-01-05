
function gfx_uninstall ([string]$para1,[string]$para2){
 
    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force;
    $wshell=New-Object -ComObject wscript.shell
     $shell=New-Object -ComObject shell.application
      Add-Type -AssemblyName Microsoft.VisualBasic
       Add-Type -AssemblyName System.Windows.Forms
        Add-Type -AssemblyName System.Windows.Forms,System.Drawing 
     
if($PSScriptRoot.length -eq 0){
$scriptRoot="C:\testing_AI\modules"
}
else{
$scriptRoot=$PSScriptRoot
}


if($para1.length -eq 0){
$para1="N"
}
if($para2.length -eq 0){
$para2=""
}

    $nn1=$para1
    $nonlogflag=$para2

$tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
$tcnumber=((get-content $tcpath).split(","))[0]
$tcstep=((get-content $tcpath).split(","))[1]
$action=((get-content $tcpath).split(","))[2]

$picpath=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\"
if(-not(test-path $picpath)){new-item -ItemType directory -path $picpath |out-null}

$actionss="screenshot"
Get-Module -name $actionss|remove-module
$mdpath=(Get-ChildItem -path $scriptRoot -r -file |Where-object{$_.name -match "^$actionss\b" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

$actioncp="copyingfiles"
Get-Module -name $actioncp|remove-module
$mdpath=(Get-ChildItem -path $scriptRoot -r -file |Where-object{$_.name -match "^$actioncp\b" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

$actioncmd="cmdline"
Get-Module -name $actioncmd|remove-module
$mdpath=(Get-ChildItem -path $scriptRoot -r -file |Where-object{$_.name -match "^$actioncmd\b" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

$actionexp="filexplorer"
Get-Module -name $actionexp|remove-module
$mdpath=(Get-ChildItem -path $scriptRoot -r -file |Where-object{$_.name -match "^$actionexp\b" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

$actionus="driver_uninstall"
Get-Module -name $actionus|remove-module
$mdpath=(Get-ChildItem -path $scriptRoot -r -file |Where-object{$_.name -match "^$actionus\b" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

$results="-"
$index="check logs"

$inidrv=(Get-ChildItem "C:\testing_AI\logs\ini*\*" -r -Filter "*DriverVersion.csv"|Sort-Object lastwritetime|select -last 1).FullName
$checktype=(import-csv $inidrv|Where-object{$_.DeviceClass -match "DISPLAY"}).devicename

if($inidrv -and $checktype){
if($checktype -match "NVIDIA"){
$drvtype2="NV_general"
if($checktype -match "ada"){
$drvtype2="NV_A6000ada"
}
write-host "The Display Driver is $($drvtype2)"
}

#region AMD GFX uninstall#

if($checktype -match "AMD"){
$chekdrv=$checktype -match "[a-zA-Z]\d{4}"
if(!$chekdrv){$checktype -match "\d{4}"}
$drvtype2="AMD_"+$matches[0]
write-host "The Display Driver is $($drvtype2)"

## check if folder exist
$drvfd="$scriptRoot\driver\GFX\$($drvtype2)\$($nn1)"

## if no exist, copy it from server
if(!(test-path $drvfd )){
&$actioncp -para1 "\\192.168.2.249\srvprj\Inventec\Dell\Matagorda\07.Tool\_AutoTool\driver\GFX" -para2 "$scriptRoot\driver" -para3 nolog
}

## after copy 

if(test-path $drvfd){

$dupfile=Get-ChildItem $drvfd\*.exe|sort lastwritetime|select -last 1
$zipfile=Get-ChildItem $drvfd\*.zip|sort lastwritetime|select -last 1


if($dupfile){
$dupfilefull=$dupfile.fullname
$timenow=get-date -format "yyMMdd_HHmmss"
$zipdes=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\$($timenow)_step$($tcstep)_DUPextract\"
$logpath_extract=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\$($timenow)_step$($tcstep)_DUPextract.txt"

if(!(test-path $zipdes)){
new-item -ItemType directory -Path $zipdes|out-null
}
&$dupfilefull /s /e=$zipdes /l=$logpath_extract
$exeresult=$?

if($exeresult -eq $true){
write-host "extract DUP success" 
}
else{
write-host "extract DUP fail" 
}
do{
start-sleep -s 5
$runfiles=(Get-ChildItem -path $zipdes -Recurse |Where-object{$_.name -match "ATISetup\.exe"})
write-host  "wait DUP extract (ATIsetup)"
}until($runfiles)
}


elseif(!$dupfile -and $zipfile){
$zipfilebname=$zipfile.BaseName
$timenow=get-date -format "yyMMdd_HHmmss"
$zipdes=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\$($timenow)_step$($tcstep)_ZIPextract\"
Expand-Archive $zipfile.FullName -DestinationPath  $zipdes -Force
&$actionexp -para1 $zipdes -para2 nonlog
}

else{
$results="NG"
$index="no DUP nor NUP file in $($drvfd)"
$timenow=get-date -format "yyMMdd_HHmmss"
$logpath=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\$($timenow)_step$($tcstep)_AMD_GFX_uninstall_NG.txt"
add-content -Path $logpath -value "no zip file in$($drvfd)"
}

if($results -ne "NG"){
$logpath=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\$($timenow)_step$($tcstep)_AMD_GFX_uninstall_log.txt"
$runfiles=(Get-ChildItem -path $zipdes -Recurse |Where-object{$_.name -match "AMDCleanupUtility\.exe"}).FullName
$uninstallcmd=$runfiles+" /silent"
if(!$runfiles){
$runfiles=(Get-ChildItem -path $zipdes -Recurse |Where-object{$_.name -match "ATISetup\.exe"}).FullName
$uninstallcmd=$runfiles+" -uninstall all -log $logpath "
}

&$actioncmd -para1 $uninstallcmd -para3 cmd -para5 nonlog
do{
write-host "wait uninstall job complete..."
start-sleep -s 10
$atirun=get-process -name atisetup -ea SilentlyContinue
$amdclean=get-process -name AMDCleanupUtility -ea SilentlyContinue
}until (!$atirun -and !$amdclean)

if($uninstallcmd -match "silent"){
copy-item -path "$env:userprofile\AppData\Local\Temp\CleanUp\AMDCleanup.log" -Destination $logpath -Force
}
add-content -Path $logpath -value "$($runfile) uninstall done, $(get-date)"
}

}
else{
$results="NG"
$index="copy driver file fail"
$timenow=get-date -format "yyMMdd_HHmmss"
$logpath=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\$($timenow)_step$($tcstep)_AMD_GFX_uninstall_NG.txt"
add-content -Path $logpath -value $index

}
}
#endregion 

#region NV GFX uninstall#
if($checktype -match "NVIDIA"){

&$actionus -para1 "NVIDIA RTX Desktop Manager" -para2 "nonlog"
&$actionus -para1 "NVIDIA HD Audio Driver" -para2 "nonlog"
&$actionus -para1 "NVIDIA Graphics Driver" -para2 "nonlog"

}
#endregion 

}

else{
$results="NG"
$index="cannot find initial driver infomation"
}

write-host "$results, $index"

######### write log #######
if( $nonlogflag.Length -eq 0){

Get-Module -name "outlog"|remove-module
$mdpath=(Get-ChildItem -path "C:\testing_AI\modules\"  -r -file |Where-object{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

#write-host "Do $action!"
outlog $action $results $tcnumber $tcstep $index
}
    

   }

    export-modulemember -Function gfx_uninstall