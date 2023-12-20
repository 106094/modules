
function selenium_prepare ([string]$para1,[string]$para2){
    
    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force;
    $wshell=New-Object -ComObject wscript.shell
      Add-Type -AssemblyName Microsoft.VisualBasic
      Add-Type -AssemblyName System.Windows.Forms

$paracheck1=$PSBoundParameters.ContainsKey('para1')
$paracheck2=$PSBoundParameters.ContainsKey('para2')

if($paracheck1 -eq $false -or $para1.Length -eq 0){
$para1= "edge"
}
if($paracheck2 -eq $false -or $para2.Length -eq 0){
$para2= ""
}

$brwstype=$para1
$nonlog_flag=$para2

if($PSScriptRoot.length -eq 0){
$scriptRoot="C:\testing_AI\modules"
}
else{
$scriptRoot=$PSScriptRoot
}

if($brwstype -match "edge"){


$browserpath = (Get-Item (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\msedge.exe').'(Default)').VersionInfo.FileName

$version=(Get-Item $browserpath).VersionInfo.FileVersion
$versionc=[string]::Join(".",($version -split "\."|select -First 3))

$driverpath=(gci -path C:\testing_AI\modules\selenium\$brwstype\*|?{$_.name -match "$versionc"}|sort name|select -Last 1).FullName
if(!$driverpath){$driverpath=(gci -path C:\testing_AI\modules\selenium\$brwstype\*  -Directory|sort lastwritetime|select -Last 1).FullName}
gci $driverpath\*.exe |copy-item -Destination C:\testing_AI\modules\selenium\ -Force

}


if($brwstype -match "firefox"){

$driverpath=(gci -path C:\testing_AI\modules\selenium\$brwstype\*|sort lastwritetime|select -Last 1).FullName

gci $driverpath\*.exe |copy-item -Destination C:\testing_AI\modules\selenium\ -Force

}

if($brwstype -match "chrome"){

$browserpath = (Get-Item (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\chrome.exe').'(Default)').VersionInfo.FileName

$version=(Get-Item $browserpath).VersionInfo.FileVersion
$versionc=[string]::Join(".",($version -split "\."|select -First 3))

$driverpath=(gci -path C:\testing_AI\modules\selenium\$brwstype\*|?{$_.name -match "$versionc"}|sort name|select -Last 1).FullName
gci $driverpath\*.exe |copy-item -Destination C:\testing_AI\modules\selenium\ -Force

}

######### write log #######
if($nonlog_flag.Length -eq 0){

$results="-"
$index="-"

$tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
$tcnumber=((get-content $tcpath).split(","))[0]
$tcstep=((get-content $tcpath).split(","))[1]

Get-Module -name "outlog"|remove-module
$mdpath=(gci -path "C:\testing_AI\modules\"  -r -file |?{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

#write-host "Do $action!"
outlog $action $results $tcnumber $tcstep $index
}

  }

    export-modulemember -Function selenium_prepare