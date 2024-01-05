
function pnpuninstall([string]$para1,[string]$para2){
    
    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force;
    $wshell=New-Object -ComObject wscript.shell
      Add-Type -AssemblyName Microsoft.VisualBasic
      Add-Type -AssemblyName System.Windows.Forms
      
$infname=$para1
$nonlog_flag=$para2

if($PSScriptRoot.length -eq 0){
$scriptRoot="C:\testing_AI\modules"
}
else{
$scriptRoot=$PSScriptRoot
}


$actionss ="screenshot"
Get-Module -name $actionss|remove-module
$mdpath=(Get-ChildItem -path $scriptRoot -r -file |?{$_.name -match "^$actionss\b" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

$action="PnP_Uninstall"

$tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
$tcnumber=((get-content $tcpath).split(","))[0]
$tcstep=((get-content $tcpath).split(","))[1]

$picpath=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\"
if(-not(test-path $picpath)){new-item -ItemType directory -path $picpath |out-null}
$datenow=get-date -format "yyMMdd_HHmmss"
$enumerate_pubf="$picpath$($datenow)_step$($tcstep)_enumerate_pnpuninstall_before.txt"

## collect 
$enumd=pnputil /enum-drivers
set-content $enumerate_pubf -value $enumd -Force

## uninstall by pnp ##

$List = New-Object System.Collections.ArrayList
((pnputil /enum-drivers | 
Select-Object -Skip 2) | 
Select-String -Pattern 'Published Name:' -Context 0,7) | 
ForEach {
if($PSItem.Context.PostContext[4] -like "*Class Version:*"){
$ClassVersion = $PSItem.Context.PostContext[4] -replace '.*:\s+'
$DriverVersion = $PSItem.Context.PostContext[5] -replace '.*:\s+'
$SignerName = $PSItem.Context.PostContext[6] -replace '.*:\s+'
}else{
$ClassVersion = "N/A"
$DriverVersion = $PSItem.Context.PostContext[4] -replace '.*:\s+'
$SignerName = $PSItem.Context.PostContext[5] -replace '.*:\s+'
}
    $y = New-Object PSCustomObject
        $y | Add-Member -Membertype NoteProperty -Name PublishedName -value (($PSitem | Select-String -Pattern 'Published Name:' ) -replace '.*:\s+')
        $y | Add-Member -Membertype NoteProperty -Name OriginalName -value (($PSItem.Context.PostContext[0]) -replace '.*:\s+')
        $y | Add-Member -Membertype NoteProperty -Name ProviderName -value (($PSItem.Context.PostContext[1]) -replace '.*:\s+')
        $y | Add-Member -Membertype NoteProperty -Name ClassName -value (($PSItem.Context.PostContext[2]) -replace '.*:\s+')
        $y | Add-Member -Membertype NoteProperty -Name ClassGUID -value (($PSItem.Context.PostContext[3]) -replace '.*:\s+')
        $y | Add-Member -Membertype NoteProperty -Name ClassVersion -value $ClassVersion
        $y | Add-Member -Membertype NoteProperty -Name DriverVersion -value $DriverVersion
        $y | Add-Member -Membertype NoteProperty -Name SignerName -value $SignerName
        $z = $List.Add($y)
}

$dupinfnames=$infname
if($dupinfnames.Length -eq 0){
$dupinfnames=(Get-ChildItem $picpath -Recurse -filter "*.inf").name
}
$PublishedNames=$null
foreach($dupinfname in $dupinfnames){
$PublishedNames=$PublishedNames+@(($List|?{$dupinfname -eq $_.OriginalName } ).PublishedName)
}
write-host "matched publish name"
$PublishedNames

foreach($PublishedName in $PublishedNames){
 $infname=($List|?{$dupinfname -eq $_.PublishedName } ).OriginalName
   write-host "execute pnputil /delete-driver $PublishedName($($infname)) /force"
$unstallresult=pnputil /delete-driver $PublishedName /force

do{
start-sleep -s 1
}until(!(get-process -name pnputil))

 write-host "$PublishedName : $unstallresult"
   $index=$index+@("$PublishedName"+" : "+$unstallresult|Out-String)

}

$datenow=Get-Date -Format "yyMMdd_HHmmss"
$enumerate_puafter="$picpath$($datenow)_step$($tcstep)_enumerate_pnpuninstall_after.txt"
$inflist="$picpath$($datenow)_step$($tcstep)_inf_list.txt"
$enumd=pnputil /enum-drivers
set-content $enumerate_puafter -value $enumd -Force
set-content $inflist -value $dupinfnames -Force

$index=$index|Out-String

$datenow=get-date -format "yyMMdd_HHmmss"
$pnplogpath=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\$($datenow)_step$($tcstep)_pnpuninstall.txt"

set-content -path $pnplogpath -Value $index

$results="OK"
if($index -match "fail"){
$results="NG"
}

$index="check pnpuninstall.txt"
######### write log #######

if($nonlog_flag.Length -eq 0 -or $timespanmin -gt 30){
Get-Module -name "outlog"|remove-module
$mdpath=(Get-ChildItem -path "C:\testing_AI\modules\"  -r -file |?{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

#write-host "Do $action!"
outlog $action $results $tcnumber $tcstep $index
}
  }

    export-modulemember -Function pnpuninstall