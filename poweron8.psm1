function poweron8 ([string]$para1,[string]$para2){

  Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force;

  $acdc=$para1
  $nonlog_flag=$para2

if($PSScriptRoot.length -eq 0){
$scriptRoot="C:\testing_AI\modules"
}
else{
$scriptRoot=$PSScriptRoot
}

$tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
$tcnumber=((get-content $tcpath).split(","))[0]
$tcstep=((get-content $tcpath).split(","))[1]
$picpath=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\"
if(-not(test-path $picpath)){new-item -ItemType directory -path $picpath |out-null}
$powerlog1=$picpat+"powercfg_before.txt"
$powerlog2=$picpat+"powercfg_after.txt"

$action="power setting to never"
$index="check powercfg logs"
$results="OK"

#collect original powerset
$poid= (powercfg /getactivescheme).split(" ")|? {$_ -match "-"}
$psettings=powercfg /q $poid

$l=0
$psettings|%{
$l++
if($_ -match "after" ){$_line=$psettings.IndexOf($_)}
$nowlinegap= $l - $_line

if( $nowlinegap -ge 0 -and $nowlinegap -le 10 -and ($_ -match "index" -or$_ -match "after" )){
 $checks=$checks+@($_)
}
}

set-content -path $powerlog1 -value  $checks -Force

#change powerset

powercfg /change monitor-timeout-ac 0
powercfg -change -standby-timeout-ac 0
powercfg /x -hibernate-timeout-ac 0
powercfg /x -disk-timeout-ac 0

if($acdc.Length -gt 0){
powercfg /change monitor-timeout-dc 0
powercfg -change -standby-timeout-dc 0
powercfg /x -hibernate-timeout-dc 0
powercfg /x -disk-timeout-dc 0
}

powercfg.exe /SETACTIVE SCHEME_CURRENT

###show S4 option
REG ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FlyoutMenuSettings" /V ShowHibernateOption /T REG_dWORD /D 1 /F

#collect after change powerset
$checks.clear()
$poid= (powercfg /getactivescheme).split(" ")|? {$_ -match "-"}
$psettings=powercfg /q $poid

$l=0
$psettings|%{
$l++
if($_ -match "after" ){$_line=$psettings.IndexOf($_)}
$nowlinegap= $l - $_line

if( $nowlinegap -ge 0 -and $nowlinegap -le 10 -and ($_ -match "index" -or$_ -match "after" )){
 $checks=$checks+@($_)
}
}

set-content -path $powerlog2 -value  $checks -Force

if($nonlog_flag.Length -gt 0){
Get-Module -name "outlog"|remove-module
$mdpath=(gci -path "C:\testing_AI\modules\" -r -file |?{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

#write-host "Do $action!"
outlog $action $results $tcnumber $tcstep $index
}

  }

  export-modulemember -Function  poweron8