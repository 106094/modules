
function benchmark2 ([string]$para1, [string]$para2, [string]$para3){
    
    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force;
    $wshell=New-Object -com wscript.shell
      $shell=New-Object -ComObject shell.application
      Add-Type -AssemblyName Microsoft.VisualBasic
       Add-Type -AssemblyName System.Windows.Forms
        Add-Type -AssemblyName System.Windows.Forms,System.Drawing
        [void][System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")

#region functions

Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public class Window {
    [DllImport("user32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect);
}

public class Win32 {
    [DllImport("user32.dll", SetLastError = true)]
    public static extern IntPtr FindWindow(string lpClassName, string lpWindowName);

    [DllImport("user32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect);
}

public struct RECT {
    public int Left;
    public int Top;
    public int Right;
    public int Bottom;
}
"@

$cSource = @'
using System;
using System.Drawing;
using System.Runtime.InteropServices;
using System.Windows.Forms;
public class Clicker
{
//https://msdn.microsoft.com/en-us/library/windows/desktop/ms646270(v=vs.85).aspx
[StructLayout(LayoutKind.Sequential)]
struct INPUT
{ 
    public int        type; // 0 = INPUT_MOUSE,
                            // 1 = INPUT_KEYBOARD
                            // 2 = INPUT_HARDWARE
    public MOUSEINPUT mi;
}

//https://msdn.microsoft.com/en-us/library/windows/desktop/ms646273(v=vs.85).aspx
[StructLayout(LayoutKind.Sequential)]
struct MOUSEINPUT
{
    public int    dx ;
    public int    dy ;
    public int    mouseData ;
    public int    dwFlags;
    public int    time;
    public IntPtr dwExtraInfo;
}

//This covers most use cases although complex mice may have additional buttons
//There are additional constants you can use for those cases, see the msdn page
const int MOUSEEVENTF_MOVED      = 0x0001 ;
const int MOUSEEVENTF_LEFTDOWN   = 0x0002 ;
const int MOUSEEVENTF_LEFTUP     = 0x0004 ;
const int MOUSEEVENTF_RIGHTDOWN  = 0x0008 ;
const int MOUSEEVENTF_RIGHTUP    = 0x0010 ;
const int MOUSEEVENTF_MIDDLEDOWN = 0x0020 ;
const int MOUSEEVENTF_MIDDLEUP   = 0x0040 ;
const int MOUSEEVENTF_WHEEL      = 0x0080 ;
const int MOUSEEVENTF_XDOWN      = 0x0100 ;
const int MOUSEEVENTF_XUP        = 0x0200 ;
const int MOUSEEVENTF_ABSOLUTE   = 0x8000 ;

const int screen_length = 0x10000 ;

//https://msdn.microsoft.com/en-us/library/windows/desktop/ms646310(v=vs.85).aspx
[System.Runtime.InteropServices.DllImport("user32.dll")]
extern static uint SendInput(uint nInputs, INPUT[] pInputs, int cbSize);

public static void LeftClickAtPoint(int x, int y)
{
    //Move the mouse
    INPUT[] input = new INPUT[3];
    input[0].mi.dx = x*(65535/System.Windows.Forms.Screen.PrimaryScreen.Bounds.Width);
    input[0].mi.dy = y*(65535/System.Windows.Forms.Screen.PrimaryScreen.Bounds.Height);
    input[0].mi.dwFlags = MOUSEEVENTF_MOVED | MOUSEEVENTF_ABSOLUTE;
    //Left mouse button down
    input[1].mi.dwFlags = MOUSEEVENTF_LEFTDOWN;
    //Left mouse button up
    input[2].mi.dwFlags = MOUSEEVENTF_LEFTUP;
    SendInput(3, input, Marshal.SizeOf(input[0]));
}
}
'@
Add-Type -TypeDefinition $cSource -ReferencedAssemblies System.Windows.Forms,System.Drawing


Function Set-ScreenResolution { 
 
<# 
    .Synopsis 
        Sets the Screen Resolution of the primary monitor 
    .Description 
        Uses Pinvoke and ChangeDisplaySettings Win32API to make the change 
    .Example 
        Set-ScreenResolution -Width 1024 -Height 768         
    #> 
param ( 
[Parameter(Mandatory=$true, 
           Position = 0)] 
[int] 
$Width, 
 
[Parameter(Mandatory=$true, 
           Position = 1)] 
[int] 
$Height 
) 
 
$pinvokeCode = @" 
 
using System; 
using System.Runtime.InteropServices; 
 
namespace Resolution 
{ 
 
    [StructLayout(LayoutKind.Sequential)] 
    public struct DEVMODE1 
    { 
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)] 
        public string dmDeviceName; 
        public short dmSpecVersion; 
        public short dmDriverVersion; 
        public short dmSize; 
        public short dmDriverExtra; 
        public int dmFields; 
 
        public short dmOrientation; 
        public short dmPaperSize; 
        public short dmPaperLength; 
        public short dmPaperWidth; 
 
        public short dmScale; 
        public short dmCopies; 
        public short dmDefaultSource; 
        public short dmPrintQuality; 
        public short dmColor; 
        public short dmDuplex; 
        public short dmYResolution; 
        public short dmTTOption; 
        public short dmCollate; 
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)] 
        public string dmFormName; 
        public short dmLogPixels; 
        public short dmBitsPerPel; 
        public int dmPelsWidth; 
        public int dmPelsHeight; 
 
        public int dmDisplayFlags; 
        public int dmDisplayFrequency; 
 
        public int dmICMMethod; 
        public int dmICMIntent; 
        public int dmMediaType; 
        public int dmDitherType; 
        public int dmReserved1; 
        public int dmReserved2; 
 
        public int dmPanningWidth; 
        public int dmPanningHeight; 
    }; 
 
 
 
    class User_32 
    { 
        [DllImport("user32.dll")] 
        public static extern int EnumDisplaySettings(string deviceName, int modeNum, ref DEVMODE1 devMode); 
        [DllImport("user32.dll")] 
        public static extern int ChangeDisplaySettings(ref DEVMODE1 devMode, int flags); 
 
        public const int ENUM_CURRENT_SETTINGS = -1; 
        public const int CDS_UPDATEREGISTRY = 0x01; 
        public const int CDS_TEST = 0x02; 
        public const int DISP_CHANGE_SUCCESSFUL = 0; 
        public const int DISP_CHANGE_RESTART = 1; 
        public const int DISP_CHANGE_FAILED = -1; 
    } 
 
 
 
    public class PrmaryScreenResolution 
    { 
        static public string ChangeResolution(int width, int height) 
        { 
 
            DEVMODE1 dm = GetDevMode1(); 
 
            if (0 != User_32.EnumDisplaySettings(null, User_32.ENUM_CURRENT_SETTINGS, ref dm)) 
            { 
 
                dm.dmPelsWidth = width; 
                dm.dmPelsHeight = height; 
 
                int iRet = User_32.ChangeDisplaySettings(ref dm, User_32.CDS_TEST); 
 
                if (iRet == User_32.DISP_CHANGE_FAILED) 
                { 
                    return "Unable To Process Your Request. Sorry For This Inconvenience."; 
                } 
                else 
                { 
                    iRet = User_32.ChangeDisplaySettings(ref dm, User_32.CDS_UPDATEREGISTRY); 
                    switch (iRet) 
                    { 
                        case User_32.DISP_CHANGE_SUCCESSFUL: 
                            { 
                                return "Success"; 
                            } 
                        case User_32.DISP_CHANGE_RESTART: 
                            { 
                                return "You Need To Reboot For The Change To Happen.\n If You Feel Any Problem After Rebooting Your Machine\nThen Try To Change Resolution In Safe Mode."; 
                            } 
                        default: 
                            { 
                                return "Failed To Change The Resolution"; 
                            } 
                    } 
 
                } 
 
 
            } 
            else 
            { 
                return "Failed To Change The Resolution."; 
            } 
        } 
 
        private static DEVMODE1 GetDevMode1() 
        { 
            DEVMODE1 dm = new DEVMODE1(); 
            dm.dmDeviceName = new String(new char[32]); 
            dm.dmFormName = new String(new char[32]); 
            dm.dmSize = (short)Marshal.SizeOf(dm); 
            return dm; 
        } 
    } 
} 
 
"@ 
 
Add-Type $pinvokeCode -ErrorAction SilentlyContinue 
[Resolution.PrmaryScreenResolution]::ChangeResolution($width,$height) 
} 
      
 Add-Type @"
  using System;
  using System.Runtime.InteropServices;
  public class SFW {
     [DllImport("user32.dll")]
     [return: MarshalAs(UnmanagedType.Bool)]
     public static extern bool SetForegroundWindow(IntPtr hWnd);
  }
"@

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

  $Signature = @"
[DllImport("user32.dll")]public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);
"@

#$ShowWindowAsync = Add-Type -MemberDefinition $Signature -Name "Win32ShowWindowAsync" -Namespace Win32Functions -PassThru

#endregion
       
$paracheck1=$PSBoundParameters.ContainsKey('para1')
$paracheck2=$PSBoundParameters.ContainsKey('para2')
$paracheck3=$PSBoundParameters.ContainsKey('para3')

if($paracheck3 -eq $false -or $para3.Length -eq 0){
$para3=""
}

$bitype=$para1
$bitconfig=$para2
$noexit_flag=$para3

if($PSScriptRoot.length -eq 0){
$scriptRoot="C:\testing_AI\modules"
}
else{
$scriptRoot=$PSScriptRoot
}

$actionss="screenshot"
Get-Module -name $actionss|remove-module
$mdpath=(gci -path $scriptRoot -r -file |?{$_.name -match "^$actionss\b" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global


$tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
$tcnumber=((get-content $tcpath).split(","))[0]
$tcstep=((get-content $tcpath).split(","))[1]

$timenow=get-date -format "yyMMdd_HHmmss"
#$picpath=(Split-Path -Parent $scriptRoot)+"\logs\screenshot\"
$picpath=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\"
if(-not(test-path $picpath)){new-item -ItemType directory -path $picpath |out-null}

$width  = (([string]::Join("`n", (wmic path Win32_VideoController get CurrentHorizontalResolution))).split("`n") -match "\d{1,}")[0]
$height  = (([string]::Join("`n", (wmic path Win32_VideoController get CurrentVerticalResolution))).split("`n") -match "\d{1,}")[0]


if($bitype -match "SPECviewperf13"){

$action="SPECviewperf13 Benchmark"

## copy tool ##

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

$autopath="Y:\Matagorda\07.Tool\_AutoTool"
$copytopath="C:\testing_AI\modules\BITools\SPECviewperf13"

  if(!(test-path $copytopath)){
 Expand-Archive "$autopath\extra_tools\SPECviewperf13.zip" -DestinationPath $copytopath
   <#
   new-item -ItemType directory $copytopath |Out-Null
   $zipfile="$autopath\extra_tools\SPECviewperf13.zip"
   $copytopath="C:\testing_AI\modules\BITools\SPECviewperf13"
    write-host "unzip $zipfile to $copytopath"
    $shell.NameSpace($copytopath).copyhere($shell.NameSpace($zipfile).Items(),16)
    #>
    }

 $resultss= Set-ScreenResolution -Width 1920 -Height  1080

 if( $resultss -match "failed"){
   $results="NG, Fail to change resolution to 1920*1080"
   $Index="-"
   $noexit_flag="noexit"
 }

 else{

 <##
 $displayw=[int64](([System.Windows.Forms.Screen]::AllScreens).Bounds).Width
 $displayh=[int64](([System.Windows.Forms.Screen]::AllScreens).Bounds).Height
 $systemw= [int64](($width.split())[0])
 $systemh=[int64](($height.split())[0])

 
$diffw=$displayw- $systemw
$diffh= $displayh-  $systemh

if(-not($diffw -eq 0 -and $diffh -eq 0)){
 Set-ScreenResolution -Width $systemw -Height  $systemh
}
#>

start-sleep -s 5


$bipath=(gci "$scriptRoot\BITools\$bitype\" -r -file |?{$_.name -match "exe"}).FullName
   
 get-process nw -ErrorAction SilentlyContinue|stop-process -Force
 get-process viewperf -ErrorAction Silent|stop-process  -Force

 start-sleep -s 10

 ## check install and install ###

 $installspec13=$false

(Get-ChildItem "HKLM:Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\")|%{
$n=$_.name
$n=$n.Replace("HKEY_LOCAL_MACHINE\","HKLM:")
($p=Get-ItemProperty $n)|%{
#$_.DisplayName
if($_.DisplayName -match "SPECviewperf" -and $_.DisplayName -match "13"){
$installspec13=$true
}
}
}

if($installspec13 -eq $false){
  #&$bipath /VERYSILENT 

 &$bipath /VERYSILENT

   $starttime= (get-date).ToString()

    write-host "installing will take about 30 minutes" -nonewline

   set-content $picpath\installtime.txt -value "installing will take about 25+ minutes from $starttime"


   do{
    start-sleep -s 10
       
 $check13=((Get-Process -name SPECgpcViewperf13.0 -ErrorAction SilentlyContinue).Id).count

 write-host "." -nonewline

   }until($check13 -eq 0 )

   write-host

     $endtime= (get-date).ToString()

      write-host "installing done $endtime" 

   add-content $picpath\installtime.txt -value "installing done $endtime" 

    start-sleep -s 10

   $idrelesaenote=(get-process *|?{$_.MainWindowTitle -match "release_note"}).Id
   if( $idrelesaenote -ne $null){
   [Microsoft.VisualBasic.interaction]::AppActivate( $idrelesaenote)|out-null
    start-sleep -s 2
    [System.Windows.Forms.SendKeys]::SendWait("%{F4}")
    start-sleep -s 2
   }

   }



<### setting viewsets ##

if($bitconfig.Length -ne 0){
$viewsets=$bitconfig.split("+")
 $folders=gci -Directory C:\SPEC\SPECgpc\SPECviewperf13\viewsets\ 
 
 foreach ($folder in $folders){
 if($folder.Name -notin $viewsets){
 
 $des="C:\SPEC\SPECgpc\SPECviewperf13\temp\"
 if( -not(test-path $des) ){new-item -ItemType directory $des|out-null}
Move-Item -Path $folder.fullname -Destination $des  -Force
 }
 }
 }
 ###>

### revise 【index.html】 ## 

$setindex="C:\SPEC\SPECgpc\SPECviewperf13\vp13bench\index.html"
$setindexb="C:\SPEC\SPECgpc\SPECviewperf13\vp13bench\index_0.html"
$mgntjs="C:\SPEC\SPECgpc\SPECviewperf13\vp13bench\gwpgManageBenchmark.js"
$mgntjsb="C:\SPEC\SPECgpc\SPECviewperf13\vp13bench\gwpgManageBenchmark_0.js"
$mgntjsb1="C:\SPEC\SPECgpc\SPECviewperf13\vp13bench\gwpgManageBenchmark_1.js"
$mgntrbjs="C:\SPEC\SPECgpc\SPECviewperf13\vp13bench\gwpgRunBenchmark.js"
$mgntrbjsb="C:\SPEC\SPECgpc\SPECviewperf13\vp13bench\gwpgRunBenchmark_0.js"

if(Test-Path $setindexb){
move-item $setindexb $setindex -Force -ErrorAction SilentlyContinue
}

$newhtml=get-content $setindex|%{

if($_ -match "<footer>"){
 " <script>window.setInterval (run_benchmark,20000);</script>"  ###<footer>前加入 <script>window.setInterval (run_benchmark,10000);</script> ->30秒後自動開始
}

$_

}

#move-item $setindex  $setindexb -Force

#$newhtml|set-content $setindex ## wait 2nd time replace

### revise 【gwpgManageBenchmark.js】 1. viewset settings ## 

if(Test-Path $mgntjsb ){
move-item $mgntjsb $mgntjs -Force  -ErrorAction SilentlyContinue
}

if($bitconfig.Length -ne 0){

 $defviewset=($bitconfig.split("+")|%{"'"+$_+"'"}) -join ","    # ['3dsmax-06','catia-05']; 
 
$oriline="'3dsmax-06','catia-05','creo-02','energy-02','maya-05','medical-02','showcase-02','snx-03','sw-04'"
}

$changefalse=999

$newmngmjs=get-content $mgntjs|%{

if($bitconfig.Length -ne 0 -and $_ -like "*var official_viewsets*"){

$_ = " var official_viewsets = ["+$defviewset+"];"
}

if ($_ -like "*if (onSubmission)*"){
$changefalse=0

}
$changefalse++
if($changefalse -eq 9){
$addline="document.getElementById(""official-run"").checked = false;"
$addline
}

$_

}
move-item $mgntjs $mgntjsb -Force  -ErrorAction SilentlyContinue
$newmngmjs|set-content $mgntjs

### revise 【gwpgManageBenchmark.js】 2. disable alert ##  【gwpgManageBenchmark.js】//  alert('DPI must be 96 for a submission candidate.');

$newmngmjs2=get-content $mgntjs|%{
$oriline="alert('DPI must be 96 for a submission candidate.')"
if($_ -like "*$oriline*"){
$_ = "// " +$_
}

$_

}
move-item $mgntjs $mgntjsb1 -Force  -ErrorAction SilentlyContinue
$newmngmjs2|set-content $mgntjs


### revise【gwpgRunBenchmark.js】for auto running ###

 if(Test-Path $mgntjsb ){
move-item $mgntrbjsb $mgntrbjs -Force  -ErrorAction SilentlyContinue
}

$remarklines=@("122","125")
$n=0
$newrunjs=get-content $mgntrbjs|%{
if($n -in $remarklines){
if(-not ($_ -match "//")){$_ = "// " +$_}
}
$_
$n++
}

move-item $mgntrbjs $mgntrbjsb -Force  -ErrorAction SilentlyContinue
$newrunjs|set-content $mgntrbjs


### start UI & screenshot ###
start-sleep -s 5

$runcommand=".\gui\nw.exe"

set-location "C:\SPEC\SPECgpc\SPECviewperf13\"

&$runcommand vp13bench
start-sleep -s 10

 ## screenshot for settings at start ###

&$actionss  -para3 nonlog -para5 "$action-start"
    
$picfile1=(gci $picpath |?{$_.name -match ".jpg" -and $_.name -match "$action-start" }).FullName
 
 stop-process -name nw

 ## revise index for autostarting
 
move-item $setindex  $setindexb -Force  -ErrorAction SilentlyContinue

$newhtml|set-content $setindex ## wait 2nd time replace

### start UI & screenshot ###
start-sleep -s 5
 &$runcommand vp13bench

## screenshot for running ###

 start-sleep -s 40       

#### check if fail to open##

$resultNG = $null

 if( ((get-process -Name nw).Id).count -eq 0 -and ((get-process -Name viewperf).Id).count -eq 0 ){
 
#### outlog parameteres ###

  $results="NG, Fail to open programs"
       $Index="-"


[System.Windows.Forms.MessageBox]::Show($this, "Fail to open programs, please check")   
exit

 }

else{

    [KeySends.KeySend]::KeyDown("LWin")
    [KeySends.KeySend]::KeyDown("B")
    [KeySends.KeySend]::KeyUp("LWin")
    [KeySends.KeySend]::KeyUp("B")
    Start-Sleep -s 1
    [KeySends.KeySend]::KeyDown("LWin")
    [KeySends.KeySend]::KeyUp("LWin")
    Start-Sleep -s 1
    [KeySends.KeySend]::KeyDown("LWin")
    [KeySends.KeySend]::KeyUp("LWin")
     Start-Sleep -s 2

 ## screenshot for runnings ###

 &$actionss  -para3 nonlog -para5 "$action-running"
   
$picfile2=(gci $picpath |?{$_.name -match ".jpg" -and $_.name -match "$action-running" }).FullName

 start-sleep -s 5

 &$actionss  -para3 nonlog -para5 "$action-running2"
 

$picfile3=(gci $picpath |?{$_.name -match ".jpg" -and $_.name -match "$action-running2\b" }).FullName
### assign task schedule ####

### assign task schedule ####

start-process cmd -ArgumentList '/c schtasks /delete /TN "Auto_Run" -f' 
start-sleep -s 5
$actionsch = New-ScheduledTaskAction -Execute "C:\testing_AI\AutoRun.bat"
$etime=(Get-Date).AddMinutes(5)
$trigger = New-ScheduledTaskTrigger -Once -At $etime  -RepetitionInterval ([TimeSpan]::FromMinutes(5))
$Stset = New-ScheduledTaskSettingsSet -Priority 0 -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
$user=[System.Security.Principal.WindowsIdentity]::GetCurrent().Name

$STPrin= New-ScheduledTaskPrincipal   -User $user  -RunLevel Highest

Register-ScheduledTask -Action $actionsch -Trigger $trigger -Settings $Stset -Force -TaskName "Auto_Run" -Principal $STPrin

start-sleep -s 5

#### outlog parameteres ###
  
$Index=$picfile1+"`n"+$picfile2+"`n"+$picfile3
$results="chceck screenshots"
  
  }

}

}

if($bitype -match "SPECviewperf2020"){

## copy tool ##

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

$autopath="Y:\Matagorda\07.Tool\_AutoTool"
$copytopath="C:\testing_AI\modules\BITools\SPECviewperf2020"

  if(!(test-path $copytopath)){
 Expand-Archive "$autopath\extra_tools\SPECviewperf2020.zip" -DestinationPath $copytopath
   <#
  new-item -ItemType directory $copytopath |Out-Null
   $zipfile="$autopath\extra_tools\SPECviewperf2020.zip"
   $copytopath="C:\testing_AI\modules\BITools\SPECviewperf2020"
   write-host "unzip  $zipfile to $copytopath"
    $shell.NameSpace($copytopath).copyhere($shell.NameSpace($zipfile).Items(),16)
    #>
    }


 $action="SPECviewperf2020 Benchmark"

 $resultss= Set-ScreenResolution -Width 1920 -Height  1080

 if( $resultss -match "failed"){
   $results="NG, Fail to change resolution to 1920*1080"
   $Index="-"
   $noexit_flag="noexit"
 }

 else{

 <##
 $displayw=[int64](([System.Windows.Forms.Screen]::AllScreens).Bounds).Width
 $displayh=[int64](([System.Windows.Forms.Screen]::AllScreens).Bounds).Height
 $systemw= [int64](($width.split())[0])
 $systemh=[int64](($height.split())[0])

 
$diffw=$displayw- $systemw
$diffh= $displayh-  $systemh

if(-not($diffw -eq 0 -and $diffh -eq 0)){
 Set-ScreenResolution -Width $systemw -Height  $systemh
}
#>

start-sleep -s 5


$bipath=(gci "$scriptRoot\BITools\$bitype\" -r -file |?{$_.name -match "exe"}).FullName
   
 get-process nw -ErrorAction SilentlyContinue|stop-process -Force
 get-process RunViewperf -ErrorAction Silent|stop-process  -Force

 start-sleep -s 10

 ## check install and install ###

 $installspec2020=$false

(Get-ChildItem "HKLM:Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\")|%{
$n=$_.name
$n=$n.Replace("HKEY_LOCAL_MACHINE\","HKLM:")
($p=Get-ItemProperty $n)|%{
#$_.DisplayName
if($_.DisplayName -match "SPECviewperf" -and $_.DisplayName -match "2020"){
$installspec2020=$true
write-host "SPECviewperf2020 has been installed"
}
}
}

if($installspec2020 -eq $false){
  #&$bipath /VERYSILENT 
  $id0=((get-process notepad -ea SilentlyContinue).Id).count


 &$bipath /VERYSILENT

   $starttime= (get-date).ToString()

    write-host "installing will take about few minutes" -nonewline

   set-content $picpath\installtime.txt -value "installing will take about 25+ minutes from $starttime"
  
   start-sleep -s 60

   do{
    start-sleep -s 10
     $id1=((get-process notepad -ea SilentlyContinue).Id).count    
          $check2020heck2020=((Get-Process -name SPECviewperf2020* -ErrorAction SilentlyContinue).Id).count

           }until($id1 -gt $id0 -or  $check2020heck2020 -eq 0)

           Stop-Process -name  notepad -ea SilentlyContinue

    start-sleep -s 10

   $idrelesaenote=(get-process notepad -ea SilentlyContinue|?{$_.MainWindowTitle -match "note"}).Id
   if( $idrelesaenote -ne $null){
   [Microsoft.VisualBasic.interaction]::AppActivate( $idrelesaenote)|out-null
    start-sleep -s 2
    [System.Windows.Forms.SendKeys]::SendWait("%{F4}")
    start-sleep -s 2
   }

   }


### copy viewsets ##

if(!(test-path C:\SPEC\SPECgpc\SPECviewperf2020\viewsets\)){

write-host "start copying viewsets"

copy-item -path "\\192.168.2.249\srvprj\Inventec\Dell\Matagorda\07.Tool\SPECviewperf\SPECviewperf 2020\downloaded_viewsets\viewsets\" -destination C:\SPEC\SPECgpc\SPECviewperf2020\ -Force -Recurse

     $endtime= (get-date).ToString()

      write-host "installing done $endtime" 

   add-content $picpath\installtime.txt -value "installing done $endtime" 
      
    start-sleep -s 10

}
### revise 【index.html】 ## 

$setindex="C:\SPEC\SPECgpc\SPECviewperf2020\vpbench\index.html"
$setindexb="C:\SPEC\SPECgpc\SPECviewperf2020\vpbench\index_0.html"
$mgntjs="C:\SPEC\SPECgpc\SPECviewperf2020\vpbench\gwpgManageBenchmark.js"
$mgntjsb="C:\SPEC\SPECgpc\SPECviewperf2020\vpbench\gwpgManageBenchmark_0.js"
$mgntjsb1="C:\SPEC\SPECgpc\SPECviewperf2020\vpbench\gwpgManageBenchmark_1.js"
$mgntrbjs="C:\SPEC\SPECgpc\SPECviewperf2020\vpbench\gwpgRunBenchmark.js"
$mgntrbjsb="C:\SPEC\SPECgpc\SPECviewperf2020\vpbench\gwpgRunBenchmark_0.js"


if(Test-Path $setindexb){
move-item $setindexb $setindex -Force  -ErrorAction SilentlyContinue
}

$newhtml=get-content $setindex|%{

if($_ -match "<footer>"){
 " <script>window.setInterval (run_benchmark,20000);</script>"  ###<footer>前加入 <script>window.setInterval (run_benchmark,10000);</script> ->30秒後自動開始
}

$_

}

#move-item $setindex  $setindexb -Force

#$newhtml|set-content $setindex


if(Test-Path $mgntjsb ){
move-item $mgntjsb $mgntjs -Force  -ErrorAction SilentlyContinue
}


### revise 【gwpgManageBenchmark.js】 1. viewset settings 
if($bitconfig.Length -ne 0){

 $defviewset=($bitconfig.split("+")|%{"'"+$_+"'"}) -join ","    # ['3dsmax-06','catia-05']; 
 
$oriline="'3dsmax-07','catia-06','creo-03','energy-03','maya-06','medical-03','snx-04','solidworks-07'"

}

$changefalse=999

$newmngmjs=get-content $mgntjs|%{

if($bitconfig.Length -ne 0 -and $_ -like "*$oriline*"){

$_ = $_.replace($oriline,$defviewset)
}

##
if ($_ -like "*if (onSubmission)*"){
$changefalse=0
}
$changefalse++
if($changefalse -eq 9){
$addline="document.getElementById(""official-run"").checked = false;"
$addline
}

$_

}
move-item $mgntjs $mgntjsb -Force  -ErrorAction SilentlyContinue
$newmngmjs|set-content $mgntjs


###>

### revise 【gwpgManageBenchmark.js】 2. disable alert ##  【gwpgManageBenchmark.js】//  alert('DPI must be 96 for a submission candidate.');
 
$newmngmjs2=get-content C:\SPEC\SPECgpc\SPECviewperf2020\vpbench\gwpgManageBenchmark.js|%{
$oriline="lert('DPI must be 96 for a submission candidate.')"
if($_ -like "*$oriline*"){
$_ = "// " +$_
}

$_

}

move-item $mgntjs $mgntjs1 -Force  -ErrorAction SilentlyContinue
$newmngmjs2|set-content $mgntjs

### revise【gwpgRunBenchmark.js】for auto running ###

if(Test-Path $mgntrbjsb ){
move-item $mgntrbjsb $mgntrbjs -Force  -ErrorAction SilentlyContinue
}

$remarklines=@("114","117")
$n=0
$newrunjs=get-content $mgntrbjs|%{
if($n -in $remarklines){
if(-not ($_ -match "//")){$_ = "// " +$_}
}
$_
$n++
}

move-item $mgntrbjs $mgntrbjsb -Force  -ErrorAction SilentlyContinue

$newrunjs|set-content $mgntrbjs

### start UI & screenshot ###

start-sleep -s 5

$runcommand=".\gui\nw.exe"

set-location "C:\SPEC\SPECgpc\SPECviewperf2020\"

&$runcommand vpbench
start-sleep -s 10

 ## screenshot for settings at start ###
       
&$actionss  -para3 nonlog -para5 "$action-start"
   
$picfile1=(gci $picpath |?{$_.name -match ".jpg" -and $_.name -match "$action-start" }).FullName
 
  stop-process -name nw

 ## revise index for autostarting

 
move-item $setindex  $setindexb -Force  -ErrorAction SilentlyContinue

$newhtml|set-content $setindex ## wait 2nd time replace

### start UI & screenshot ###
start-sleep -s 5
&$runcommand vpbench

## screenshot for running ###

 start-sleep -s 40       
#### check if fail to open##

$resultNG = $null

 if( ((get-process -Name nw).Id).count -eq 0 -and ((get-process -Name viewperf).Id).count -eq 0 ){
 
#### outlog parameteres ###

  $results="NG, Fail to open programs"
       $Index="-"


[System.Windows.Forms.MessageBox]::Show($this, "Fail to open programs, please check")   
exit

 }

else{

    [KeySends.KeySend]::KeyDown("LWin")
    [KeySends.KeySend]::KeyDown("B")
    [KeySends.KeySend]::KeyUp("LWin")
    [KeySends.KeySend]::KeyUp("B")
    Start-Sleep -s 1
    [KeySends.KeySend]::KeyDown("LWin")
    [KeySends.KeySend]::KeyUp("LWin")
    Start-Sleep -s 1
    [KeySends.KeySend]::KeyDown("LWin")
    [KeySends.KeySend]::KeyUp("LWin")
     Start-Sleep -s 2

 ## screenshot for runnings ###
      
      
&$actionss  -para3 nonlog -para5 "$action-running"

 start-sleep -s 5

 &$actionss  -para3 nonlog -para5 "$action-running2"
   
$picfile2=(gci $picpath |?{$_.name -match ".jpg" -and $_.name -match "$action-running\b" }).FullName

$picfile3=(gci $picpath |?{$_.name -match ".jpg" -and $_.name -match "$action-running2\b" }).FullName
### assign task schedule ####

start-process cmd -ArgumentList '/c schtasks /delete /TN "Auto_Run" -f' 
start-sleep -s 5
$actionsch = New-ScheduledTaskAction -Execute "C:\testing_AI\AutoRun.bat"
$etime=(Get-Date).AddMinutes(5)
$trigger = New-ScheduledTaskTrigger -Once -At $etime  -RepetitionInterval ([TimeSpan]::FromMinutes(5))
$Stset = New-ScheduledTaskSettingsSet -Priority 0 -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
$user=[System.Security.Principal.WindowsIdentity]::GetCurrent().Name

$STPrin= New-ScheduledTaskPrincipal   -User $user  -RunLevel Highest

Register-ScheduledTask -Action $actionsch -Trigger $trigger -Settings $Stset -Force -TaskName "Auto_Run" -Principal $STPrin

start-sleep -s 5

#### outlog parameteres ###
  
$Index=$picfile1+"`n"+$picfile2+"`n"+$picfile3
$results="chceck screenshots"
  

  }

}

}

if($bitype -match "Cinebench"){

$results="OK"
$index="check logs"

if($bitconfig.Length -eq 0){
$results="NG"
$index="error define process config vale"
}
else{
$cputype=$bitconfig.split("-")[0]
$runtime=[int]($bitconfig.split("-")[1])

if($bitype -match "20"){
$benchname="CinebenchR20"
}
elseif($bitype -match "23"){
$benchname="CinebenchR23"
}
else{
$results="NG"
$index="$bitype no defined "
}

$action="$($bitype) Benchmark"
$benchzip=$benchname+".zip"
## copy tool ##

if ($results -ne "NG"){
$copytopath="C:\testing_AI\modules\BITools\$bitype"

  if(!(test-path $copytopath)){

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

$autopath="Y:\Matagorda\07.Tool\_AutoTool"

write-host "$benchzip unzip to $copytopath"

 Expand-Archive "$autopath\extra_tools\$benchzip" -DestinationPath $copytopath

    }
    
start-sleep -s 5

$bipath=(gci "$scriptRoot\BITools\$bitype\" -r -file |?{$_.name -match "Cinebench" -and $_.name -match "exe"}).FullName

if($bipath){

$logresult=$picpath+"$bitype"+"_testA.txt"
if(!(test-path $logresult)){
new-item -path $logresult|Out-Null
}

write-host "[$(get-date)]run $($benchname) and save log to $logresult - Start"

if($runtime -eq 0 -and $cputype -match "single"){
&$bipath -g_CinebenchCpu1Test=true |add-content $logresult -Force
}
if($runtime -eq 0 -and $cputype -match "multi"){
&$bipath -g_CinebenchCpuXTest=true |add-content $logresult -Force
}

if($runtime -ne 0 -and $cputype -match "single"){
&$bipath -g_CinebenchCpu1Test=true -g_CinebenchMinimumTestDuration=$($runtime) |add-content $logresult -Force
}
if($runtime -ne 0 -and $cputype -match "multi"){
&$bipath -g_CinebenchCpuXTest=true -g_CinebenchMinimumTestDuration=$($runtime) |add-content $logresult -Force
}


<##
do{
start-sleep -s 10
$wintile= (get-process *).MainWindowTitle|?{$_.length -gt 0}
}until($wintile -match "CINEBENCH")

start-sleep -s 10
&$actionss  -para3 nonlog -para5 "$($benchname)_running"
#>

do{
start-sleep -s 10
}until(!(get-process -name Cinebench -ErrorAction SilentlyContinue))


write-host "[$(get-date)]run $($benchname)  Completed"

}

else{
$results="NG"
$index="fail to find Cinebench.exe"
}
}
}
}

if($bitype -match "batch32"){

$results="OK"
$index="check logs"
if($bitconfig.Length -eq 0 -or $bitconfig -eq "1" ){
$down_num=0
}
else{
$down_num=[int]$bitconfig
}

$bipath=(gci "$scriptRoot\BITools\Batch32\" -r -file |?{$_.name -match "batch32" -and $_.name -match "exe"}).FullName

if(!$bipath){
$results="NG"
$index="batch32.exe not found"
}
else{
$actioncmd="cmdline"
Get-Module -name $actioncmd|remove-module
$mdpathcmd=(gci -path $scriptRoot -r -file |?{$_.name -match "^$actioncmd\b" -and $_.name -match "psm1"}).fullname
Import-Module $mdpathcmd -WarningAction SilentlyContinue -Global


function runbatch32{

stop-process -Name Batch32 -Force -ErrorAction SilentlyContinue
Start-Sleep -s 5
&$bipath
Start-Sleep -s 10
#$rootexe=split-path $bipath
#&$actioncmd -para1 "batch32.exe" -para2 $rootexe -para3 cmd -para5 nonlog
$Handle = Get-Process batch32| Where-Object { $_.MainWindowTitle -match $env:TITLE } | ForEach-Object { $_.MainWindowHandle }
if ( $Handle -is [System.Array] ) { $Handle = $Handle[0] }
$WindowRect = New-Object RECT
$GotWindowRect = [Window]::GetWindowRect($Handle, [ref]$WindowRect)
$clickx=$WindowRect.Left + 50
$clicky=$WindowRect.top +20
#$clickx2=($WindowRect.Left + $WindowRect.right)/2
#$clicky2=($WindowRect.top+$WindowRect.Bottom)/2
Start-Sleep -s 3
[Clicker]::LeftClickAtPoint($clickx, $clicky)
start-sleep -s 2
#region testing if warning
    $wshell.SendKeys("%t")
    start-sleep -s 2
      $wshell.SendKeys("~")
      start-sleep -s 2
      }
      
#region testing if warning

runbatch32

      $wshell.SendKeys("~")
      Start-Sleep -s 2
      $wshell.SendKeys("%{f4}")
      Start-Sleep -s 2
      $checkrun=get-process -name batch32 -ea SilentlyContinue
      if($checkrun){$waringmsg=$true}
      else{write-host "no warning message"}

runbatch32

if($waringmsg){
write-host "close warning message"
 $wshell.SendKeys("~")
 start-sleep -s 2
}

 start-sleep -s 2
 # select disks
 $wshell.SendKeys("{tab}")
 start-sleep -s 1
 $wshell.SendKeys("{tab}")
 start-sleep -s 1
 #$wshell.SendKeys(" ") # not select disk C
 #start-sleep -s 1
 
 if($down_num -gt 0){
 $down_num=$down_num-1

 do{ 
 $wshell.SendKeys("{down}") #select other disks
 start-sleep -s 1
 $wshell.SendKeys(" ")
 start-sleep -s 1
 $down_num=$down_num-1
 $down_num
 }until($down_num -le 0)
 }
  
 &$actionss -para3 "nolog" -para5 "disksettings"

 $wshell.SendKeys("{tab}")
 start-sleep -s 1
 $wshell.SendKeys("{tab}")
 start-sleep -s 1
 $wshell.SendKeys(" ")
 start-sleep -s 2

 #time setting 10 mins

 $wshell.SendKeys("%t")
 start-sleep -s 1
 $wshell.SendKeys("t")
 start-sleep -s 1
 $wshell.SendKeys("{tab}")
 start-sleep -s 1
 $wshell.SendKeys("{tab}")
 Set-Clipboard -value "10"
 start-sleep -s 5
 $wshell.SendKeys("^v")
 
 
 &$actionss -para3 "nolog" -para5 "timesettings"

 $wshell.SendKeys("{tab}")
 start-sleep -s 1
 $wshell.SendKeys(" ")
 start-sleep -s 2
 
 #run
 $wshell.SendKeys("%t")
 start-sleep -s 1
 $wshell.SendKeys("r")
 start-sleep -s 2

 #region check if starting
 
   $processName = "batch32"

    # Get the Process object for the specific process
    $process = Get-Process -Name $processName

    # Get the Process ID (PID) of the specific process
    $processId = $process.Id

    write-host "atto benchmark start $(get-date)"
    # Define the performance counters you want to monitor for the specific process

$counterList = @(
    "\Process($processName)\IO Read Bytes/sec",
    "\Process($processName)\IO Write Bytes/sec"
)
 $countlimit=0

 do{
  
   $counters = Get-Counter -Counter $counterList

    $readMBPerSec = $counters.CounterSamples[0].CookedValue / 1MB
    $writeMBPerSec = $counters.CounterSamples[1].CookedValue / 1MB

    $acceessmb= $readMBPerSec+$writeMBPerSec


    Write-Host "Process $processName - Disk Read MB/s: $readMBPerSec"
    Write-Host "Process $processName - Disk Write MB/s: $writeMBPerSec"

    Start-Sleep -Seconds 5  # Adjust the interval as needed

    $countlimit++

      }until ($acceessmb -gt 0 -or $countlimit -gt 10)  

 if($countlimit -gt 10){
       &$actionss -para3 "nolog" -para5 "running-fail"
       $results="NG"
       $index="fail to run Batch32"
      }
      
else{
 &$actionss -para3 "nolog" -para5 "running"


#endregion

 #region check if finish
$acceessmb=1
# Loop to retrieve and display disk activity for the specific process
while ($acceessmb -ne 0) {
    $counters = Get-Counter -Counter $counterList

    $readMBPerSec = $counters.CounterSamples[0].CookedValue / 1MB
    $writeMBPerSec = $counters.CounterSamples[1].CookedValue / 1MB

    $acceessmb= $readMBPerSec+$writeMBPerSec

    #Write-Host "Process $processName - Disk Read MB/s: $readMBPerSec"
    #Write-Host "Process $processName - Disk Write MB/s: $writeMBPerSec"

    Start-Sleep -Seconds 1  # Adjust the interval as needed
        
    $readMBPerSec = $counters.CounterSamples[0].CookedValue / 1MB
    $writeMBPerSec = $counters.CounterSamples[1].CookedValue / 1MB

    $acceessmb= $acceessmb+$readMBPerSec+$writeMBPerSec
    
    Start-Sleep -Seconds 1  # Adjust the interval as needed
        
    $readMBPerSec = $counters.CounterSamples[0].CookedValue / 1MB
    $writeMBPerSec = $counters.CounterSamples[1].CookedValue / 1MB

    $acceessmb= $acceessmb+$readMBPerSec+$writeMBPerSec

}

write-host "end $(get-date)"

 &$actionss -para3 "nolog" -para5 "completed"
#endregion

 $Handle = Get-Process batch32| Where-Object { $_.MainWindowTitle -match $env:TITLE } | ForEach-Object { $_.MainWindowHandle }
if ( $Handle -is [System.Array] ) { $Handle = $Handle[0] }
$WindowRect = New-Object RECT
$GotWindowRect = [Window]::GetWindowRect($Handle, [ref]$WindowRect)
#$clickx=$WindowRect.Left + 50
#$clicky=$WindowRect.top +20
$clickx2=($WindowRect.Left + $WindowRect.right)/2
$clicky2=($WindowRect.top+$WindowRect.Bottom)/2
Start-Sleep -s 2
[Clicker]::LeftClickAtPoint($clickx2, $clicky2)
Start-Sleep -s 2
 $wshell.SendKeys("{down 20}")

 &$actionss -para3 "nolog" -para5 "completed2"

}
(get-process -name Batch32).CloseMainWindow()
}
}

write-host "$results, $index"
######### write log #######

Get-Module -name "outlog"|remove-module
$mdpath=(gci -path "C:\testing_AI\modules\"  -r -file |?{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

#write-host "Do $action!"
outlog $action $results $tcnumber $tcstep $index

start-sleep -s 10

if($noexit_flag.length -eq 0){
exit
}

}
    export-modulemember -Function  benchmark2
