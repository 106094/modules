
function getresult([string]$para1){

    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force;
    $wshell=New-Object -ComObject wscript.shell
      Add-Type -AssemblyName Microsoft.VisualBasic
      Add-Type -AssemblyName System.Windows.Forms
       Add-Type -AssemblyName System.Windows.Forms,System.Drawing

$paracheck=$PSBoundParameters.ContainsKey('para1')

if( $paracheck -eq $false -or $para1.length -eq 0 ){
#write-host "no defined, setting 1 min after login"
$para1="passmark"
}

$result_type=$para1
$action = "get results - $result_type"

if($PSScriptRoot.length -eq 0){
$scriptRoot="C:\testing_AI\modules"
}
else{
$scriptRoot=$PSScriptRoot
}

$tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
$tcnumber=((get-content $tcpath).split(","))[0]
$tcstep=((get-content $tcpath).split(","))[1]
$logpath=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\"

$width  = ([string]::Join("`n", (wmic path Win32_VideoController get CurrentHorizontalResolution))).split("`n") -match "\d{1,}"
$height  = ([string]::Join("`n", (wmic path Win32_VideoController get CurrentVerticalResolution))).split("`n") -match "\d{1,}"

  if(-not(test-path  $logpath)){new-item -ItemType directory -path $picpath |out-null}


if($result_type -match "passmark"){

  $resultfile=Get-ChildItem -path C:\testing_AI\logs\passmark*.log
  
  if($resultfile.count -ne 0){
  
  move-Item C:\testing_AI\logs\passmark*.log $logpath -Force
    move-Item C:\testing_AI\logs\passmark*.htm $logpath -Force
  
  $resultfilename= (Get-ChildItem $logpath -Filte "passmark*.log"|sort lastwritetime|select -last 1).fullname

  $results="OK"
  $Index= $resultfilename

  }

  else{
    $results="NG"
  $Index= "No results. please check bitconfig settings"

  }

}

if($result_type -match "3dmark"){

  $getlasttime=(Get-ChildItem -path C:\testing_AI\logs\logs_timemap.csv).lastwritetime
  $nowtime=get-date
  $gaps=(New-TimeSpan  -Start $getlasttime -end  $nowtime).TotalMinutes
  $Index=""
 
  $resultfile=Get-ChildItem -path $env:USERPROFILE\documents\3DMark\3DMark.log -ErrorAction SilentlyContinue
   $resultfile2=Get-ChildItem -path $env:USERPROFILE\documents\3DMark\*.3dmark-result -ErrorAction SilentlyContinue
     $resultfile3=Get-ChildItem -path $env:USERPROFILE\documents\3DMark\*.xml -ErrorAction SilentlyContinue
       $resultfile32=Get-ChildItem -path $env:USERPROFILE\documents\*.xml -ErrorAction SilentlyContinue


   ## finish with log ###

  if($resultfile.count -ne 0){copy-Item  $env:USERPROFILE\documents\3DMark\3DMark.log $logpath -Force}
  if($resultfile2.count -ne 0){copy-Item $env:USERPROFILE\documents\3DMark\*.3dmark-result $logpath -Force}
  if($resultfile3.count -ne 0){copy-Item $env:USERPROFILE\documents\3DMark\*.xml $logpath -Force}
  if($resultfile32.count -ne 0){copy-Item $env:USERPROFILE\documents\\*.xml $logpath -Force}

  $resultfilename=  [string]::join("`n",$resultfile.BaseName,$resultfile2.BaseName,$resultfile3.BaseName)

  $results="OK"
  $Index=$resultfilename
  
  }
  

########### log #########

Get-Module -name "outlog"|remove-module
$mdpath=(Get-ChildItem -path "C:\testing_AI\modules\" -r -file |?{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

#write-host "Do $action!"
outlog $action $results $tcnumber $tcstep $index


}


  export-modulemember -Function  getresult