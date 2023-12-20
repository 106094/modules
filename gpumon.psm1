
function gpumon ([string]$para1){
      
    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force;
    $wshell=New-Object -ComObject wscript.shell
      Add-Type -AssemblyName Microsoft.VisualBasic
       Add-Type -AssemblyName System.Windows.Forms
        Add-Type -AssemblyName System.Windows.Forms,System.Drawing
    

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
     
if($PSScriptRoot.length -eq 0){
$scriptRoot="C:\testing_AI\modules"
}
else{
$scriptRoot=$PSScriptRoot
}

$actiontype=$para1

$tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
$tcnumber=((get-content $tcpath).split(","))[0]
$tcstep=((get-content $tcpath).split(","))[1]
$action=((get-content $tcpath).split(","))[2]

$picpath=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\"
if(-not(test-path $picpath)){new-item -ItemType directory -path $picpath |out-null}

$actionmd ="screenshot"
Get-Module -name $actionmd|remove-module
$mdpath=(gci -path $scriptRoot -r -file |?{$_.name -match "^$actionmd\b" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

$screen = [System.Windows.Forms.Screen]::PrimaryScreen
$bounds = $screen.Bounds
$width  = $bounds.Width
$height = $bounds.Height


$checkgfx=(Get-WmiObject -Class Win32_VideoController | Select-Object Name,AdapterCompatibility).name
if($checkgfx -match "amd"){
$results="na"
 $index="AMD Gfx Driver, by pass"+"`n" `
  +"Refer to https://developer.nvidia.com/rtx/path-tracing/nvapi/get-started, NVAPI is NVIDIA's core software development kit, that supported on NVIDIA graphics card."
}

else{


if($actiontype -match "start"){    

 &"$scriptRoot\GPUMon\GPUMon.exe"
 start-sleep -s 10
 $gpumid=(get-process -name GPUMon).Id
  [Microsoft.VisualBasic.Interaction]::AppActivate($gpumid)
    Start-Sleep -s 1
  [System.Windows.Forms.SendKeys]::SendWait("{tab 14}")
   Start-Sleep -s 2
   
 ## screenshot ##

&$actionmd  -para3 nonlog -para5 "$actiontype_tab14"

$picfile1=(gci $picpath |?{$_.name -match ".jpg" -and $_.name -match "$actiontype_tab14" }|sort lastwritetime|select -last1).FullName

   [System.Windows.Forms.SendKeys]::SendWait("~")
    Start-Sleep -s 2

 $gpumid=(get-process -name GPUMon -ErrorAction SilentlyContinue).Id

if(-not($gpumid)){
 &"$scriptRoot\GPUMon\GPUMon.exe"
 start-sleep -s 10
 $gpumid=(get-process -name GPUMon).Id
  [Microsoft.VisualBasic.Interaction]::AppActivate($gpumid)
    Start-Sleep -s 1
  [System.Windows.Forms.SendKeys]::SendWait("{tab 13}")
      Start-Sleep -s 2



&$actionmd  -para3 nonlog -para5 "$actiontype_tab13"

$picfile2=(gci $picpath |?{$_.name -match ".jpg" -and $_.name -match "$actiontype_tab13" }|sort lastwritetime|select -last1).FullName
        
   [System.Windows.Forms.SendKeys]::SendWait("~")
     Start-Sleep -s 2
   }
   
 $gpumid=(get-process -name GPUMon).Id

  if($gpumid){

 ## screenshot ##

 
&$actionmd  -para3 nonlog -para5 "clickstart"

$picfile3=(gci $picpath |?{$_.name -match ".jpg" -and $_.name -match "clickstart" }|sort lastwritetime|select -last1).FullName


start-sleep -s 1
[System.Windows.Forms.SendKeys]::SendWait("~")

$results= "check screenshot"
 $index="$picfile"
}
  else{
  $results= "NG"
 $index="fail to start log"
  }

}
##

if($actiontype -match "end"){

 $gpumid=(get-process -name GPUMon).Id
   if($gpumid){

$tiemcheck1=get-date

do{
start-sleep -s 2
$checklogs=gci -path C:\testing_AI\* -Recurse  -File -Filter "GPUMon.log"|sort lastwritetime|select -last 1
$checktime=$checklogs.lastwritetime
$timespan=(New-TimeSpan -start $tiemcheck1 -end  $checktime).TotalSeconds
}until($timespan -gt 10)

$newlog=$checklogs.fullname

 $gpumid=(get-process -name GPUMon).Id
  [Microsoft.VisualBasic.Interaction]::AppActivate($gpumid)
    Start-Sleep -s 1
  [System.Windows.Forms.SendKeys]::SendWait("~")
   Start-Sleep -s 2         

 
&$actionmd  -para3 nonlog -para5 $actiontype

$picfile4=(gci $picpath |?{$_.name -match ".jpg" -and $_.name -match $actiontype }|sort lastwritetime|select -last1).FullName

(get-process -name GPUMon).CloseMainWindow()

$timestmp=Get-Date -Format "yyMMdd_HHmmss"

Move-Item  $newlog "$picpath\$($timestmp)_GPUMon.log" -Force

$picfile=[string]::Join("`n",$picfile1,$picfile2,$picfile4)

$results= "check screenshot and log"
 $index=$picfile

}

else{
$results= "NG"
 $index="no GPUMon is running"
}

}

}
######### write log #######

Get-Module -name "outlog"|remove-module
$mdpath=(gci -path "C:\testing_AI\modules\"  -r -file |?{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

#write-host "Do $action!"
outlog $action $results $tcnumber $tcstep $index


   }

    export-modulemember -Function gpumon