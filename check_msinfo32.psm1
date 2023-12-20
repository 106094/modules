
function　check_msinfo32 ([string]$para1){
      
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

$nonlog_flag=$para1

$width  = (([string]::Join("`n", (wmic path Win32_VideoController get CurrentHorizontalResolution))).split("`n") -match "\d{1,}")[0]
$height  = (([string]::Join("`n", (wmic path Win32_VideoController get CurrentVerticalResolution))).split("`n") -match "\d{1,}")[0]

$action="check_msinfo32"
$tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
$tcnumber=((get-content $tcpath).split(","))[0]
$tcstep=((get-content $tcpath).split(","))[1]

$picpath=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\"
if(-not(test-path $picpath)){new-item -ItemType directory -path $picpath |out-null}

$actionmd="screenshot"
Get-Module -name $actionmd|remove-module
$mdpath=(gci -path $scriptRoot -r -file |?{$_.name -match "^$actionmd\b" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global


# 0 – Security 1 – Basic 2 – Enhanced 3 – Full  -> On:3 Off:1
$checkvalue=(Get-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection -Name "AllowTelemetry").AllowTelemetry
$turns=$false
if($checkvalue -eq 1 -and $switchflag -eq "on"){$turns=$true}
if($checkvalue -eq 3 -and $switchflag -eq "off"){$turns=$true}

#####

$appname="msinfo32"

    [KeySends.KeySend]::KeyDown("LWin")
        [KeySends.KeySend]::KeyUp("LWin")
      
    Start-Sleep -s 2     
   [System.Windows.Forms.SendKeys]::SendWait("$appname")
   Start-Sleep -s 2
   [System.Windows.Forms.SendKeys]::SendWait("~")
    Start-Sleep -s 10
     [System.Windows.Forms.SendKeys]::SendWait("% ")
       Start-Sleep -s 2
        [System.Windows.Forms.SendKeys]::SendWait("x")
          Start-Sleep -s 2
     [System.Windows.Forms.SendKeys]::SendWait("{tab}")
       Start-Sleep -s 2
       
## screen capture ##

&$actionmd  -para3 nonlog -para5 "1"
 
      
       [System.Windows.Forms.SendKeys]::SendWait("{PGDN}")
          Start-Sleep -s 10
          
&$actionmd  -para3 nonlog -para5 "2"
   

       
       [System.Windows.Forms.SendKeys]::SendWait("{PGDN}")
          Start-Sleep -s 10
          
&$actionmd  -para3 nonlog -para5 "3"

     [System.Windows.Forms.SendKeys]::SendWait("% ")
       Start-Sleep -s 2
        [System.Windows.Forms.SendKeys]::SendWait("c")
          Start-Sleep -s 2

##check results ##

 $picfile1=(gci $picpath |?{$_.name -match ".jpg" -and $_.name -match "1" }).FullName
 $picfile2=(gci $picpath |?{$_.name -match ".jpg" -and $_.name -match "2" }).FullName
 $picfile3=(gci $picpath |?{$_.name -match ".jpg" -and $_.name -match "3" }).FullName

$results="check screenshot"
$index=[string]::join("`n",$picfile1,$picfile2,$picfile3)

######### write log  #######

if($nonlog_flag.Length -eq 0){
Get-Module -name "outlog"|remove-module
$mdpath=(gci -path "C:\testing_AI\modules\"  -r -file |?{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

#write-host "Do $action!"
outlog $action $results $tcnumber $tcstep $index

  }

  }

  
    export-modulemember -Function check_msinfo32