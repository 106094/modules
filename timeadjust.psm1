

function timeadjust ([double]$para1){


    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force;
    $wshell=New-Object -ComObject wscript.shell
      Add-Type -AssemblyName Microsoft.VisualBasic
      Add-Type -AssemblyName System.Windows.Forms
 
 
$paracheck=$PSBoundParameters.ContainsKey('para1')
if( $paracheck -eq $false -or $para1 -eq 0){
$para1=0
}

 $addtime= [double]$para1
  
 $time1=get-date -Format "yy/MM/dd HH:mm"
 $timeset = New-TimeSpan -Hours $addtime
 Set-Date -Adjust $timeset
 $time2=get-date -Format "yy/MM/dd HH:mm"

if( $time1 -ne  $time2 -OR $addtime -eq 0){$results="OK"}
else{$results="NG"}

$index=  "change from  $time1 to $time2 with time gap:  $addtime Hours"

   
######### write log #######


if($PSScriptRoot.length -eq 0){
$scriptRoot="C:\testing_AI\modules"
}
else{
$scriptRoot=$PSScriptRoot
}


$action="System time adjust"
$tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
$tcnumber=((get-content $tcpath).split(","))[0]
$tcstep=((get-content $tcpath).split(","))[1]

Get-Module -name "outlog"|remove-module
$mdpath=(gci -path "C:\testing_AI\modules\"  -r -file |?{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

#write-host "Do $action!"
outlog $action $results $tcnumber $tcstep $index


  }

    export-modulemember -Function timeadjust