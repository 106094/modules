
function initial_copytool ([string]$para1){

    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force;
    $wshell=New-Object -ComObject wscript.shell
      Add-Type -AssemblyName Microsoft.VisualBasic
      Add-Type -AssemblyName System.Windows.Forms
          
$paracheck=$PSBoundParameters.ContainsKey('para1')

if( $paracheck -eq $false -or $para1.length -eq 0 ){
#write-host "no defined, setting 1 min after login"
$para1=""
}

$nonlog_flag=$para1

if($PSScriptRoot.length -eq 0){
$scriptRoot="C:\testing_AI\modules\"
}
else{
$scriptRoot=$PSScriptRoot
}


if(-not(test-path $daver_path)){new-item -ItemType directory $daver_path |Out-Null }

$action="initial_copytool"
$tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
$tcnumber=((get-content $tcpath).split(","))[0]
$tcstep=((get-content $tcpath).split(","))[1]
$picpath=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\"
if(-not(test-path $picpath)){new-item -ItemType directory -path $picpath |out-null}


### create netdisk for file copying##      
            
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

netdisk_connect -webpath \\192.168.2.249\srvprj\Inventec\Dell -username user001 -passwd allion001 -diskid Y

### remove buff ###

$dest="C:\testing_AI"
$shortcutadd="false"

if(!(test-path $dest)){
$shortcutadd="true"
}
else{
  rename-Item "$dest\AutoRun_.bat" "$dest\AutoRun.bat" -Force -ea SilentlyContinue
  Remove-Item "$dest\logs\wait.txt" -Force -ea SilentlyContinue
  start-process cmd -ArgumentList '/c schtasks /delete /TN "Auto_Run" -f' 
$path="$($dest)\logs\logs_timemap.csv" 
 
  if((test-path $path) -eq $true){

########### force  new logs_timemap.csv ########

$logtimemap="C:\testing_AI\logs\logs_timemap.csv"
$current=import-csv  $logtimemap

$day=get-date -format "yyyyMMdd_HHmm"
$path="C:\testing_AI\logs\logs_timemap.csv" 
$path2="C:\testing_AI\logs\logs_timemap2.csv" 
$path3="C:\testing_AI\logs\logs_timemap_backup_$day.csv" 
$title=get-content $path|select -First 1
Set-Content -path $path2  -value $title
Move-Item $path $path3 -Force
Move-Item $path2  $path -Force


}
 }

## define and copy　files

  $autofilesraw = @{
  
  "mainzip" = @{
       rank=1
       filename = "testing_AI.zip"
       copyto = ""
       update = "no"
    }

  "modules" = @{
       rank=2
       filename = "modules\"
       copyto = ""
       update = "yes" 
    }

   "selenium" = @{
       rank=3
       filename = "selenium\"
       copyto = "modules\"
       update = "yes" 
    }

  "BI_config"= @{
       rank=4
       filename= "BI_config\*"
       copyto = "modules\BITools\config\"
       update = "no" 
    }

    "nv_Controlpanel" = @{
       rank=5
       filename = "nv_Controlpanel\"
       copyto = "settings\" 
       update = "yes" 
    }

    "pcai" = @{
        rank=6
        filename = "pcai\Main\"
        copyto = "modules\PC_AI_Tool*\"
        update = "yes" 
    }

    "driverinstall" = @{
        rank=7
        filename = "driver\"
        copyto = "modules\"
        update = "yes" 
    }

     "SPECviewperf13" = @{
       rank=8
       filename = "extra_tools\SPECviewperf13.zip"
       copyto = "modules\BITools\SPECviewperf13\"
       update = "no" 
    }
    "flex" = @{
       rank=9
       filename = "extra_tools\flex.zip"
       copyto = "modules\BITools\flex\"
       update = "no" 
    }

    "3dmark" = @{    
        rank=10
        filename = "extra_tools\3dmark.zip"
        copyto = "modules\BITools\3dmark\"
        update = "no" 
    }

    "CloudGate" = @{
       rank=11
       filename = "extra_tools\cloudgate.zip"
        copyto = "modules\BITools\cloudgate\"
        update = "no" 
    }
    
        
}

$autofiles=$autofilesraw.GetEnumerator()|sort {$_.value.rank}|%{@{$_.Key = $_.Value}} ### hashtable sorting ###

#$autopath="\\192.168.2.24\srvprj\Inventec\Dell\Matagorda\07.Tool\_AutoTool" 
$autopath="Y:\Matagorda\07.Tool\_AutoTool"



$copyfiles=($autofiles.Keys)

foreach ($copyfile in $copyfiles){

$fileinfo=$autofiles.$copyfile
$filename=$autopath+"\"+$fileinfo.filename
$copytopath=$dest+"\"+$fileinfo.copyto
$updateflag=$fileinfo.update

if(!(test-path $copytopath) -or $updateflag -match "yes"){

if($filename -match "\.zip"){

    if(!(test-path $copytopath)){new-item -ItemType directory $copytopath |Out-Null}
    write-host " Item: $copyfile, unzip $filename  to $copytopath"
   $shell.NameSpace($copytopath).copyhere($shell.NameSpace($filename).Items(),16)

}

else{
    if($copytopath -match "\*"){$copytopath=(gi $copytopath).FullName}
    write-host " Item: $copyfile, copy $filename  to $copytopath"
    copy-item $filename -Destination $copytopath -Recurse -Force


}

}

}

## create shortcut

if($shortcutadd -eq "true"){

New-Item -ItemType SymbolicLink -Path $env:USERPROFILE\desktop\ -Name "logs" -Value "C:\testing_AI\logs\" -force -ErrorAction SilentlyContinue | out-null

#New-Item -ItemType SymbolicLink -Path $env:USERPROFILE\desktop\ -Name "testing_AI_link" -Value "C:\testing_AI\" -force -ErrorAction SilentlyContinue | out-null

New-Item -ItemType SymbolicLink -Path $env:USERPROFILE\desktop\ -Name "AutoRun.bat" -Value "C:\testing_AI\StartAutoRun.bat" -force  -ErrorAction SilentlyContinue| out-null

New-Item -ItemType SymbolicLink -Path $env:USERPROFILE\desktop\ -Name "STOP.bat" -Value "C:\testing_AI\StopAutoRun.bat" -force -ErrorAction SilentlyContinue | out-null

}


Copy-Item "$scriptPath\flowsettings.csv" -Destination $dest\settings\ -Force

Copy-Item "$scriptPath\AutoRun.bat" -Destination $dest\settings\ -Force


## close all app windows 

Get-Process |   Where-Object { $_.MainWindowHandle -ne 0  } |
  ForEach-Object { 
  $handle = $_.MainWindowHandle

  # minimize window
  $null = [MyNamespace.MyType]::ShowWindowAsync($handle, 2)
}

$spenttime= (New-TimeSpan -start $starttime -end (Get-Date)).TotalMinutes
$spenttime2=[math]::Round($spenttime,1)

$index= "Copy Completed with $spenttime2 minutes." 
$results="copy OK"

#[System.Windows.Forms.MessageBox]::Show($this, " Copy Completed with $spenttime2 minutes. {0}{0} Please start AI testing with 【AutoRun.bat】 at deskeop {0}{0} (you may remove USB disk now) " -f [environment]::NewLine)    

###########  record logs ########

if($nonlog_flag.length -eq 0){

Get-Module -name "outlog"|remove-module
$mdpath=(gci -path "C:\testing_AI\modules\" -r -file |?{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

#write-host "Do $action!"
outlog $action $results  $tcnumber $tcstep $index
}

}

    export-modulemember -Function initial_copytool


