function copyingfiles ([string]$para1,[string]$para2,[string]$para3){
    
    #import
    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force;
    $shell=New-Object -ComObject shell.application
    $wshell=New-Object -ComObject wscript.shell
    Add-Type -AssemblyName Microsoft.VisualBasic
    Add-Type -AssemblyName System.Windows.Forms

    
    $filepath=$para1
    $copytopath=$para2
    $nonlog_flag=$para3
 
    if($PSScriptRoot.length -eq 0){
      $scriptRoot="C:\testing_AI\modules"
    }
    else{
      $scriptRoot=$PSScriptRoot
    }

    if($filepath -match "192.168.2.249"){
      do{
      start-sleep -s 2
      $testpin= ping 192.168.2.249 /n 3
      }until( !($testpin -match "unreachable" -or $testpin -match "Request timed out" -or $testpin -match "failed"))


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

      $filepath= $filepath.replace("\\192.168.2.249\srvprj\Inventec\Dell","Y:")

    }

    $waitc=0
    do{
    start-sleep -s 2
    $checkfilelink=(test-path  $filepath)
    $waitc++
    }until($checkfilelink -or $waitc -gt 30)

if ($waitc -le 30 -and $checkfilelink){

$action="copying files to logs folder from $filepath "
$tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
$tcnumber=((get-content $tcpath).split(","))[0]
$tcstep=((get-content $tcpath).split(","))[1]
$logpath=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)"
if(-not(test-path $logpath)){new-item -ItemType directory -path $logpath -Force|Out-Null}
 $type_folder=$false

if($copytopath.Length -eq 0){
$copytopath=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\copydata\"
if(-not(test-path $copytopath)){new-item -ItemType directory -path $copytopath -Force|Out-Null}
}
if($filepath.length -ne 0 ){
$filename=($filepath.split("\\"))[-1]

  ## if copy a folder files
   if($filepath.Substring($filepath.Length-1,1) -match "\\"){
 $type_folder=$true
 $filepath= $filepath+"*"
 } 

$copyfroms=Get-ChildItem $filepath -file -Recurse
if($copytopath -eq "C:\" -or $copytopath -eq "C:\Windows\System32\"){
$copyfile0=(Get-ChildItem $copytopath\*).count
}
else{
$copyfile0=(Get-ChildItem $copytopath\* -r ).count
}

copy-Item -Path  $filepath -Destination $copytopath -Recurse -Exclude "System Volume Information" -Force

if($copytopath -eq "C:\" -or $copytopath -eq "C:\Windows\System32\"){
$copyfroms=Get-ChildItem $filepath -file
}
else{
$copyfroms=Get-ChildItem $filepath -file -Recurse
}

if($copytopath -eq "C:\" -or $copytopath -eq "C:\Windows\System32\"){
$copyfile1=(Get-ChildItem $copytopath\*).count
}
else{
$copyfile1=(Get-ChildItem $copytopath\* -r).count
}

$copyfilecount=$copyfile1-$copyfile0
write-host "Folder files $($copyfilecount) files copied"
 
### check info ##

$runaction="cmdline"
Get-Module -name $runaction|remove-module
$mdpath=(Get-ChildItem -path "C:\testing_AI\modules\"  -r -file |?{$_.name -match "^$runaction\b" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

if($copytopath -eq "C:\" -or $copytopath -eq "C:\Windows\System32\" -or $type_folder -eq $false){
&$runaction  -para1 "dir $filename" -para2 "$copytopath" -para3 "cmd" -para5 "nolog"
}
else{
&$runaction  -para1 "dir /s" -para2 "$copytopath" -para3 "cmd" -para5 "nolog"
}

$results="OK"
foreach($copyfrom in $copyfroms){
if($copytopath -eq "C:\" -or $copytopath -eq "C:\Windows\System32\" ){
$size=(Get-ChildItem "$copytopath\*" -file |?{$_.name -eq $copyfrom.name}).Length
}
else{
$size=(Get-ChildItem "$copytopath\*" -file -Recurse |?{$_.name -eq $copyfrom.name}).Length
}

if($size -ne $copyfrom.Length){
$results="NG"
}
}

$index="check $copytopath and cmd logs"
}

else{
$results="NG"
$index="no define copy from path"
}

}

else{
$results="NG"
$index="no defined path is found after waiting 60s"

}
######### write log #######
if( $nonlog_flag.Length -eq 0){

Get-Module -name "outlog"|remove-module
$mdpath=(Get-ChildItem -path "C:\testing_AI\modules\"  -r -file |?{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

#write-host "Do $action!"
outlog $action $results $tcnumber $tcstep $index
}

  }

    export-modulemember -Function copyingfiles