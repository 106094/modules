

function SetScreenResolution_py ([int]$para1,[int]$para2,[string]$para3){
    
    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force;
    $wshell=New-Object -ComObject wscript.shell
      Add-Type -AssemblyName Microsoft.VisualBasic
      Add-Type -AssemblyName System.Windows.Forms
   

$paracheck=$PSBoundParameters.ContainsKey('para1')
$paracheck2=$PSBoundParameters.ContainsKey('para2')
$paracheck3=$PSBoundParameters.ContainsKey('para3')

if( $paracheck -eq $false -or $para1 -eq 0 ){
$para1=1920
}
if( $paracheck2 -eq $false -or $para2 -eq 0 ){
$para2=1080
}
if( $paracheck3 -eq $false -or $para3.length -eq 0 ){
$para3=""
}

$resx=$para1
$resy=$para2
#$maxtype=$para3
$nonlogflag=$para3


if($PSScriptRoot.length -eq 0){
$scriptRoot="C:\testing_AI\modules"
}
else{
$scriptRoot=$PSScriptRoot
}

$tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
$tcnumber=((get-content $tcpath).split(","))[0]
$tcstep=((get-content $tcpath).split(","))[1]

$timenow=get-date -format "yyMMdd_HHmmss"
#$picpath=(Split-Path -Parent $scriptRoot)+"\logs\screenshot\"
$picpath=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\"
if(-not(test-path $picpath)){new-item -ItemType directory -path $picpath |out-null}

$actionss ="screenshot"
Get-Module -name $actionss|remove-module
$mdpath=(Get-ChildItem -path $scriptRoot -r -file |Where-object{$_.name -match "^$actionss\b" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

### before res change##
      
&$actionss  -para3 nonlog -para5 "before"

$pyrs=$picpath+"resolutionchange.py"

get-content C:\testing_AI\modules\py\resolutionchange.py|%{

if($_ -match "resx"){$_.replace("resx",$resx)}
elseif($_ -match "resy"){$_.replace("resy",$resy)}
else{$_}
}|set-content $pyrs -Force
$pycmd="py $pyrs"
 
 $index=& invoke-Expression "$pycmd" -ErrorAction SilentlyContinue | Out-String

start-sleep -s 10

if(test-path $pyrs){remove-item $pyrs -Force}

 ## after res change##
 
&$actionss  -para3 nonlog -para5 "after"

  $results="OK"
   $Index="check screenshots"

  
######### write log #######

$action="SetScreenResolution to $($resx) x $($resy)"
if($nonlogflag.Length -eq 0){
Get-Module -name "outlog"|remove-module
$mdpath=(Get-ChildItem -path "C:\testing_AI\modules\"  -r -file |Where-object{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

#write-host "Do $action!"
outlog $action $results $tcnumber $tcstep $index
}

  }

    export-modulemember -Function SetScreenResolution_py