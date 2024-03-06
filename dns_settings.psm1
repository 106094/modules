function dns_settings ([string]$para1,[string]$para2){

$paracheck1=$PSBoundParameters.ContainsKey('para1')

if( $paracheck1 -eq $false -or $para1.length -eq 0 ){
$para1=""
}

if($PSScriptRoot.length -eq 0){
$scriptRoot="C:\testing_AI\modules"
}
else{
$scriptRoot=$PSScriptRoot
}

$action="DNSsettings"
$tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
$tcnumber=((get-content $tcpath).split(","))[0]
$tcstep=((get-content $tcpath).split(","))[1]

$picpath=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\"
if(-not(test-path $picpath)){new-item -ItemType directory -path $picpath |out-null}

$dnsip=$para1
$nonlogflag=$para2

$getinfo=ipconfig
$checkline=$getinfo -match "allion.test"

if($checkline){

$linenu=$getinfo.IndexOf($checkline)
($getinfo|Select-Object -Skip $linenu|Select-Object -First 3|Select-Object -last 1) -match "\d{1,}\.\d{1,}\.\d{1,}\.\d{1,}" |Out-Null
$ipout=$matches[0]


Get-NetIPAddress|ForEach-Object{

if($_.IPAddress -match $ipout -and $_.AddressFamily -eq "IPv4"){
$adtname=$_.InterfaceAlias 
}
}


$timennow=get-date -Format "yyMMdd_HHmmss"
$dnsconfigtxt=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\$($timennow)_step$($tcstep)_dnsconfig_before.txt"
Get-DnsClientServerAddress -InterfaceAlias $adtname|Where-object{$_.AddressFamily -eq "2"}|Out-String|set-content $dnsconfigtxt

if($dnsip.Length -gt 2){
## change dns
Set-DnsClientServerAddress -InterfaceAlias $adtname -ServerAddresses $dnsip
Clear-DnsClientCache
start-sleep -s 30
$timennow=get-date -Format "yyMMdd_HHmmss"
$dnsconfigtxt=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\$($timennow)_step$($tcstep)_dnsconfig_after.txt"
Get-DnsClientServerAddress -InterfaceAlias $adtname|Where-object{$_.AddressFamily -eq "2"}|Out-String|set-content $dnsconfigtxt

$results="NG"
$index="DNS changed to $dnsip fail"

if((get-content $dnsconfigtxt) -match $dnsip){
$results="OK"
$index="DNS changed to $dnsip"
}

}
  
else{
## rollback dns settins
Set-DnsClientServerAddress -InterfaceAlias $adtname -ResetServerAddresses
Clear-DnsClientCache
start-sleep -s 30
$timennow=get-date -Format "yyMMdd_HHmmss"
$dnsconfigtxt=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\$($timennow)_step$($tcstep)_dnsconfig_after.txt"
Get-DnsClientServerAddress -InterfaceAlias $adtname|Where-object{$_.AddressFamily -eq "2"}|Out-String|set-content $dnsconfigtxt

$results="NG"
$index="DNS changed to original settings fail"
if((get-content $dnsconfigtxt) -match "168"){
$results="OK"
$index="DNS changed to original settings"
}


}

## check action result ##


}

else{
$results="-"
$index="no allion.test connected"
}



if($nonlogflag.length -eq 0){

 $index="ipconfig_result.txt"
 
Get-Module -name "outlog"|remove-module
$mdpath=(Get-ChildItem -path "C:\testing_AI\modules\" -r -file |Where-object{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

#write-host "Do $action!"
outlog $action $results $tcnumber $tcstep $index

}

  }

  export-modulemember -Function dns_settings