

function crdiskinstall {
    
    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force;
    $wshell=New-Object -ComObject wscript.shell
      Add-Type -AssemblyName Microsoft.VisualBasic
      Add-Type -AssemblyName System.Windows.Forms
        Add-Type -AssemblyName Microsoft.VisualBasic
   
   
if($PSScriptRoot.length -eq 0){
$scriptRoot="C:\testing_AI\modules"
}
else{
$scriptRoot=$PSScriptRoot
}


$checkcdv = (Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* |  Select-Object DisplayName).DisplayName -match "CrystalDisk" |select -first 1
try{
$checkcdv=$checkcdv.ToString().trim()
}
catch{

 $crdinfo= (Get-ChildItem -path $scriptRoot -r -file "CrystalDiskInfo*").fullname

 & $crdinfo  /verysilent

}

$i=0
do{
start-sleep 5
$checkcdv = (Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* |  Select-Object DisplayName).DisplayName -match "CrystalDisk" |select -first 1
$checkcdv=$checkcdv.ToString().trim()
}until($checkcdv.Length -ne 0 -or $i -gt 10)

if($checkcdv.Length -ne 0){
$result="OK"
$index=$checkcdv
}

if( $i -gt 10){
$results="NG"
$index="install CrystalDiskInfo fail"


[System.Windows.Forms.MessageBox]::Show($this,"CrystalDiskInfo install fail, please check")   
exit
}

######### write log #######


$action="CrystalDiskInfo install"

$tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
$tcnumber=((get-content $tcpath).split(","))[0]
$tcstep=((get-content $tcpath).split(","))[1]

Get-Module -name "outlog"|remove-module
$mdpath=(Get-ChildItem -path "C:\testing_AI\modules\"  -r -file |?{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

#write-host "Do $action!"
outlog $action $results $tcnumber $tcstep $index


  }

    export-modulemember -Function crdiskinstall