
function SetScreenResolution ([int]$para1,[int]$para2,[string]$para3,[string]$para4){
    
    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force;
    $wshell=New-Object -ComObject wscript.shell
      Add-Type -AssemblyName Microsoft.VisualBasic
      Add-Type -AssemblyName System.Windows.Forms
   

$paracheck=$PSBoundParameters.ContainsKey('para1')
$paracheck2=$PSBoundParameters.ContainsKey('para2')
$paracheck3=$PSBoundParameters.ContainsKey('para3')
$paracheck4=$PSBoundParameters.ContainsKey('para4')

if( $paracheck -eq $false -or $para1 -eq 0 ){
$para1=1920
}
if( $paracheck2 -eq $false -or $para2 -eq 0 ){
$para2=1080
}
if( $paracheck3 -eq $false -or $para3.length -eq 0 ){
$para3=""
}
if( $paracheck4 -eq $false -or $para4.length -eq 0 ){
$para4=""
}
$resx=$para1
$resy=$para2
$maxtype=$para3
$nonlogflag=$para4

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
public class PInvoke {
    [DllImport("user32.dll")] public static extern IntPtr GetDC(IntPtr hwnd);
    [DllImport("gdi32.dll")] public static extern int GetDeviceCaps(IntPtr hdc, int nIndex);
}
"@
$hdc = [PInvoke]::GetDC([IntPtr]::Zero)


if($PSScriptRoot.length -eq 0){
$scriptRoot="C:\testing_AI\modules"
}
else{
$scriptRoot=$PSScriptRoot
}

$tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
$tcnumber=((get-content $tcpath).split(","))[0]
$tcstep=((get-content $tcpath).split(","))[1]

$timenow=get-date -format "yyMMdd_HHmmss"
#$picpath=(Split-Path -Parent $scriptRoot)+"\logs\screenshot\"
$picpath=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\"
if(-not(test-path $picpath)){new-item -ItemType directory -path $picpath |out-null}

$actionss ="screenshot"
Get-Module -name $actionss|remove-module
$mdpath=(Get-ChildItem -path $scriptRoot -r -file |Where-object{$_.name -match "^$actionss\b" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

<#
$screen = [System.Windows.Forms.Screen]::PrimaryScreen
$bounds = $screen.Bounds
$width=$bounds.Width
$height=$bounds.Height
#>

#$width  = (([string]::Join("`n", (wmic path Win32_VideoController get CurrentHorizontalResolution))).split("`n") -match "\d{1,}")[0]
#$height  = (([string]::Join("`n", (wmic path Win32_VideoController get CurrentVerticalResolution))).split("`n") -match "\d{1,}")[0]


$width  = [PInvoke]::GetDeviceCaps($hdc, 118) # width
$height = [PInvoke]::GetDeviceCaps($hdc, 117) # height

### before res change##
      
&$actionss  -para3 nonlog -para5 "before"

 if($maxtype.length -gt 0){
 
## check max resolution ## ## $maxx $maxy2

$horlist=wmic /namespace:\\ROOT\WMI path WmiMonitorListedSupportedSourceModes get MonitorSourceModes /format:list |Where-object{$_ -match "HorizontalActivePixels"}
$verlist=wmic /namespace:\\ROOT\WMI path WmiMonitorListedSupportedSourceModes get MonitorSourceModes /format:list |Where-object{$_ -match "VerticalActivePixels"}

$maxx=0
$maxy=0
$rnk=0
foreach($verlist1 in $verlist){
$verlist1 -match "\d{3,}"
$maxy1=$Matches[0]

if([int]$maxy1 -ge [int]$maxy){
  $maxy=[int]$maxy1

  $horlist[$rnk] -match "\d{3,}"
  $maxx1=$Matches[0]
  if([int]$maxx1 -ge [int]$maxx){
   $maxx=[int]$maxx1
    $maxy2=$maxy
   write-host "$maxx , $maxy2"
   }
   
  }

  $rnk++

  write-host "X:$($maxx)"
  write-host "X:$($maxy2)"
}


$resx=$maxx
$resy=$maxy2
 }


$results= Set-ScreenResolution -Width $resx -Height  $resy

start-sleep -s 2

 ## if  os res change fail##

 if( $results -match "fail"){
  
$action_respy ="SetScreenResolution_py"
Get-Module -name $action_respy|remove-module
$mdpath=(Get-ChildItem -path $scriptRoot -r -file |Where-object{$_.name -match "^$action_respy\b" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

&$action_respy -para1 $resx -para2 $resy -para3 nonlog
  start-sleep -s 10
  
  Set-ScreenResolution -Width $resx -Height  $resy
    start-sleep -s 10

$width2  = [PInvoke]::GetDeviceCaps($hdc, 118) # width
$height2 = [PInvoke]::GetDeviceCaps($hdc, 117) # height

 $results="NG"
  $Index="fail to change the resolution to $($resx) X  $($resy) from $($width) X $($height) "
if($width2 -eq $resx -and  $height2 -eq $resy){
    $results="OK"
    $index="success change resolution to $($resx) X  $($resy) by PY-setresolution"
   }

 }
 
else{start-sleep -s 20

   $results="OK"
    $index="success change resolution to $($resx) X  $($resy)"

&$actionss  -para3 nonlog -para5 "after"
}
 


######### write log #######

$action="SetScreenResolution to $($resx) x $($resy)"
if($nonlogflag.Length -eq 0){
Get-Module -name "outlog"|remove-module
$mdpath=(Get-ChildItem -path "C:\testing_AI\modules\"  -r -file |Where-object{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

#write-host "Do $action!"
outlog $action $results $tcnumber $tcstep $index
}

  }

    export-modulemember -Function SetScreenResolution