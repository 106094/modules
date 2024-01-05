
function wallpapersetting ([string]$para1,[string]$para2){
    
    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force;
    $wshell=New-Object -ComObject wscript.shell
      Add-Type -AssemblyName Microsoft.VisualBasic
      Add-Type -AssemblyName System.Windows.Forms
 
 #region import dll

Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public class Wallpaper {
    [DllImport("user32.dll", CharSet = CharSet.Auto)]
    public static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
}
"@
   # Define SPI constants
$SPI_SETDESKWALLPAPER = 0x0014
$SPIF_UPDATEINIFILE = 0x01
$SPIF_SENDCHANGE = 0x02

#endregion

$paracheck=$PSBoundParameters.ContainsKey('para1')
$paracheck2=$PSBoundParameters.ContainsKey('para2')

if( $paracheck -eq $false -or $para1.length -eq 0 ){
#write-host "no defined, setting 1 min after login"
$para1="idle"
}
if( $paracheck2 -eq $false -or $para2.length -eq 0 ){
#write-host "no defined, setting 1 min after login"
$para2=""
}


if($PSScriptRoot.length -eq 0){
$scriptRoot="C:\testing_AI\modules"
}
else{
$scriptRoot=$PSScriptRoot
}

$wppname=$para1
$nonlog_flag=""

$action="wallpaper change to $($para1)"
if($para1 -match "changebacktolast"){
$action="wallpaper change back to lastone"
}

$tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
$tcnumber=((get-content $tcpath).split(","))[0]
$tcstep=((get-content $tcpath).split(","))[1]
$picpath=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\"
if(-not(test-path $picpath)){new-item -ItemType directory -path $picpath |out-null}
$results="OK"

$lastwallpaperpath=$scriptRoot+"\wallpaper\last.txt"

$actionss ="screenshot"
Get-Module -name $actionss|remove-module
$mdpath=(Get-ChildItem -path $scriptRoot -r -file |Where-object{$_.name -match "^$actionss\b" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

&$actionss -para3 nonlog -para5 "before"

if($wppname -match "changebacktolast"){

# Set the wallpaper
$wallpaperPath=get-content $lastwallpaperpath
try{[Wallpaper]::SystemParametersInfo($SPI_SETDESKWALLPAPER, 0, $wallpaperPath, $SPIF_UPDATEINIFILE -bor $SPIF_SENDCHANGE)}
catch{$results="NG"}

}
else{

#save current wallpaperpath
$regPath = "HKCU:\Control Panel\Desktop"
$previousWallpaperPath = (Get-ItemProperty -Path $regPath -Name Wallpaper).Wallpaper
set-content $lastwallpaperpath -Value $previousWallpaperPath

# Set the wallpaper
$wallpaperPath=(Get-ChildItem -path $scriptRoot\wallpaper\ -r -file |Where-object{$_.name -match "^$wppname\b" -and $_.name -match "\.jpg"}).fullname
try{[Wallpaper]::SystemParametersInfo($SPI_SETDESKWALLPAPER, 0, $wallpaperPath, $SPIF_UPDATEINIFILE -bor $SPIF_SENDCHANGE)}
catch{$results="NG"}

}

&$actionss -para3 nonlog -para5 "after"
  
$index="check screenshots"

######### write log #######

if($nonlog_flag.length -eq 0){
Get-Module -name "outlog"|remove-module
$mdpath=(Get-ChildItem -path "C:\testing_AI\modules\"  -r -file |Where-object{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

#write-host "Do $action!"
outlog $action $results $tcnumber $tcstep $index
}

  }

    export-modulemember -Function wallpapersetting