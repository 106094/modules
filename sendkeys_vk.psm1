

function sendkeys_vk ([string]$para1,[string]$para2,[string]$para3,[int]$para4,[string]$para5){
    
    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force;
    $wshell=New-Object -ComObject wscript.shell
      Add-Type -AssemblyName Microsoft.VisualBasic
      Add-Type -AssemblyName System.Windows.Forms
  
$paracheck=$PSBoundParameters.ContainsKey('para1')
$paracheck2=$PSBoundParameters.ContainsKey('para2')
$paracheck3=$PSBoundParameters.ContainsKey('para3')
$paracheck4=$PSBoundParameters.ContainsKey('para4')
$paracheck5=$PSBoundParameters.ContainsKey('para5')

if( $paracheck -eq $false -or $para1.length -eq 0 ){
#write-host "no defined, setting 1 min after login"
$para1=""
}
if( $paracheck2 -eq $false -or $para2.length -eq 0 ){
#write-host "no defined, setting 1 min after login"
$para2=""
}
if( $paracheck3 -eq $false -or $para3.length -eq 0 ){
#write-host "no defined, setting 1 min after login"
$para3=""
}
if( $paracheck4 -eq $false -or $para4 -eq 0 ){
#write-host "no defined, setting 1 min after login"
$para4=1
}
if( $paracheck5 -eq $false -or $para5.length -eq 0 ){
#write-host "no defined, setting 1 min after login"
$para5=""
}

$keysend1=$para1
$keysend2=$para2
$keysend3=$para3
$waittime=$para4
$nonlog_flag=$para5

  $source = @"
using System;
using System.Threading.Tasks;
using System.Runtime.InteropServices;
using System.Windows.Forms;
namespace KeySends
{
    public class KeySend
    {
        [DllImport("user32.dll")]
        public static extern void keybd_event(byte bVk, byte bScan, int dwFlags, int dwExtraInfo);
        private const int KEYEVENTF_EXTENDEDKEY = 1;
        private const int KEYEVENTF_KEYUP = 2;
        public static void KeyDown(Keys vKey)
        {
            keybd_event((byte)vKey, 0, KEYEVENTF_EXTENDEDKEY, 0);
        }
        public static void KeyUp(Keys vKey)
        {
            keybd_event((byte)vKey, 0, KEYEVENTF_EXTENDEDKEY | KEYEVENTF_KEYUP, 0);
        }
    }
}
"@
Add-Type -TypeDefinition $source -ReferencedAssemblies "System.Windows.Forms"

if($PSScriptRoot.length -eq 0){
$scriptRoot="C:\testing_AI\modules"
}
else{
$scriptRoot=$PSScriptRoot
}

$keysend=[string]::Join("+", (@($keysend1, $keysend2, $keysend3) | ?{ $_.Length -gt 0 }))

$action="sendkeys of $keysend"

$tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
$tcnumber=((get-content $tcpath).split(","))[0]
$tcstep=((get-content $tcpath).split(","))[1]
$picpath=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\"
if(-not(test-path $picpath)){new-item -ItemType directory -path $picpath |out-null}

    $actionss ="screenshot"
    Get-Module -name $actionss|remove-module
    $mdpath=(gci -path $scriptRoot -r -file |?{$_.name -match "^$actionss\b" -and $_.name -match "psm1"}).fullname
    Import-Module $mdpath -WarningAction SilentlyContinue -Global
  
$screen = [System.Windows.Forms.Screen]::PrimaryScreen
$bounds = $screen.Bounds
$width=$bounds.Width
$height=$bounds.Height

#$width  = (([string]::Join("`n", (wmic path Win32_VideoController get CurrentHorizontalResolution))).split("`n") -match "\d{1,}")[0]
#$height  = (([string]::Join("`n", (wmic path Win32_VideoController get CurrentVerticalResolution))).split("`n") -match "\d{1,}")[0]

 ## screenshot before sendkeys ##

&$actionss  -para3 nonlog -para5 "before"

  if($keysend1.Length -gt 0){[KeySends.KeySend]::KeyDown("$keysend1")}
  if($keysend2.Length -gt 0){[KeySends.KeySend]::KeyDown("$keysend2")}
  if($keysend3.Length -gt 0){[KeySends.KeySend]::KeyDown("$keysend3")}
  
  if($keysend1.Length -gt 0){[KeySends.KeySend]::KeyUp("$keysend1")}
  if($keysend2.Length -gt 0){[KeySends.KeySend]::KeyUp("$keysend2")}
  if($keysend3.Length -gt 0){[KeySends.KeySend]::KeyUp("$keysend3")}


#$returncode=($?).tostring().trim()
#if($returncode -eq "True"){$results="OK"}else{$results="NG"}

start-sleep -s $waittime


 ## screenshot before sendkeys ##

&$actionss  -para3 nonlog -para5 "after"

  
######### write log #######

$results="check"
$index="check screen shot"

if($nonlog_flag.Length -eq 0){

Get-Module -name "outlog"|remove-module
$mdpath=(gci -path "C:\testing_AI\modules\"  -r -file |?{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

#write-host "Do $action!"
outlog $action $results $tcnumber $tcstep $index


}


  }

    export-modulemember -Function sendkeys_vk