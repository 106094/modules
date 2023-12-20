
function　check_upgradecomplete ([string]$para1,[string]$para2){
      
    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force;
    $wshell=New-Object -ComObject wscript.shell
      Add-Type -AssemblyName Microsoft.VisualBasic
      Add-Type -AssemblyName System.Windows.Forms
      Add-Type -AssemblyName System.Windows.Forms,System.Drawing    

$paracheck1=$PSBoundParameters.ContainsKey('para1')
if($paracheck1 -eq $false -or $para1.Length -eq 0){
$para1=""
}

$isofile=$para1
$nonlog_flag=$para2

 #  Control Panel\System and Security\Backup and Restore (Windows 7)

if($PSScriptRoot.length -eq 0){
$scriptRoot="C:\testing_AI\modules"
}
else{
$scriptRoot=$PSScriptRoot
}


$action="Window upgrade by iso file"
$tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
$tcnumber=((get-content $tcpath).split(","))[0]
$tcstep=((get-content $tcpath).split(","))[1]

$picpath=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\"
if(-not(test-path $picpath)){new-item -ItemType directory -path $picpath |out-null}

$setuprun=((get-process setup -ea SilentlyContinue).id).count

if($setuprun -eq 0){
$results="NG"
$index="no setup is running"
}

else{
do{
Start-Sleep -s 60
$setuprun=((get-process setup -ea SilentlyContinue).id).count

}until ($setuprun -eq 0)

$results="OK"
$index="setup completed"


}

######### write log  #######

if($nonlog_flag.Length -eq 0){
Get-Module -name "outlog"|remove-module
$mdpath=(gci -path "C:\testing_AI\modules\"  -r -file |?{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

#write-host "Do $action!"
outlog $action $results $tcnumber $tcstep $index

  }

  }

  
    export-modulemember -Function check_upgradecomplete