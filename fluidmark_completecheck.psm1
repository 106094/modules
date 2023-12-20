

function fluidmark_completecheck {
    
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

$action="fluidmark_completecheck"
$tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
$tcnumber=((get-content $tcpath).split(","))[0]
$tcstep=((get-content $tcpath).split(","))[1]

$picpath=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\"
if(-not(test-path $picpath)){new-item -ItemType directory -path $picpath  -Force |out-null}

#$width  = (([string]::Join("`n", (wmic path Win32_VideoController get CurrentHorizontalResolution))).split("`n") -match "\d{1,}")[0]
#$height  = (([string]::Join("`n", (wmic path Win32_VideoController get CurrentVerticalResolution))).split("`n") -match "\d{1,}")[0]

$actionmd="screenshot"
Get-Module -name $actionmd|remove-module
$mdpath=(gci -path $scriptRoot -r -file |?{$_.name -match "^$actionmd\b" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global


$checkrunning=(get-process -name FluidMark).MainWindowTitle

if($checkrunning -eq "FluidMark" ){

exit

}

else {

    start-sleep -s 30

 $wshell.AppActivate('Geeks3D') 

  ##### screen shot ###

 &$actionmd  -para3 nonlog 

 $picfile1=(gci $picpath |?{$_.name -match ".jpg" -and $_.name -match $action -and $_.name -match "step$($tcstep)"}|sort lastwritetime |select -Last 1).FullName
 
(get-process -name FluidMark -ea SilentlyContinue).CloseMainWindow()
  stop-process -name FluidMark -ea SilentlyContinue

 $results="OK"
 $index= $picfile1
   

}
 

######### write log #######

Get-Module -name "outlog"|remove-module
$mdpath=(gci -path "C:\testing_AI\modules\"  -r -file |?{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

#write-host "Do $action!"
outlog $action $results $tcnumber $tcstep $index


  }

    export-modulemember -Function fluidmark_completecheck