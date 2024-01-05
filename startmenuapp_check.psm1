
function　startmenuapp_check ([string]$para1,[int64]$para2,[string]$para3,[string]$para4){
      
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


$paracheck2=$PSBoundParameters.ContainsKey('para2')

if( $paracheck2 -eq $false -or $para2 -eq 0 ){
$para2=30
}

$appname=$para1
$waittime=$para2
$appprocess=$para3
$nonlog_flag=$para4
$appname1=$appname.Replace("|","")

$action="startmenu_$($appname)"

#$width  = (([string]::Join("`n", (wmic path Win32_VideoController get CurrentHorizontalResolution))).split("`n") -match "\d{1,}")[0]
#$height  = (([string]::Join("`n", (wmic path Win32_VideoController get CurrentVerticalResolution))).split("`n") -match "\d{1,}")[0]

$tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
$tcnumber=((get-content $tcpath).split(","))[0]
$tcstep=((get-content $tcpath).split(","))[1]

$picpath=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\"
if(-not(test-path $picpath)){new-item -ItemType directory -path $picpath |out-null}

$actionss ="screenshot"
Get-Module -name $actionss|remove-module
$mdpath=(Get-ChildItem -path $scriptRoot -r -file |Where-object{$_.name -match "^$actionss\b" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

$screen = [System.Windows.Forms.Screen]::PrimaryScreen
$bounds = $screen.Bounds
$width=$bounds.Width
$height=$bounds.Height
$skipprun=$false

#region  for premiercolor check

if($appname -match "premiercolor"){
$skipprun=$true
$listfile=(Split-Path -Parent $scriptRoot)+"\settings\premiercolor_monitor_list.txt"
$monlist=(get-content $listfile)|Where-object{$_.length -gt 0}
$monitors = (Get-WmiObject -Namespace "root\CIMv2" -Query "SELECT * FROM Win32_PnPEntity WHERE PNPClass='Monitor'").name
$monitors2  =Get-WmiObject -Namespace "root/WMI" -Class WmiMonitorID | ForEach-Object {
    $edidBytes = $_.UserFriendlyName
    if($edidBytes){
    $edidString = [System.Text.Encoding]::ASCII.GetString($edidBytes)
    $edidString
    }
}

$monitorsall=($monitors+@($monitors2))|sort|Get-Unique
foreach($modelname in $monitorsall){
foreach($monli in $monlist){
$monli=$monli.Trim()
if($modelname -match $monli){
 $skipprun=$false
  write-host "$($modelname) in premiercolor monitor list - $monli"
  break
}
}

}


if($skipprun -eq $true){

$timenow=get-date -format "yyMMdd_HHmmss"
$logpath=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\$timenow_step$($tcstep)_premiercolor_skipinfo.txt"
$messg="The monitor(s) not supprot premiercolor:"+"`n"+($monitors.name|out-string) 
set-content -path $logpath -value $messg
$results="-"
$index="skip"
}

}

#endregion ####

    [KeySends.KeySend]::KeyDown("LWin")
        [KeySends.KeySend]::KeyUp("LWin")
        
   Start-Sleep -s 20

if($skipprun -eq $false){
   
   if($appname.Length -gt 0){
   
   $retry=0
   do{

Set-Clipboard $appname
 Start-Sleep -s 5
 
   [System.Windows.Forms.SendKeys]::SendWait("^v")
   Start-Sleep -s 10
    
   $n=0
   while($n -lt $retry){
     write-host "app select shift down $($retry)"
    Start-Sleep -s 2
   [System.Windows.Forms.SendKeys]::SendWait("{down}")
   $n++
   } 
    write-host "down * $($n)"

    $startchecktime=Get-Date
     Start-Sleep -s 2
   [System.Windows.Forms.SendKeys]::SendWait("~")
   
   Start-Sleep -s $waittime

   $checkrunning=get-process *|Where-object{$_.StartTime -gt $startchecktime}
   $checkrunningnames=$checkrunning.name|Out-String

   if(!($checkrunningnames -match $appprocess)){
   write-host "current running process is $checkrunningnames"
   if($checkrunning.id.count -gt 0){
    $checkrunning|stop-process -Force
    }else{    
     [System.Windows.Forms.SendKeys]::SendWait("{esc}")
     Start-Sleep -s 2
    }
    
      [KeySends.KeySend]::KeyDown("LWin")
        [KeySends.KeySend]::KeyUp("LWin")
         Start-Sleep -s 20
        $retry++
           }

   }until($checkrunningnames -match $appprocess)

      &$actionss  -para3 nonlog -para5 "$($appname1)"

     [System.Windows.Forms.SendKeys]::SendWait("% ")
       Start-Sleep -s 2
        [System.Windows.Forms.SendKeys]::SendWait("x")
          Start-Sleep -s 2
   }     
   
## screen capture ##
&$actionss  -para3 nonlog -para5 "$($appname1)_fullscreen"


if($appname.Length -eq 0){
    [KeySends.KeySend]::KeyDown("LWin")
        [KeySends.KeySend]::KeyUp("LWin")
   }

## iso update ##
$results="check"
$index="check screenshots"
}

######### write log  #######

if($nonlog_flag.Length -eq 0){
Get-Module -name "outlog"|remove-module
$mdpath=(Get-ChildItem -path "C:\testing_AI\modules\"  -r -file |Where-object{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

#write-host "Do $action!"
outlog $action $results $tcnumber $tcstep $index

  }

  }

  
    export-modulemember -Function startmenuapp_check