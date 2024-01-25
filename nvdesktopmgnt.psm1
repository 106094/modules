
function nvdesktopmgnt ([string]$para1,[string]$para2,[string]$para3){
    
    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force;
    #$wshell=New-Object -ComObject wscript.shell
      Add-Type -AssemblyName Microsoft.VisualBasic
      Add-Type -AssemblyName System.Windows.Forms
        Add-Type -AssemblyName Microsoft.VisualBasic
   

if($para1.length -eq 0){
$para1= "enable"
}
else{
$para1= "disable"
}

if($para2.length -eq 0){
  $para2= ""
  }
  else{
  $para2= "taskbar"
  }

$switches=$para1
$openfrom=$para2
$nonlog_flag=$para3

if($PSScriptRoot.length -eq 0){
$scriptRoot="C:\testing_AI\modules"
}
else{
$scriptRoot=$PSScriptRoot
}

$actionpcai="pcai"
Get-Module -name $actionpcai|remove-module
$mdpath=(Get-ChildItem -path $scriptRoot -r -file |Where-object{$_.name -match "^$actionpcai\b" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

$actionapp="startmenuapp"
Get-Module -name $actionapp|remove-module
$mdpath=(Get-ChildItem -path $scriptRoot -r -file |Where-object{$_.name -match "^$actionapp\b" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

$action="start NV Desktop Management - $switches"
$tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
$tcnumber=((get-content $tcpath).split(","))[0]
$tcstep=((get-content $tcpath).split(","))[1]
$picpath=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\"
if (-not(test-path $picpath)){New-Item -ItemType directory $picpath }
$results="NG"
$index=" Desktop Management - $switches Failed"

$n=0

do{
 
  $n++ 
  if ($openfrom -eq "taskbar"){
   &$actionpcai -para1 "nvdt_StartAppByTaskbar" -para5 "nolog"
   }
    else{
    &$actionapp "NVIDIA RTX Desktop Manager" -para3 "nolog"
    }

    if($switches -eq "enable" ){
    &$actionpcai -para1 "NvDesktopMngEnableClick" -para5 "nolog"
    Start-Sleep -s 30
    $actioncheck=(get-process -name "nviewMain64").Id
        if( $actioncheck.count -gt 0){ 
          $results="OK"
         }
        }
    if($switches -eq "disable" ){
    &$actionpcai -para1 "NvDesktopMngDisableClick" -para5 "nolog"
    Start-Sleep -s 30
    $actioncheck=(get-process -name "nviewMain64").Id
        if( $actioncheck.count -eq 0){ 
          $results="OK"
         }
        }

    if($results -eq "OK"){
      $index=" Desktop Management - $switches Passed"
    }
    else{
      (get-process -name nvwdmcpl).CloseMainWindow()
      Start-Sleep -s 10
    }
    
  
}until($results -eq "OK" -or $n -gt 3)


######### write log #######
if($nonlog_flag.Length -eq 0){
  
Get-Module -name "outlog"|remove-module
$mdpath=(Get-ChildItem -path "C:\testing_AI\modules\"  -r -file |Where-object{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

#write-host "Do $action!"
outlog $action $results $tcnumber $tcstep $index
}

  }

    export-modulemember -Function nvdesktopmgnt