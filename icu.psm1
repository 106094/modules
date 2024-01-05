

function icu (){
    
    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force;
    $wshell=New-Object -ComObject wscript.shell
      Add-Type -AssemblyName Microsoft.VisualBasic
      Add-Type -AssemblyName System.Windows.Forms


if($PSScriptRoot.length -eq 0){
$scriptRoot="C:\testing_AI\modules"
}
else{
$scriptRoot=$PSScriptRoot
}

$action="icu data collecting"
$tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
$tcnumber=((get-content $tcpath).split(","))[0]
$tcstep=((get-content $tcpath).split(","))[1]


     $logpath="C:\testing_AI\logs\$($tcnumber)"

    if( -not(test-path  $logpath )){new-item -ItemType directory  $logpath -Force -ea SilentlyContinue |out-null}

  $html1=(Get-ChildItem -Path "$($logpath)\*" -file |Where-object{ $_.name -match "icu-output" -and  $_.name -match ".html"}).FullName
   $xls1=(Get-ChildItem -Path "$($logpath)\*" -file |Where-object{ $_.name -match "icu-output" -and  $_.name -match ".xls"}).FullName
  $icucommand="C:\testing_AI\modules\ICU\icu.exe"
  set-location  $logpath
  & $icucommand
 $html2=(Get-ChildItem -Path "$($logpath)\*" -file |Where-object{ $_.name -match "icu-output" -and  $_.name -match ".html" }).FullName|Where-object{ $_ -notin $html1}
   $xls2=(Get-ChildItem -Path "$($logpath)\*" -file |Where-object{ $_.name -match "icu-output" -and  $_.name -match ".xls"}).FullName |Where-object{ $_ -notin $xls1}

  if($html2.count -eq 1 -and $xls2.count -eq 1){$results="OK"; $index=$html2 + "`n" + $xls2}

  else{  $results="-"; $index="icu results not found please check" }
   
  
######### write log #######


Get-Module -name "outlog"|remove-module
$mdpath=(Get-ChildItem -path "C:\testing_AI\modules\"  -r -file |Where-object{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

#write-host "Do $action!"
outlog $action $results $tcnumber $tcstep $index


  }

    export-modulemember -Function icu