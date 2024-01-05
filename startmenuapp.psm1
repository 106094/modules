function startmenuapp ([string]$para1,[int64]$para2,[string]$para3){
      
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
$nonlog_flag=$para3
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

$skipprun=$false

$results="check"
$index="check screenshots"

if($appname.Length -gt 0){

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
$messg=$timenow+"`n"+"The monitor(s) not supprot premiercolor:"+"`n"+($monitors|out-string) 
set-content -path $logpath -value $messg
$results="-"
$index="skip"
}

}

#endregion ####

if($skipprun -eq $false){
 
$appid=(Get-StartApps|Where-object{$_.name -match "$appname" -AND $_.APPID -match "!"  }).appid
if(!$appid){$appid=(Get-StartApps|Where-object{$_.name -match "$appname"}).appid}

if($appid.count -eq 1){

# Start the application
#explorer shell:appsfolder\$appid
Start-Process "explorer.exe" "shell:appsfolder\$appId"

if($appname -match "dell command"){
    $apppath = Get-ChildItem "C:\Program Files\WindowsApps\DellInc.DellCommandUpdate*\DCU\DellCommandUpdate.exe"
    Start-Process $apppath.FullName -Verb RunAs
}



# Wait a moment for the app to launch
Start-Sleep -Seconds 10

# Find the process (replace 'ApplicationName' with the actual name of the app)
$process = Get-Process | Where-Object { $_.MainWindowTitle -like "*$($appname)*" }

# Check if the process is found
if ($process) {
    # Define the ShowWindow function from the user32.dll
    Add-Type @"
    using System;
    using System.Runtime.InteropServices;
    public class Win32ShowWindow {
        [DllImport("user32.dll")]
        [return: MarshalAs(UnmanagedType.Bool)]
        public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
    }
"@

    # Maximize the window
    [Win32ShowWindow]::ShowWindow($process.MainWindowHandle, 3) # 3 is for SW_MAXIMIZE
}
else {
    Write-Host "Process not found."
}


#------------------------------

 #region old method by sendkey
 <#

  [KeySends.KeySend]::KeyDown("LWin")
  [KeySends.KeySend]::KeyUp("LWin") 
  Set-Clipboard $appname
  Start-Sleep -s 20
  [System.Windows.Forms.SendKeys]::SendWait("^v")
  Start-Sleep -s 10
  [System.Windows.Forms.SendKeys]::SendWait("~")
   
    #>
     #endregion
  
   Start-Sleep -s $waittime

    &$actionss  -para3 nonlog -para5 "$($appname1)"
     #region old method by sendkey
  <#
      [KeySends.KeySend]::KeyDown("LWin")
        [KeySends.KeySend]::KeyUp("LWin")
   #>
  #endregion
}
else{
$results="NG"

if($appid.count -eq 0){$index="no found matched app id"}

if($appid.count -gt 1){$index="found multi matched app ids, need clarify"}

}



   }     
   
   
}
else{

      [KeySends.KeySend]::KeyDown("LWin")
        [KeySends.KeySend]::KeyUp("LWin")
        
    &$actionss  -para3 nonlog -para5 "Winkey"
    

      [KeySends.KeySend]::KeyDown("LWin")
        [KeySends.KeySend]::KeyUp("LWin")

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
  
    export-modulemember -Function startmenuapp