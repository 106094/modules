function net_disconnecting ([string]$para1,[string]$para2){

  
if($PSScriptRoot.length -eq 0){
$scriptRoot="C:\testing_AI\modules"
}
else{
$scriptRoot=$PSScriptRoot
}

$action="Netconnection Disable"
$tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
$tcnumber=((get-content $tcpath).split(","))[0]
$tcstep=((get-content $tcpath).split(","))[1]


$logflag=$para2

$adapn=(Get-NetAdapter).Name

$netname_out=@()

Get-NetIPAddress|%{

if($_.InterfaceAlias -in $adapn -and $_.IPAddress -match "\d{1,}\.\d{1,}\.\d{1,}\.\d{1,}" -and $_.AddressFamily -eq "IPv4"){

$adtname=$_.InterfaceAlias 

if($_.IPAddress -match "192.168.2"){$netname_internal=$adtname}
else{$netname_out=$netname_out+@($adtname)}

}
}

##Get-WmiObject win32_networkadapter | select  NetConnectionID, Description |?{$_.netconnectionid -ne $null}
$netcountall=(Get-NetAdapter).count
$netnames=(((Get-NetAdapter)|?{$_.status -eq "UP"}).name)

if($para1 -eq "internet"){$netnames=$netname_out}
if($para1 -eq "local"){$netnames=$netname_internal}
$results="OK"
  foreach($netname in $netnames){
  #Enable-NetAdapter -Name $netname -Confirm:$false
  Disable-NetAdapter -Name $netname -Confirm:$false
  start-sleep -s 10
  $netstatus=((Get-NetAdapter)|?{$_.Name -eq $netname}).status
  if($netstatus -eq "Up"){
  $results="NG"
  }
  }
  
  #$netname=[string]::Join("/",((Get-NetAdapter)|?{$_.status -ne "UP"}).name)


if($logflag.length -eq 0){

$picpath=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\"
if(-not(test-path $picpath)){new-item -ItemType directory -path $picpath |out-null}

$timennow=get-date -Format "yyMMdd_HHmmss"
$ipconfigtxt=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\$($timennow)_step$($tcstep)_ipconfig_result.txt"
ipconfig|set-content $ipconfigtxt

 $index="ipconfig_result.txt"
 
Get-Module -name "outlog"|remove-module
$mdpath=(gci -path "C:\testing_AI\modules\" -r -file |?{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

#write-host "Do $action!"
outlog $action $results $tcnumber $tcstep $index

}

  }

  export-modulemember -Function net_disconnecting