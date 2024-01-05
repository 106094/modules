
function crystalDiskInfo_Compare ([string]$para1, [string]$para2){
    

$paracheck=$PSBoundParameters.ContainsKey('para1')
$paracheck2=$PSBoundParameters.ContainsKey('para2')

if( $paracheck -eq $false -or $para1.length -eq 0 ){
#write-host "no defined, setting 1 min after login"
$para1="Transfer Mode"
}

if( $paracheck2 -eq $false -or $para2.length -eq 0 ){
#write-host "no defined, setting 1 min after login"
$para2="no_define"
}


    $compareindex=$para1
    $remark=$para2

    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force;
    $wshell=New-Object -ComObject wscript.shell
      Add-Type -AssemblyName Microsoft.VisualBasic
      Add-Type -AssemblyName System.Windows.Forms
        Add-Type -AssemblyName Microsoft.VisualBasic
   
   $tenNums = 35..0
$x=""
$y=""
$z=""
foreach ($x in $tenNums ){
#$x
$y="{$x},$z"
#$y
$z=$y
}
$y=$y.SubString(0,$y.length-1)


if($PSScriptRoot.length -eq 0){
$scriptRoot="C:\testing_AI\modules"
}
else{
$scriptRoot=$PSScriptRoot
}

$action="crystalDiskInfo Compare - $remark - $compareindex"
$index="C:\testing_AI\logs\$($tcnumber)\crystalldiskinfo_results.csv"+"`n"+"C:\testing_AI\logs\$($tcnumber)\DiskInfo\DiskInfo*.txt"
$results=$checkflag

$tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
$tcnumber=((get-content $tcpath).split(","))[0]
$tcstep=((get-content $tcpath).split(","))[1]

$cr_results=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\crystalldiskinfo_results_of_$($compareindex).csv"
$info_path=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\DiskInfo"

if(-not(test-path $cr_results)){

New-Item -ItemType directory -Path $info_path -ErrorAction SilentlyContinue |Out-Null

New-Item -Path $cr_results -ErrorAction SilentlyContinue |Out-Null

$y -f "Time","check_type","result","remark","HDD1","HDD2","HDD3","HDD4","HDD5","HDD6","HDD7","HDD8","HDD9","HDD10","HDD11","HDD12","HDD13","HDD14","HDD15","HDD16" `
,"HDD1_diff","HDD2_diff","HDD3_diff","HDD4_diff","HDD5_diff","HDD6_diff","HDD7_diff","HDD8_diff","HDD9_diff","HDD10_diff","HDD11_diff","HDD12_diff","HDD13_diff","HDD14_diff","HDD15_diff","HDD16_diff" `
 | add-content -path  $cr_results -force  -Encoding  UTF8

}

Start-Process "$($Env:ProgramFiles)\CrystalDiskInfo\DiskInfo64.exe" -ArgumentList "/CopyExit" -wait

$checktime=((Get-ChildItem "$($Env:ProgramFiles)\CrystalDiskInfo\DiskInfo.txt").lastwritetime).ToString()
$DiskInfoRaw  = get-content "$($Env:ProgramFiles)\CrystalDiskInfo\DiskInfo.txt"


$last= import-csv -path $cr_results  -Encoding  UTF8|select -last 1

#$empty= """"","*19+""""""
$y -f "","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","",""| add-content -path  $cr_results -force  -Encoding  UTF8
$writeto= import-csv -path $cr_results  -Encoding  UTF8

$i=0
$checkflag="Pass"

$DiskInfoRaw|%{
if($_ -match $compareindex){
$data= ((($_.replace($compareindex,"")).replace(":","")).replace("  "," ")).trim()
$data
$i++
$col="HDD"+$i
$col2="HDD"+$i+"_diff"

     $writeto[-1].$col=$data

    if($writeto.time.count -eq 1){
    $writeto[-1].$col2="-"
     $writeto[-1]."result"="-"
    }
    else{
    $dataold=$last.$col
    
    $compare= (Compare-Object  $dataold $data   -IncludeEqual).SideIndicator
        if( $compare -eq "=="){$results2 = "SAME"}
        else{$results2 = "Different";$checkflag="Fail"}

     $writeto[-1].$col2=$results2
     $writeto[-1]."result"=$checkflag
     }
     

}
}
     
     $writeto[-1]."check_type"=$compareindex
     $writeto[-1]."remark"=$remark
      $writeto[-1]."Time"=$checktime

    $writeto| export-csv -path $cr_results  -Encoding  UTF8 -NoTypeInformation
    $timea=get-date -format "yyMMdd_HHmmss"
 
    copy-item "$($Env:ProgramFiles)\CrystalDiskInfo\DiskInfo.txt" -Destination "$($info_path)\DiskInfo_$($remark)_$($timea).txt" -Force
  
######### write log #######


Get-Module -name "outlog"|remove-module
$mdpath=(Get-ChildItem -path "C:\testing_AI\modules\"  -r -file |Where-object{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

#write-host "Do $action!"
outlog $action $results $tcnumber $tcstep $index


  }

    export-modulemember -Function crystalDiskInfo_Compare