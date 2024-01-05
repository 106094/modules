function copyingfiles_toserver ([string]$para1,[string]$para2,[string]$para3,[string]$para4){
    
    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force;
    $wshell=New-Object -ComObject wscript.shell
      Add-Type -AssemblyName Microsoft.VisualBasic
      Add-Type -AssemblyName System.Windows.Forms
 
 $filename=$para1
 $compare_flag=$para2
 $delete_flag=$para3
 $nonlog_flag=$para4

if($PSScriptRoot.length -eq 0){
$scriptRoot="C:\testing_AI\modules"
}
else{
$scriptRoot=$PSScriptRoot
}

$serverip="192.168.2.249"
do{
start-sleep -s 2
$testpin= ping $serverip /n 3
}until( $testpin -match "Reply from" )


function netdisk_connect([string]$webpath,[string]$username,[string]$passwd,[string]$diskid){
    net use $webpath /delete
    net use $webpath /user:$username $passwd /PERSISTENT:yes
    net use $webpath /SAVECRED 

    if($diskid.length -ne 0){
        $diskpath=$diskid+":"
        $checkdisk=net use
    if($checkdisk -match $diskpath){net use $diskpath /delete}
        net use $diskpath $webpath
    }
}

netdisk_connect -webpath \\192.168.2.249\srvprj\Inventec\Dell -username pctest -passwd pctest -diskid Y

$action="copying  $filename from Log folder to server "
$tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
$tcnumber=((get-content $tcpath).split(","))[0]
$tcstep=((get-content $tcpath).split(","))[1]

$logpath=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\"
if(-not(test-path $logpath)){new-item -ItemType directory -path $logpath -Force|Out-Null}

$filecopyfrom=Get-ChildItem $logpath -Recurse |Where-object{$_.name -match $filename}


 if($filecopyfrom.length -ne 0){
 $dutname=$env:computername
 $datenow=get-date -format "yyMMdd_HHmmss"
 $copytofolder="Y:\Matagorda\07.Tool\_AutoTool\copyfiles\from_DUT\$($datenow)_$($dutname)_$($tcnumber)_step$($tcstep)\"

 if(!(test-path $copytofolder)){new-item -ItemType directory  $copytofolder -Force |out-null }
 
 $results="OK"
 foreach($filecopy in $filecopyfrom){
 $copyffullname=$filecopy.fullname
 $copyfname=$filecopy.name
 copy-item $copyffullname -Destination  $copytofolder -Force
 $destifn=$copytofolder+ $copyfname
 $check1=( Get-ChildItem $copyffullname).Length
 $check2=( Get-ChildItem $destifn).Length
 if($check1 -ne $check2){
  $results="NG"
  $index=$index+@("$copyfname copy fail")
 }

 }


### check info ##

$runaction="cmdline"
Get-Module -name $runaction|remove-module
$mdpath=(Get-ChildItem -path "C:\testing_AI\modules\"  -r -file |Where-object{$_.name -match "^$runaction\b" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

&$runaction  -para1 "Get-ChildItem $copytofolder" -para3 "powershell" -para5 "nolog"

#comp
$oripath = $copytofolder + $filename
$despath = $logpath + $filename

if($compare_flag.Length -ne 0){
    
    $datenow=get-date -format "yyMMdd_HHmmss"
    &$runaction  -para1 "comp /m /d $oripath $despath > $logpath$($datenow)_step$($tcstep)_compf.txt" -para3 'cmd' -para5 'nolog'

    $action = $action + ", and compare both file"
    $comp = Get-Content "$logpath$($datenow)_step$($tcstep)_compf.txt"
    if($comp -match "OK"){
        $results += ",compare OK"
    }else{
        $results += ",compare NG"
    }
}

#delete
if($delete_flag.Length -ne 0){
    $action = $action + ", and delete copy to server file"
    if(Test-Path $oripath){
        Remove-Item $oripath
        $output = "Delete $($filename) from $($copytofolder)"
        $output | Out-File -FilePath "$logpath$($datenow)_step$($tcstep)_deleteInfo.txt"
        $results += ",delete OK"
        &$runaction  -para1 "dir $copytofolder" -para3 "cmd" -para5 "nolog"
    }else{
        $results += ",delete NG"
    }
}

$index=$index|out-string
}


else{
$results="NG"
$index="no copied file is found in log folder"
}

if($index.length -ne 0){$index=$index|out-string}
else{$index="check logs"}

######### write log #######
if( $nonlog_flag.Length -eq 0){

Get-Module -name "outlog"|remove-module
$mdpath=(Get-ChildItem -path "C:\testing_AI\modules\"  -r -file |Where-object{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

#write-host "Do $action!"
outlog $action $results $tcnumber $tcstep $index
}

  }

    export-modulemember -Function copyingfiles_toserver