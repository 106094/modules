function checkDM([string]$para1,[string]$para2,[string]$para3,[string]$para4) {
    
  Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force;
  $shell=New-Object -ComObject shell.application
  $wshell=New-Object -ComObject wscript.shell
    Add-Type -AssemblyName Microsoft.VisualBasic
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Windows.Forms,System.Drawing

#region import
function Set-WindowState {
<#
.LINK
https://gist.github.com/Nora-Ballard/11240204
#>

[CmdletBinding(DefaultParameterSetName = 'InputObject')]
param(
  [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
  [Object[]] $InputObject,

  [Parameter(Position = 1)]
  [ValidateSet('FORCEMINIMIZE', 'HIDE', 'MAXIMIZE', 'MINIMIZE', 'RESTORE',
         'SHOW', 'SHOWDEFAULT', 'SHOWMAXIMIZED', 'SHOWMINIMIZED',
         'SHOWMINNOACTIVE', 'SHOWNA', 'SHOWNOACTIVATE', 'SHOWNORMAL')]
  [string] $State = 'SHOW'
)

Begin {
  $WindowStates = @{
    'FORCEMINIMIZE'		= 11
    'HIDE'				= 0
    'MAXIMIZE'			= 3
    'MINIMIZE'			= 6
    'RESTORE'			= 9
    'SHOW'				= 5
    'SHOWDEFAULT'		= 10
    'SHOWMAXIMIZED'		= 3
    'SHOWMINIMIZED'		= 2
    'SHOWMINNOACTIVE'	= 7
    'SHOWNA'			= 8
    'SHOWNOACTIVATE'	= 4
    'SHOWNORMAL'		= 1
  }

  $Win32ShowWindowAsync = Add-Type -MemberDefinition @'
[DllImport("user32.dll")]
public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);
'@ -Name "Win32ShowWindowAsync" -Namespace Win32Functions -PassThru

  if (!$global:MainWindowHandles) {
    $global:MainWindowHandles = @{ }
  }
}

Process {
  foreach ($process in $InputObject) {
    if ($process.MainWindowHandle -eq 0) {
      if ($global:MainWindowHandles.ContainsKey($process.Id)) {
        $handle = $global:MainWindowHandles[$process.Id]
      } else {
        Write-Error "Main Window handle is '0'"
        continue
      }
    } else {
      $handle = $process.MainWindowHandle
      $global:MainWindowHandles[$process.Id] = $handle
    }

    $Win32ShowWindowAsync::ShowWindowAsync($handle, $WindowStates[$State]) | Out-Null
    Write-Verbose ("Set Window State '{1} on '{0}'" -f $MainWindowHandle, $State)
  }
}
}

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

#endregion
<## 
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class PInvoke {
  [DllImport("user32.dll")] public static extern IntPtr GetDC(IntPtr hwnd);
  [DllImport("gdi32.dll")] public static extern int GetDeviceCaps(IntPtr hdc, int nIndex);
}
"@
$hdc = [PInvoke]::GetDC([IntPtr]::Zero)
$curwidth = [PInvoke]::GetDeviceCaps($hdc, 118) # width
$curheight = [PInvoke]::GetDeviceCaps($hdc, 117) # height

$screen = [System.Windows.Forms.Screen]::PrimaryScreen
$bounds = $screen.Bounds
##>

if($PSScriptRoot.length -eq 0){
$scriptRoot="C:\testing_AI\modules"
}
else{
$scriptRoot=$PSScriptRoot
}

$actionss="screenshot"
Get-Module -name $actionss|remove-module
$mdpath=(Get-ChildItem -path $scriptRoot -r -file |Where-object{$_.name -match "^$actionss\b" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global      

$paracheck=$PSBoundParameters.ContainsKey('para1')
$paracheck2=$PSBoundParameters.ContainsKey('para2')
$paracheck3=$PSBoundParameters.ContainsKey('para3')
$paracheck4=$PSBoundParameters.ContainsKey('para4')

if( $paracheck -eq $false -or $para1.length -eq 0 ){
$para1=""
}
if( $paracheck2 -eq $false -or $para2.length -eq 0 ){
$para2=""
}
if( $paracheck3 -eq $false -or $para3.length -eq 0 ){
$para3=""
}
if( $paracheck4 -eq $false -or $para4.length -eq 0 ){
$para4=""
}

$expand_flag=$para1
$output_flag=$para2
$noncapt_flag=$para3
$dkeyword=$para4

$action="Device Manager Check"
$tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
$tcnumber=((get-content $tcpath).split(","))[0]
$tcstep=((get-content $tcpath).split(","))[1]
$dd=get-date -format "yyMMdd_HHmmss"

#$picpath=(Split-Path -Parent $scriptRoot)+"\logs\screenshot\"
$picpath=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)"
if(-not(test-path $picpath)){new-item -ItemType directory -path $picpath |out-null}

###########  save Device ########

## before driver install collect DRV info
if ($expand_flag -match "display"){

#Get-WmiObject Win32_PnPSignedDriver|select-object DeviceName, DriverVersion, HardwareID, Signer, IsSigned, DriverProviderName, InfName,Description,Location,DeviceClass |Where-object{$_.DeviceClass -match "display"}|out-string|set-content  "$picpath\$($dd)_step$($tcstep)_DisplayDeviceManager.txt"
$applist=Get-AppxPackage  |Where-object{$_.Name -match "AMD" -or $_.Name -match "NVIDIA"}| select-object Name,Version,Vendor,InstallDate,PackageFullName|out-string
if(!$applist){$applist="na"}
$applist|set-content  "$picpath\$($dd)_step$($tcstep)_Display_AppInfo.txt"

$ye=Get-WmiObject Win32_PnPEntity | Where-Object { $_.ConfigManagerErrorCode -ne 0 -and $_.Name -match "display|monitor" }|`
    Select-Object Name,Description, DeviceID, @{Name="HardwareID";Expression={$_.HardwareID -join "; "}}, Manufacturer

$results="OK"
$index="check logs"
if($ye.DeviceID.count -gt 0){
$yefile= "$picpath\$($dd)_step$($tcstep)_yellowbang.csv" 
$ye|Export-Csv $yefile -Encoding UTF8 -NoTypeInformation
$results="NG (with yellow bangs)"
$index=$yefile
}

## collect dxdiag ##

$dxdinfo="$picpath\$($dd)_step$($tcstep)_DxDiag.txt"

$inidrv=(Get-ChildItem "C:\testing_AI\logs\ini*" -r -Filter "*DriverVersion.csv"|Sort-Object lastwritetime|select-object -last 1).FullName
$checktype=(import-csv $inidrv|Where-object{$_.DeviceClass -match "DISPLAY"}).devicename

dxdiag /t $dxdinfo
do{
Start-Sleep -s 2
}until (!(get-process -name dxdiag -ea SilentlyContinue))

if($checktype -match "NVIDIA"){
$nvsmiinfo="$picpath\$($dd)_step$($tcstep)_nvidia-smi.txt"
try{nvidia-smi -f $nvsmiinfo}
catch{set-content $nvsmiinfo -value "no install a NV Display driver"}

}

}

else{
Get-WmiObject Win32_PnPSignedDriver|select-object DeviceName, DriverVersion, HardwareID, Signer, IsSigned, DriverProviderName, InfName,Description,Location,DeviceClass |Where-object{$_.InfName -match "oem"}|Export-Csv "$picpath\$($dd)_step$($tcstep)_DriverVersion.csv" -Encoding UTF8 -NoTypeInformation
Get-WmiObject Win32_PnPSignedDriver|select-object DeviceName, DriverVersion, HardwareID, Signer, IsSigned, DriverProviderName, InfName,Description,Location,DeviceClass |Export-Csv "$picpath\$($dd)_step$($tcstep)_DriverVersion_all.csv" -Encoding UTF8 -NoTypeInformation
Get-Package | select-object  name, Version,ProviderName,Source,FastPackageReference |Export-Csv -Path  "$picpath\$($dd)_step$($tcstep)_packages.csv" -Encoding UTF8  -NoTypeInformation
Get-CimInstance win32_product | select-object  Name,Version,Vendor,InstallDate,PackageFullName | Export-csv "$picpath\$($dd)_step$($tcstep)_AppVersion.csv" -Encoding UTF8 -NoTypeInformation 
Get-AppxPackage | select-object  Name,Version,Vendor,InstallDate,PackageFullName | Export-csv "$picpath\$($dd)_step$($tcstep)_AppVersion.csv"  -Append  -Encoding UTF8  -NoTypeInformation
Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | select-object  DisplayName, DisplayVersion, Publisher, InstallDate|export-csv "$picpath\$($dd)_step$($tcstep)_controlpanel_programs.csv" -Encoding UTF8  -NoTypeInformation
start-sleep -s 5
$ye=Get-WmiObject Win32_PnPEntity|Where-object{ $_.ConfigManagerErrorCode -ne 0}|select-object Name,Description, DeviceID, @{Name="HardwareID";Expression={$_.HardwareID -join "; "}},Manufacturer
$results="OK"
$index="check logs"
if($ye.DeviceID.count -gt 0){
$yefile= "$picpath\$($dd)_step$($tcstep)_yellowbang.csv"
$ye|Export-Csv $yefile -Encoding UTF8 -NoTypeInformation
Get-WmiObject Win32_PnPEntity|select-object Name,Description, DeviceID, @{Name="HardwareID";Expression={$_.HardwareID -join "; "}}, `
      Manufacturer |Export-Csv "$picpath\$($dd)_step$($tcstep)_Driver2.csv" -Encoding UTF8 -NoTypeInformation

$results="NG (with yellow bangs)"
$index=$yefile
}
}


### screentshot ###

if($noncapt_flag.Length -eq 0){

devmgmt.msc

start-sleep -s 5

$dmid=  (Get-Process mmc |sort-object starttime |Select-Object -last 1).id

$wshell.AppActivate('Device Manager') 

 Get-Process -id  $dmid  | Set-WindowState -State  MAXIMIZE

   start-sleep -s 2     
   
[Microsoft.VisualBasic.interaction]::AppActivate($dmid)|out-null
start-sleep -s 2

[Clicker]::LeftClickAtPoint(50, 1)

Start-Sleep -Seconds 2

## show hidden ##
if($expand_flag.Length -eq 0){
Start-Sleep -Seconds 2
  $wshell.sendkeys("%v")
   start-sleep -s 2
     $wshell.sendkeys("w")
     }

     start-sleep -s 2
  $wshell.sendkeys("{tab}")
  start-sleep -s 2 

if($expand_flag.Length -eq 0){
&$actionss  -para3 nonlog -para5 "DevicecManager"
#$picfile=(Get-ChildItem $picpath |Where-object{$_.name -match ".jpg" -and $_.name -match "DeviceManager" }).FullName
}

if($expand_flag.length -gt 0){

if ($expand_flag -match "display"){$ccatg="Win32_VideoController"}  
if ($expand_flag -match "network"){$ccatg="Win32_NetworkAdapter"} 
if ($expand_flag -match "storage controllers"){$ccatg="Win32_SCSIController"}  #Win32_IDEController
if ($expand_flag -match "disk"){$ccatg="Win32_DiskDrive"}

$datenow=get-date -format "yyMMdd_HHmmss"
$dirverinfo="$picpath\$($datenow)_step$($tcstep)_$($expand_flag)_DriverInfo.txt"
new-item $dirverinfo -Force |Out-Null

$catdrivers = Get-WmiObject $ccatg  | Where-Object { $_.ConfigManagerErrorCode -eq 0 }
 $catcount=$catdrivers.Caption.count

foreach ($catdriver in $catdrivers) {

  $deviceName = $catdriver.Name
  $deviceName
  $driver = Get-WmiObject Win32_PnPSignedDriver | Where-Object {   $_.DeviceName -eq $deviceName  }
  if(!$driver){
  $deviceName2=($deviceName -split "#")[0].Trim()
  $driver = Get-WmiObject Win32_PnPSignedDriver | Where-Object {   $_.DeviceName -eq $deviceName2  }
  }

  if ($driver) {
     $driverversion= ((($driver.DriverVersion|Out-String) -split ",")[0]).Trim()
      Add-Content $dirverinfo -value "Device Name: $($deviceName)"
      Add-Content $dirverinfo -value  "Driver Version:   $($driverversion)"
      Add-Content $dirverinfo -value  "Device Description: $($catdriver.Description)"
      Add-Content $dirverinfo -value  "------------------------"
  }

}

$wshell.AppActivate('Device Manager') 
 start-sleep -s 2
 if($expand_flag -match "display"){
   $wshell.sendkeys("display")
 }
 else{
  $wshell.sendkeys($expand_flag)
 }
   start-sleep -s 2
    $wshell.sendkeys("{right}")

#$catcount=(((Get-PnpDevice -InstanceId *)|select-object Class).class|sort|Get-Unique).count

$i=0
do{
Set-Clipboard " "
$i++
$wshell.AppActivate('Device Manager') 
start-sleep -s 2
 $wshell.sendkeys("{down}")
   start-sleep -s 2
     $wshell.sendkeys("~")
     start-sleep -s 5
      $wshell.sendkeys("+{tab}")
         &$actionss  -para3 nonlog -para5 "$($expand_flag)_$($i)"
         $wshell.sendkeys("{right}")
              &$actionss  -para3 nonlog -para5 "$($expand_flag)_$($i)_drivertab"
          
              if ($expand_flag -match "display_resources"){
                start-sleep -s 5
                 $wshell.sendkeys("{right 3}")
                 start-sleep -s 5
                 $wshell.sendkeys("{tab}")
                 start-sleep -s 2
                 &$actionss  -para3 nonlog -para5 "$($expand_flag)_$($i)_resourcestab1"
                 $wshell.sendkeys("{down}")
                 start-sleep -s 1
                 $wshell.sendkeys("{down}")
                 start-sleep -s 1
                 $wshell.sendkeys("{down}")
                 &$actionss  -para3 nonlog -para5 "$($expand_flag)_$($i)_resourcestab2"
                 $wshell.sendkeys("{down}")
                 start-sleep -s 1
                 $wshell.sendkeys("{down}")
                 &$actionss  -para3 nonlog -para5 "$($expand_flag)_$($i)_resourcestab3"
                               
              }    

              if ($expand_flag -match "disk"){
               start-sleep -s 5
               $wshell.sendkeys("{TAB}")
               start-sleep -s 1
                $wshell.sendkeys("{+}")
               start-sleep -s 1
               $wshell.sendkeys("+{tab}")
               start-sleep -s 1
               $wshell.sendkeys("{Enter}")
               start-sleep -s 2

               [Clicker]::LeftClickAtPoint(($bounds.Width/2), ($bounds.height/2))
               $wshell.sendkeys("^c")

                start-sleep -s 3
               if((Get-Clipboard) -match "write-caching"){
                  Write-Output "Match"
                  &$actionss  -para3 nonlog -para5 "$($expand_flag)_$($i)_1_Not support write-caching"
                  $wshell.sendkeys("~")
                 start-sleep -s 5
                     
               }else{
                  Write-Output "Not Match"
                  $wshell.sendkeys("~")
                     start-sleep -s 5
                      $wshell.sendkeys("+{tab}")
                       start-sleep -s 1
                         $wshell.sendkeys("{right}")
                          start-sleep -s 2
                          &$actionss  -para3 nonlog -para5 "$($expand_flag)_$($i)_1_After Enable write-caching"
                }

               
               }

## for advance settings

if($dkeyword.Length -ne 0){        
 
#region Lan SpeedDuplex/SoftwareTimestamp config 

$landevs=(import-csv "$picpath\$($dd)_step$($tcstep)_DriverVersion_all.csv"|Where-object{$_.DeviceClass -match "Net" -and $_.location -ne ""}).InfName|Sort-Object name|Get-Unique
foreach($landev in $landevs){
$setinfo=get-content C:\Windows\INF\$landev 

if($setinfo -match "SoftwareTimestamp"){
$countss=$true
}

}
#endregion

      $wshell.sendkeys("{tab}")
       start-sleep -s 1
         $wshell.sendkeys("$dkeyword")
        start-sleep -s 1
        
          &$actionss  -para3 nonlog -para5 "$($expand_flag)_$($i)_1_$($dkeyword)"

      if($countss){
       start-sleep -s 1
         $wshell.sendkeys("{Down}")
        start-sleep -s 1
        
          &$actionss  -para3 nonlog -para5 "$($expand_flag)_$($i)_1_$($dkeyword)_2"
      }
      

              $wshell.sendkeys("+{tab}")
         
         }
       
       
      start-sleep -s 1 
         $wshell.sendkeys("%{F4}")


}until($i -ge $catcount)

}


$wshell.AppActivate('Device Manager') 

start-sleep -s 1

$wshell.sendkeys("%{F4}")

if($wshell.AppActivate('Device Manager') -eq $true){stop-process -name mmc}

## control panel programs and features

#Start-Process control -Verb Open -WindowStyle Maximized


$shell.Windows() |Where-object{$_.name -eq "File Explorer"}| ForEach-Object { $_.Quit() }
start-sleep -s 5

 appwiz.cpl
 start-sleep -s 5
  $wshell.SendKeys("% ")
  $wshell.SendKeys("x")
  start-sleep -s 2

&$actionss  -para3 nonlog -para5 "controlpanel_programs"

$shell.Windows() |Where-object{$_.name -eq "File Explorer"}| ForEach-Object { $_.Quit() }
start-sleep -s 5


}

######### write log #######
if($output_flag.length -eq 0){

Get-Module -name "outlog"|remove-module
$mdpath=(Get-ChildItem -path "C:\testing_AI\modules\"  -r -file |Where-object{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

#write-host "Do $action!"
outlog $action $results $tcnumber $tcstep $index
}

}

  export-modulemember -Function checkDM