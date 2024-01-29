
function gfxtype_check ([string]$para1,[string]$para2){
 
    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force;
    #$wshell=New-Object -ComObject wscript.shell
     #$shell=New-Object -ComObject shell.application
      Add-Type -AssemblyName Microsoft.VisualBasic
        Add-Type -AssemblyName System.Windows.Forms,System.Drawing 

$checktype=$para1
$nonlog_flag=$para2
 
$results="FAIL"
$inidrv=(Get-ChildItem "C:\testing_AI\logs\ini*\*" -r -Filter "*DriverVersion.csv"|Sort-Object lastwritetime|Select-Object -last 1).FullName
$checktype=(import-csv $inidrv|Where-object{$_.DeviceClass -match "DISPLAY"}).devicename

if($checktype.length -eq 0){
    $results="NG"    
    $index="no define display type for checking"
}
else{
if(!$inidrv -or !$checktype){
    $results="NG"    
    $index="no inital information was found, no idea the gfx type is"
}

if($inidrv -and $checktype){
if($checktype -match "NVIDIA"){
$drvtype1="NV"    
$drvtype2="NV_general"
if($checktype -match "ada"){
$drvtype2="NV_A6000ada"
}
write-host "The Display Driver is $($drvtype2)"
}
if($checktype -match "AMD"){
$drvtype1="AMD"
$chekdrv=$checktype -match "[a-zA-Z]\d{4}"
if(!$chekdrv){$checktype -match "\d{4}"}
$drvtype2="AMD_"+$matches[0]
write-host "The Display Driver is $($drvtype2)"
}
}
if($drvtype1 -match $checktype){
$results="PASS"
$index=$drvtype2
}
}
write-output "$results,$index"

######### write log #######
if( $nonlog_flag.Length -eq 0){

Get-Module -name "outlog"|remove-module
$mdpath=(Get-ChildItem -path "C:\testing_AI\modules\"  -r -file |Where-object{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

#write-host "Do $action!"
outlog $action $results $tcnumber $tcstep $index
}
    

   }

    export-modulemember -Function gfxtype_check