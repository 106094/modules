

function filexplorer ([string]$para1,[string]$para2){

    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force;
    $shell=New-Object -ComObject shell.application
    $wshell=New-Object -ComObject wscript.shell
      Add-Type -AssemblyName Microsoft.VisualBasic
      Add-Type -AssemblyName System.Windows.Forms
 
if($PSScriptRoot.length -eq 0){
$scriptRoot="C:\testing_AI\modules"
}
else{
$scriptRoot=$PSScriptRoot
}

    $actionss ="screenshot"
    Get-Module -name $actionss|remove-module
    $mdpath=(Get-ChildItem -path $scriptRoot -r -file |?{$_.name -match "^$actionss\b" -and $_.name -match "psm1"}).fullname
    Import-Module $mdpath -WarningAction SilentlyContinue


$tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
$tcnumber=((get-content $tcpath).split(","))[0]
$tcstep=((get-content $tcpath).split(","))[1]
$action=((get-content $tcpath).split(","))[2]

$picpath=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\"
if(-not(test-path $picpath)){new-item -ItemType directory -path $picpath |out-null}

$paracheck1=$PSBoundParameters.ContainsKey('para1')
if($paracheck1 -eq $false -or $para1.Length -eq 0){
$para1="C:\"
}

$folderpath=$para1
$nonlog_flag=$para2

if (test-path $folderpath){

   start-process explorer "$folderpath" -WindowStyle Maximized

      start-sleep -s 5   

      &$actionss -para3 non_log -para5 "file_explore"

$picfile=(Get-ChildItem $picpath |?{$_.name -match ".jpg" -and $_.name -match "file_explore" }|sort lastwritetine|select -Last 1).FullName

 ### close file explore windows

 $shell.Windows() |?{$_.name -eq "File Explorer"}| ForEach-Object { $_.Quit() }
      start-sleep -s 5

$results="OK"
$index=$picfile
      
   }

else{
$results="NG"
$index="cannot find the folder path"

}

if($nonlog_flag.length -eq 0){

Get-Module -name "outlog"|remove-module
$mdpath=(Get-ChildItem -path "C:\testing_AI\modules\"  -r -file |?{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

#write-host "Do $action!"
outlog $action $results $tcnumber $tcstep $index
}
  }

    export-modulemember -Function filexplorer