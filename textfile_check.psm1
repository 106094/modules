
function textfile_check ([string]$para1,[string]$para2,[string]$para3){
     
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

$action="text_check"

$tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
$tcnumber=((get-content $tcpath).split(","))[0]
$tcstep=((get-content $tcpath).split(","))[1]

$picpath=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\"
if(-not(test-path $picpath)){new-item -ItemType directory -path $picpath |out-null}

     $checkfile=$para1
     $checkline=$para2
     $checkopp=$para3
 
 $resultpass="PASS"
 $resultfail="FAIL"
 if($checkopp.Length -gt 0){
  $resultpass="FAIL"
 $resultfail="PASS"
 }

    if($checkline.length -eq 0 -or $checkline.length -eq 0 ){
    $results="NG"
    $index="no define file/keywords"
        }
    else{

    $cc=0
    do{
    $cc++
    start-sleep -s 5
    $checkfilefull=(Get-ChildItem $picpath|Where-object{$_.name -match $checkfile}).FullName
    }until($checkfilefull.lenth -ne 0 -or $cc -gt 20)

    if( $cc -gt 20){
    $results= $resultfail
    $index="no match file is found"

    }
    
    if($checkfilefull.count -gt 1){
    $results="NG"
    $index="multi files found, need a specific file name"
    }

if($checkfilefull.count -eq 1 -and  $cc -le 20 ){
 
    write-host "check [$checkfilefull] if contains [$checkline]"

    $txtcontents= get-content $checkfilefull
    
    $m=0
    $mats=@("Match Results:")

    foreach ($txtcontent in $txtcontents){
    
    if($txtcontent -match $checkline){
     $mats=$mats+@($txtcontent)
     $m++
    }
    
    }

    $results= $resultfail
    
    if($m -gt 0){$results= $resultpass}
     $mats=$mats+@("--- End ---")

    }
    }
    
 $index=[string]::Join("`n",$mats)

 
## out-result as txt file ##

$timenow=get-date -Format "yyMMdd_HHmmss"
$outtextpath=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\$($timenow)_step$($tcstep)_textfilecheck_results.txt"

set-content -path $outtextpath -value $index

######### write log  #######

Get-Module -name "outlog"|remove-module
$mdpath=(Get-ChildItem -path "C:\testing_AI\modules\"  -r -file |Where-object{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

#write-host "Do $action!"
outlog $action $results $tcnumber $tcstep $index



  }
    export-modulemember -Function textfile_check