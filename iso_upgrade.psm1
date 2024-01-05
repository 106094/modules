
function iso_upgrade ([string]$para1,[string]$para2){
      
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
$runninglog=$picpath+"step$($tcstep)_isoinstall.log"
$results="OK"

$startflag=0
if(!(test-path $runninglog)){
$startflag=1
new-item -path $runninglog -Force
}


 $Version = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\'

$winflag="Win10"
if($Version.CurrentBuildNumber -ge 22000){
$winflag="Win11"
}

if($isofile.Length -eq 0){ $isopath=(Get-ChildItem $picpath -Recurse |Where-Object{$_.name -match "\.iso"}|Where-Object{$_.fullname -match $winflag}).FullName}
else{$isopath=(Get-ChildItem $picpath -Recurse |Where-Object{$_.name -match "\.iso" -and $_.name -match $isofile }).FullName}
if($isopath.length -eq 0 -or $isopath.count -ne 1){
$results="NG"
$index=$index+@("no iso file or multi iso file is found")
}

else{

# start running 1st time only

if($startflag -eq 1){

write-host "install $isopath"

Mount-DiskImage -ImagePath $isopath |Out-Null

write-host "mount disk"

do{
Start-Sleep -s 10
$diskle=(get-DiskImage -ImagePath $isopath|Get-Volume).DriveLetter
}until($diskle)

$osup=$($diskle)+":"+"\setup.exe"

$nowtime=Get-Date

#$installiso= &$osup /auto upgrade /eula accept /quiet /migratedrivers all /DynamicUpdate disable /Finalize
#https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/windows-setup-command-line-options?view=windows-11
#$installiso= &$osup /auto upgrade /eula accept /SkipFinalize /quiet /migratedrivers all /DynamicUpdate disable　/ShowOOBE none
$installiso= &$osup /auto upgrade /eula accept /quiet /migratedrivers all /DynamicUpdate disable /ShowOOBE none

do{
Start-Sleep -s 10
$nowtime2=Get-Date
$setuprun=get-process setup -ea SilentlyContinue
$timepass=(New-TimeSpan -start $nowtime -End $nowtime2).TotalSeconds 
} until($setuprun -or $timepass -gt 60)

if($setuprun){
$index=$index+@("iso installing start $nowtime")
write-host "iso installing start $nowtime"
add-content $runninglog -value "iso installing start $nowtime"
}

else{
$results="NG"
$index=$index+@("fail to start running within 60 seconds")
add-content $runninglog -value "fail to start running within 60 seconds"
}

}

# check finished (after reboot)
if($results -ne "NG"){

do{
Start-Sleep -s 60
$setuprun1=get-process setup -ea SilentlyContinue
Start-Sleep -s 60
$setuprun2=get-process setup -ea SilentlyContinue
} until(!$setuprun1 -and !$setuprun2)

Dismount-DiskImage -ImagePath $isopath -ErrorAction SilentlyContinue |Out-Null
write-host "dismount"
$nowtime=Get-Date
$index=$index+@("iso installing completed $nowtime")
add-content -path $runninglog -value "iso installing completed $nowtime"
write-host "wait for 10 minutes"
Start-Sleep -s 600
add-content -path $runninglog -value "C:\Windows\setupact.log"
add-content -path $runninglog -value (get-content "C:\Windows\setupact.log")

}

}


$index=$index|Out-String
write-host "$results,$index"

######### write log  #######

if($nonlog_flag.Length -eq 0){
Get-Module -name "outlog"|remove-module
$mdpath=(Get-ChildItem -path "C:\testing_AI\modules\"  -r -file |Where-Object{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

#write-host "Do $action!"
outlog $action $results $tcnumber $tcstep $index

  }
  

  }

  
    export-modulemember -Function iso_upgrade