function net_connecting([string]$para1,[string]$para2){
  
  
   $ping = New-Object System.Net.NetworkInformation.Ping

if($PSScriptRoot.length -eq 0){
$scriptRoot="C:\testing_AI\modules"
}
else{
$scriptRoot=$PSScriptRoot
}

$action="Netconnection Enable"
$tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
$tcnumber=((get-content $tcpath).split(","))[0]
$tcstep=((get-content $tcpath).split(","))[1]

$picpath=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\"
if(-not(test-path $picpath)){new-item -ItemType directory -path $picpath |out-null}


$netname=$para1
$logflag=$para2

 function linkaction ($netname) {
 
  #$testping1=ping 192.168.2.249 /n 3
  #$testping2=ping google.com /n 3
  #if($testping1 -match "Reply from" -and !($testping1 -match "unreachable")){$connecting1="local connect ok"}
  #if($testping2 -match "Reply from" -and !($testping2 -match "unreachable")){$connecting2="internet connect ok"}



  #$testping1=($ping.Send("192.168.2.249", 1000)).Status
  #$testping2=($ping.Send("www.google.com", 1000)).Status
  $testping1= Invoke-WebRequest -Uri "192.168.2.249"
  $testping2= Invoke-WebRequest -Uri "www.msn.com"

  #if($testping1 -match "Success"){$connecting1="local connect ok"}
  #if($testping2 -match "Success"){$connecting2="internet connect ok"}
  if($testping1){$connecting1="local connect ok"}
  if($testping2){$connecting2="internet connect ok"}
   
  $connects=@($connecting1,$connecting2)

if(( $connects |Select-String -pattern "ok").count -ne 2){
  
  ## with specific internet name ##
    if($netname.length -ne 0){
   Enable-NetAdapter -Name $netname -Confirm:$false
   start-sleep -s 10
  }

   ## without specific internet name connect all netnames ##
else{

$netnames=(Get-NetAdapter|?{$_.status -ne "UP"}).name

   foreach($netname in $netnames){
  Enable-NetAdapter -Name $netname -Confirm:$false
  #Disable-NetAdapter -Name $netname -Confirm:$false
  start-sleep -s 10
  }
  
  }
  
 $netname=[string]::Join("/",((Get-NetAdapter)|?{$_.status -eq "UP"}).name)
 write-host "connecting after enable: $netname"

  #$netcount2=(((Get-NetAdapter)|?{$_.status -eq "UP"}).name).count
 
   $nowtime=Get-Date

  do{
  start-sleep -s 10
  #$testping01=($ping.Send("192.168.2.249", 1000)).Status
  #$testping02=($ping.Send("www.google.com", 1000)).Status
  $testping01= Invoke-WebRequest -Uri "192.168.2.249"
  $testping02= Invoke-WebRequest -Uri "www.msn.com"

    $timepass= (New-TimeSpan -start $nowtime -end (Get-Date)).TotalSeconds
     #}until(($testping01 -match "Success" -and $testping02 -match "Success") -or $timepass -gt 100)
      }until(($testping01 -and $testping02) -or $timepass -gt 100)

#if fail connect, try renew ipconfig

 if($timepass -gt 100){
    $renew=ipconfig /renew
     $nowtime=Get-Date
       do{
       start-sleep -s 10
       #$testping01=($ping.Send("192.168.2.249", 1000)).Status
       #$testping02=($ping.Send("www.google.com", 1000)).Status
       $testping01= Invoke-WebRequest -Uri "192.168.2.249"
       $testping02= Invoke-WebRequest -Uri "www.msn.com"

        $timepass= (New-TimeSpan -start $nowtime -end (Get-Date)).TotalSeconds
      #}until(($testping01 -match "Success" -and $testping02 -match "Success") -or $timepass -gt 100)
      }until(($testping01 -and $testping02) -or $timepass -gt 100)
    
    }
    
  #if($testping01 -match "Success"){$connecting1="local connect ok"}
  #if($testping02 -match "Success"){$connecting2="internet connect ok"}
  if($testping01){$connecting1="local connect ok"}
  if($testping02){$connecting2="internet connect ok"}
  
  $connects=@($connecting1,$connecting2)
  
  #if($testping1 -match "Reply from" -and !($testping1 -match "unreachable")){$connecting1="local connect ok"}else{$connecting1="local connect fail"}
  #if($testping2 -match "Reply from" -and !($testping2 -match "unreachable")){$connecting2="internet connect ok"}else{$connecting2="internet connect fail"}
    

   }
    
  $connects=[string]::Join("`n", $connects)
  #$testping1=ping 192.168.2.249 /n 3
  #$testping2=ping www.google.com /n 3
  $testping1= Invoke-WebRequest -Uri "192.168.2.249"
  $testping2= Invoke-WebRequest -Uri "www.msn.com"

  #$checkpin=@($testping1,$testping2,$connects)
  $checkpin=@("IP request:$($testping1.StatusDescription)","IP request:$($testping2.StatusDescription)",$connects)
  $checkpin

  }

$linkaction = linkaction

 $results="NG"
if($linkaction -match "local connect ok" -and $linkaction -match "internet connect ok" ){
 $results="OK"
}

if($logflag.length -eq 0){

$timennow=get-date -format "yyMMdd_HHmmss"
$ipconfigtxt=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\$($timennow)_step$($tcstep)_ipconfig_result.txt"
ipconfig|set-content $ipconfigtxt

 $index=$linkaction|Out-String
    
Get-Module -name "outlog"|remove-module
$mdpath=(Get-ChildItem -path "C:\testing_AI\modules\" -r -file |?{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

#write-host "Do $action!"
outlog $action $results $tcnumber $tcstep $index

}
  }

  
  export-modulemember -Function  net_connecting