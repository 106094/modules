
function textfile_compare ([string]$para1,[string]$para2,[string]$para3 ){
     
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

$action="text_compare"

$tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
$tcnumber=((get-content $tcpath).split(","))[0]
$tcstep=((get-content $tcpath).split(","))[1]

$picpath=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\"
if(-not(test-path $picpath)){new-item -ItemType directory -path $picpath |out-null}

     $checkfile=$para1
     $checkfile2=$para2
     $nonlog_flag=$para3


    $filename1=(Get-ChildItem $picpath |Where-object{$_.name -match $checkfile}).FullName
    $filename2=(Get-ChildItem $picpath |Where-object{$_.name -match $checkfile2}).FullName

   # echo "$filename1, $filename1, $($checkfile.length), $($checkfile2.length), $($filename1.count), $($filename2.count)"


    if($checkfile.length -eq 0 -or $checkfile2.length -eq 0 -or  $filename1.count -ne 1 -or $filename2.count -ne 1 ){
    $results="NG"
    $index="no define file/keywords or multi files were found"
        }
    else{
    
    $filect1a=get-content $filename1|Out-String
    $filect2a=get-content $filename2|Out-String

    $filect1=((get-content $filename1|Out-String).ToLower() -replace 'w\d{2}\w\d{1}','' ) -replace '\d+|\W+|\r?\n', ''
    $filect2=((get-content $filename2|Out-String).ToLower() -replace 'w\d{2}\w\d{1}','' ) -replace '\d+|\W+|\r?\n', ''
    $timenow=get-date -Format "yyMMdd_HHmmss"
    $index="$($filename1):`n$($filect1a)`n`n$($filename2):`n$($filect2a)"
    if($filect1 -eq $filect2){
      $results="PASS"
      $outtextpath=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\$($timenow)_step$($tcstep)_textcompare_SAME.txt"
    }
    else{
    $results="NG"
    $outtextpath=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\$($timenow)_step$($tcstep)_textcompare_Different.txt"
    }

}


## out-result as txt file ##

set-content -path $outtextpath -value $index
$index="check $outtextpath"
######### write log  #######

if($nonlog_flag.Length -eq 0){
Get-Module -name "outlog"|remove-module
$mdpath=(Get-ChildItem -path "C:\testing_AI\modules\"  -r -file |Where-object{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

#write-host "Do $action!"
outlog $action $results $tcnumber $tcstep $index

  }


  }
    export-modulemember -Function textfile_compare