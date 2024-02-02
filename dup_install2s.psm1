function dup_install2s([string]$para1,[string]$para2,[string]$para3,[string]$para4){
    
   Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force;
    #$wshell=New-Object -ComObject wscript.shell
      Add-Type -AssemblyName Microsoft.VisualBasic
      Add-Type -AssemblyName System.Windows.Forms

$duptype=$para1
$extractorinstall=$para2
$nversion=$para3
$nonlog_flag=$para4

if($PSScriptRoot.length -eq 0){
$scriptRoot="C:\testing_AI\modules"
}
else{
$scriptRoot=$PSScriptRoot
}

if($nversion.Length -eq 0 -or $nversion -match "^n\b"){
    $nversion="n"
}
else{
    $nversion="n-1"
}

$actionexp="filexplorer"
Get-Module -name $actionexp|remove-module
$mdpath=(Get-ChildItem -path $scriptRoot -r -file |Where-object{$_.name -match "^$actionexp\b" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

$actionss ="screenshot"
Get-Module -name $actionss|remove-module
$mdpath=(Get-ChildItem -path $scriptRoot -r -file |Where-object{$_.name -match "^$actionss\b" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

$actiontype=$extractorinstall
if($actiontype.Length -eq 0){$actiontype="extract_and_install"}
$action="DUP $($actiontype) (unattached)"

$tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
$tcnumber=((get-content $tcpath).split(","))[0]
$tcstep=((get-content $tcpath).split(","))[1]

$picpath=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\"
if(-not(test-path $picpath)){new-item -ItemType directory -path $picpath |out-null}

$results="OK"
$index="DUP $($actiontype) ok"

#defaul dup filename collect

$installfile=(Get-ChildItem ($scriptRoot+"\driver\$($duptype)\$($nversion)\") -File |Where-object{$_.name -match "\.exe"} |Sort-Object lastwritetime|Select-Object -first 1).fullname
 $installfilebn=(split-path -Leaf $installfile) -replace "\.exe",""

 if($installfile){

$dupname10=$installfilebn.substring(0,10)

## stop running ##
 
if($dupname10.Length -gt 0){
stop-process -name "$dupname10*" -ea SilentlyContinue
}
## extract ##

 if($extractorinstall.Length -eq 0 -or $extractorinstall -match "extract"){
    
    $extractpath=$picpath+"step$($tcstep)_$($duptype)_DUPextract"
    $logpath_extract=$picpath+"step$($tcstep)_$($duptype)_extract.log"
    
    $logpath_result=$picpath+"step$($tcstep)_$($duptype)_checkextract.log"
    
    $starttime=get-date
    &$installfile  /s /e=$extractpath /l=$logpath_extract

    do{
    start-sleep -s 5
    $dupid=(get-process -name "$dupname10*" -ea SilentlyContinue).Id
    $timepassed=(New-TimeSpan -start $starttime -End (get-date)).TotalMinutes
    }until (!$dupid -or $timepassed -gt 30)

    if ($timepassed -gt 30){
    $results="NG"
    $index=  $index+@("DUP extract timeout")
    stop-process -name "$dupname10*" -Force
    }
    else{
        Get-ChildItem -path "C:\testing_AI\logs\TC-162415(NoComlete)\dup"|out-string|set-content $logpath_result -Force
    }

   }

## install ##

if($extractorinstall.Length -eq 0 -or $extractorinstall -match "install"){
    $logpath_install=$picpath+"step$($tcstep)_$($duptype)_install.log"
    $logpath_result=$picpath+"step$($tcstep)_$($duptype)_checkapp.log"
    
    $starttime=get-date
    &$installfile  /s  /l=$logpath_install

    do{
    start-sleep -s 5
    $dupid=(get-process -name "$dupname10*" -ea SilentlyContinue).Id
    $timepassed=(New-TimeSpan -start $starttime -End (get-date)).TotalMinutes
    }until (!$dupid -or $timepassed -gt 30)
   
     if ($timepassed -gt 30){ 
        $results="NG"
        $index=  $index+@("DUP install timeout")
        stop-process -name "$dupname10*" -Force
     }
     else{
        Get-AppPackage |Where-Object{$_.name -match $duptype}|out-string|set-content $logpath_result -Force
     }

}

}
else{
$results="NG"
$index="no DUP filename is found"
}

$index=$index|Out-String

######### write log #######

if($nonlog_flag.Length -eq 0 -or $timespanmin -gt 30){
Get-Module -name "outlog"|remove-module
$mdpath=(Get-ChildItem -path "C:\testing_AI\modules\"  -r -file |Where-object{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

#write-host "Do $action!"
outlog $action $results $tcnumber $tcstep $index
}
  }

    export-modulemember -Function  dup_install2s