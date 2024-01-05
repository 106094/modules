

function mvpwrtool (){
    
    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force;
    $wshell=New-Object -ComObject wscript.shell
      Add-Type -AssemblyName Microsoft.VisualBasic
      Add-Type -AssemblyName System.Windows.Forms
        Add-Type -AssemblyName Microsoft.VisualBasic
   

if($PSScriptRoot.length -eq 0){
$scriptRoot="C:\testing_AI\modules"
}
else{
$scriptRoot=$PSScriptRoot
}


$results="OK"
 $pls=@("pwrtest","platcfgw","dtrack")

 foreach($pl in $pls){
 #$pl 
 $pwrtest1= test-path  "C:/dash/tools/pwrtest/$_($pl).exe"
 if( $pwrtest1 -eq $false){
  $fpath=(Get-ChildItem -path $scriptRoot -r -file -filter "*$pl*exe").fullname

  if( (test-path "C:\dash\tools\$pl\") -eq $false){new-item -ItemType directory -Path "C:/dash/tools/$pl/" |Out-Null }
  copy-item  $fpath -Destination "C:/dash/tools/$pl/" -Force
  }
  $pwrtest1= test-path  "C:/dash/tools/$pl/$pl.exe"
   if($pwrtest1 -eq $false){
      $results="NG"
      $index="fail to move power tools"
      # [System.Windows.Forms.MessageBox]::Show($this,"powertool moving fail, please check!")   
      #exit
      }
      else{$index="moving power tools success"}
  }

  
## out-result as txt file ##

$timenow=get-date -Format "yyMMdd_HHmmss"
$outtextpath=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\$($timenow)_$($tcstep)_mvpwrtool_results.txt"

set-content -path $outtextpath -value $index

  
######### write log #######


$action="moving pwrtool"

$tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
$tcnumber=((get-content $tcpath).split(","))[0]
$tcstep=((get-content $tcpath).split(","))[1]

Get-Module -name "outlog"|remove-module
$mdpath=(Get-ChildItem -path "C:\testing_AI\modules\"  -r -file |Where-object{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

#write-host "Do $action!"
outlog $action $results $tcnumber $tcstep $index


  }

    export-modulemember -Function mvpwrtool