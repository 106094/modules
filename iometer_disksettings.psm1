
function iometer_disksettings {
    
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


$action="iometer_disksettings"

$tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
$tcnumber=((get-content $tcpath).split(","))[0]
$tcstep=((get-content $tcpath).split(","))[1]

$picpath=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\"
if(-not(test-path $picpath)){new-item -ItemType directory -path $picpath |out-null}

$timenow=get-date -format "yyMMdd_HHmmss"
$steplog=$picpath+"$($timenow)_step$($tcstep)_IOmemeter_disksetting.txt"

$checkdid = (get-physicaldisk|Where-object{$_.mediatype -eq "SSD"}|select deviceid).deviceid
$checkdidstr=[string]::Join(",",$checkdid)

$results="NG"
$index="no SSD disk is found"

if ($checkdid.count -gt 0){

##write to settings ###
$settingfile="C:\testing_AI\modules\py\SSD_Zoom_Card_Software_RAID_Basic_Functionality\zoom_card_disks.json"
$settingdata=get-content $settingfile
$newsettingsdata=foreach($line in $settingdata){
if($line -match "disks"){
$line="        " + """disks"": ""$checkdidstr"""
}
$line
}

set-content -Path $settingfile -value $newsettingsdata -Force
new-item -Path $steplog -Force
add-content -Path $steplog -Value "OK, IO meter settings file updated." -Force
add-content -Path $steplog -Value $settingfile -Force
add-content -Path $steplog -Value $newsettingsdata -Force

$results="OK"
$index="Disk is is $($checkdidstr)"

}





######### write log #######



Get-Module -name "outlog"|remove-module
$mdpath=(Get-ChildItem -path "C:\testing_AI\modules\"  -r -file |Where-object{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

#write-host "Do $action!"
outlog $action $results $tcnumber $tcstep $index


  }

    export-modulemember -Function iometer_disksettings