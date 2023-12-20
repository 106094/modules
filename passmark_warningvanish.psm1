

function passmark_warningvanish (){
    
    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force;
    $wshell=New-Object -ComObject wscript.shell
      Add-Type -AssemblyName Microsoft.VisualBasic
      Add-Type -AssemblyName System.Windows.Forms
   
  $checkpassmarkrun= (get-process -name bit -ea SilentlyContinue).id
  if($checkpassmarkrun){ 
  ##### pcaui delete ###
  $checkpcaui= ((get-process pcaui -ea SilentlyContinue).id).count
  if($checkpcaui -gt 0){
    [Microsoft.VisualBasic.Interaction]::AppActivate("program")
    Start-Sleep -s 1
      [System.Windows.Forms.SendKeys]::SendWait("{tab 2}")
      Start-Sleep -s 1
       [System.Windows.Forms.SendKeys]::SendWait(" ")
       Start-Sleep -s 1
        [System.Windows.Forms.SendKeys]::SendWait("{tab 2}")
        Start-Sleep -s 1
       [System.Windows.Forms.SendKeys]::SendWait(" ")
       Start-Sleep -s 1
       (get-process pcaui)|Stop-Process -Force

       $results="ok"
       $index="warning messages vanished"

  }

  else{
  $results="OK"
  $index="no warning is found"}

  }
  else{
  $results="-"
  $index="No Passmark Program is Running"
  }

  write-host "$results, $index"
   Start-Sleep -s 5
        
  
######### write log #######


if($PSScriptRoot.length -eq 0){
$scriptRoot="C:\testing_AI\modules"
}
else{
$scriptRoot=$PSScriptRoot
}

$action="passmark_warningvanish"

$tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
$tcnumber=((get-content $tcpath).split(","))[0]
$tcstep=((get-content $tcpath).split(","))[1]

Get-Module -name "outlog"|remove-module
$mdpath=(gci -path "C:\testing_AI\modules\"  -r -file |?{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

#write-host "Do $action!"
outlog $action $results $tcnumber $tcstep $index


  }

    export-modulemember -Function passmark_warningvanish