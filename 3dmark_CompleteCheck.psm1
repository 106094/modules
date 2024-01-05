
function 3dmark_CompleteCheck ([int]$para1) {
    
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

$action="3DMark_CompleteCheck"
$tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
$tcnumber=((get-content $tcpath).split(","))[0]
$tcstep=((get-content $tcpath).split(","))[1]
$picpath=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\"
if(-not(test-path $picpath)){new-item -ItemType directory -path $picpath  -Force |out-null}

$actionmd ="screenshot"
Get-Module -name $actionmd|remove-module
$mdpath=(Get-ChildItem -path $scriptRoot -r -file |Where-object{$_.name -match "^$actionmd\b" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

$width  = (([string]::Join("`n", (wmic path Win32_VideoController get CurrentHorizontalResolution))).split("`n") -match "\d{1,}")[0]
$height  = (([string]::Join("`n", (wmic path Win32_VideoController get CurrentVerticalResolution))).split("`n") -match "\d{1,}")[0]

  $getlasttime=[DateTime](import-csv -path C:\testing_AI\logs\logs_timemap.csv |select -last 1).time
  $nowtime=get-date
  $gaps=(New-TimeSpan  -Start $getlasttime -end   $nowtime).TotalMinutes
  $Index=""
 
  #$resultfile=Get-ChildItem -path $env:USERPROFILE\documents\3DMark\3DMark.log -ErrorAction SilentlyContinue
   $resultfile2=Get-ChildItem -path $env:USERPROFILE\documents\3DMark\*.3dmark-result -ErrorAction SilentlyContinue
     #$resultfile3=Get-ChildItem -path $env:USERPROFILE\documents\*.xml -ErrorAction SilentlyContinue


 if($gaps -ge $timelimit -and $resultfile2.count -eq 0){
   $results="NG"
    $Index=([string]::join("`n",$Index,"No *.3dmark-result results")).trim()     
       }
   
 if($gaps -lt $timelimit){ 

   ## running no log yet###
  if($resultfile2.count -eq 0){exit}

   ## result page screenshot###

start-sleep -s 30

&$actionmd  -para3 nonlog -para5 score
   
$picfile=(Get-ChildItem $picpath |Where-object{$_.name -match ".jpg" -and $_.name -match "score" }).FullName
 
  $results="OK"
  $Index="$picfile"

  }

  

######### write log #######

Get-Module -name "outlog"|remove-module
$mdpath=(Get-ChildItem -path "C:\testing_AI\modules\"  -r -file |Where-Object{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

#write-host "Do $action!"
outlog $action $results $tcnumber $tcstep $index


  }

    export-modulemember -Function 3dmark_CompleteCheck