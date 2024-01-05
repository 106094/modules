
function pcmark_CompleteCheck ([int]$para1) {
    
    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force;
    $wshell=New-Object -ComObject wscript.shell
      Add-Type -AssemblyName Microsoft.VisualBasic
      Add-Type -AssemblyName System.Windows.Forms
   
$paracheck=$PSBoundParameters.ContainsKey('para1')

if( $paracheck -eq $false -or $para1 -eq 0 ){
#write-host "no defined, setting 1 min after login"
$para1=60
}

$timelimit=$para1

if($PSScriptRoot.length -eq 0){
$scriptRoot="C:\testing_AI\modules"
}
else{
$scriptRoot=$PSScriptRoot
}

$action="PCMark_CompleteCheck"
$tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
$tcnumber=((get-content $tcpath).split(","))[0]
$tcstep=((get-content $tcpath).split(","))[1]
$picpath=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\"
if(-not(test-path $picpath)){new-item -ItemType directory -path $picpath  -Force |out-null}

$actionss ="screenshot"
Get-Module -name $actionss|remove-module
$mdpath=(Get-ChildItem -path $scriptRoot -r -file |Where-object{$_.name -match "^$actionss\b" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

$checkrunning= get-process -name PCMARK8 -ea SilentlyContinue

if($checkrunning){

$width  = (([string]::Join("`n", (wmic path Win32_VideoController get CurrentHorizontalResolution))).split("`n") -match "\d{1,}")[0]
$height  = (([string]::Join("`n", (wmic path Win32_VideoController get CurrentVerticalResolution))).split("`n") -match "\d{1,}")[0]

  $getlasttime=(Get-ChildItem C:\testing_AI\logs\logs_timemap.csv).lastwritetime
  $nowtime=get-date
  $gaps=(New-TimeSpan  -Start $getlasttime -end $nowtime).TotalMinutes
 
  #$resultfile=Get-ChildItem -path $env:USERPROFILE\documents\3DMark\3DMark.log -ErrorAction SilentlyContinue
   $resultfile2=(Get-ChildItem -path "$env:USERPROFILE\Documents\PCMark 8\Log\*\result.pcmark-8-result" -ErrorAction SilentlyContinue)|Where-object{$_.LastWriteTime -gt $getlasttime}
     #$resultfile3=Get-ChildItem -path $env:USERPROFILE\documents\*.xml -ErrorAction SilentlyContinue

 if($gaps -ge $timelimit -and $resultfile2.count -eq 0){
   $results="NG"
    $Index="No result.pcmark-8-result"
       }
   
 if($gaps -lt $timelimit){ 

   ## running no log yet###
  if($resultfile2.count -eq 0){exit}

   ## result page screenshot###

start-sleep -s 30

&$actionss  -para3 nonlog -para5 score
   
$picfile=(Get-ChildItem $picpath |Where-object{$_.name -match ".jpg" -and $_.name -match "score" }).FullName
 
 copy-item (split-path -parent ($resultfile2.FullName)) -Destination $picpath -Recurse
   
  $results="OK"
  $Index="$picfile"

  }
  }
  else{
  
  $results="NG"
  $Index="no PCMARK8 is running"

  }

   (get-process -name PCMARK8).CloseMainWindow()

######### write log #######

Get-Module -name "outlog"|remove-module
$mdpath=(Get-ChildItem -path "C:\testing_AI\modules\"  -r -file |Where-object{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

#write-host "Do $action!"
outlog $action $results $tcnumber $tcstep $index


  }

    export-modulemember -Function pcmark_CompleteCheck