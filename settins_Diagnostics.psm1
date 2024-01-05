
function　settings_Diagnostics ([string]$para1,[string]$para2){
      
    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force;
    $wshell=New-Object -ComObject wscript.shell
      Add-Type -AssemblyName Microsoft.VisualBasic
      Add-Type -AssemblyName System.Windows.Forms
      Add-Type -AssemblyName System.Windows.Forms,System.Drawing
            
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

if($para1.Length -eq 0){
$para1="on"
}

$switchflag=$para1
$nonlog_flag=$para2

#$width  = (([string]::Join("`n", (wmic path Win32_VideoController get CurrentHorizontalResolution))).split("`n") -match "\d{1,}")[0]
#$height  = (([string]::Join("`n", (wmic path Win32_VideoController get CurrentVerticalResolution))).split("`n") -match "\d{1,}")[0]

$action="Settings_Diagnostics_$switchflag"
$tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
$tcnumber=((get-content $tcpath).split(","))[0]
$tcstep=((get-content $tcpath).split(","))[1]

$picpath=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\"
if(-not(test-path $picpath)){new-item -ItemType directory -path $picpath |out-null}

$actionss ="screenshot"
Get-Module -name $actionss|remove-module
$mdpath=(Get-ChildItem -path $scriptRoot -r -file |?{$_.name -match "^$actionss\b" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

$screen = [System.Windows.Forms.Screen]::PrimaryScreen
$bounds = $screen.Bounds
$width=$bounds.Width
$height=$bounds.Height

# 0 – Security 1 – Basic 2 – Enhanced 3 – Full  -> On:3 Off:1
$checkvalue=(Get-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection -Name "AllowTelemetry").AllowTelemetry
$turns=$false
if($checkvalue -eq 1 -and $switchflag -eq "on"){$turns=$true}
if($checkvalue -eq 3 -and $switchflag -eq "off"){$turns=$true}

#####

$appname="Diagnostics & feedback settings"

    [KeySends.KeySend]::KeyDown("LWin")
        [KeySends.KeySend]::KeyUp("LWin")
      
    Start-Sleep -s 5     
   [System.Windows.Forms.SendKeys]::SendWait("$appname")
   Start-Sleep -s 10
   [System.Windows.Forms.SendKeys]::SendWait("~")
    Start-Sleep -s 10
     [System.Windows.Forms.SendKeys]::SendWait("% ")
       Start-Sleep -s 2
        [System.Windows.Forms.SendKeys]::SendWait("x")
          Start-Sleep -s 2

    if($turns -eq $true){
     [System.Windows.Forms.SendKeys]::SendWait("{tab}")
       Start-Sleep -s 2
        [System.Windows.Forms.SendKeys]::SendWait(" ")
          Start-Sleep -s 2
          }
         
   
## screen capture ##

&$actionss  -para3 nonlog
$picfile=(Get-ChildItem $picpath |?{$_.name -match ".jpg"} |sort lastwritetime|select -Last 1).FullName

     [System.Windows.Forms.SendKeys]::SendWait("% ")
       Start-Sleep -s 2
        [System.Windows.Forms.SendKeys]::SendWait("c")
          Start-Sleep -s 2

##check results ##

$checkvalue=(Get-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection -Name "AllowTelemetry").AllowTelemetry

$results="NG"
if($checkvalue -eq 3 -and $switchflag -eq "on"){$results="PASS"}
if($checkvalue -eq 1 -and $switchflag -eq "off"){$results="PASS"}

$index=$picfile

######### write log  #######

if($nonlog_flag.Length -eq 0){
Get-Module -name "outlog"|remove-module
$mdpath=(Get-ChildItem -path "C:\testing_AI\modules\"  -r -file |?{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

#write-host "Do $action!"
outlog $action $results $tcnumber $tcstep $index

  }

  }

  
    export-modulemember -Function settings_Diagnostics