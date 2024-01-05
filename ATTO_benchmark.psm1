
function ATTO_benchmark ([string]$para1,[string]$para2){
      
    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force;
    $wshell=New-Object -ComObject wscript.shell
      Add-Type -AssemblyName Microsoft.VisualBasic
       Add-Type -AssemblyName System.Windows.Forms
        Add-Type -AssemblyName System.Windows.Forms,System.Drawing    

 if($para1.Length -eq 0){
 $para1="C"
 }

    $diskid=$para1
    $nonlog_flag=$para2

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
#endregion 
     
if($PSScriptRoot.length -eq 0){
$scriptRoot="C:\testing_AI\modules"
}
else{
$scriptRoot=$PSScriptRoot
}

$tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
$tcnumber=((get-content $tcpath).split(","))[0]
$tcstep=((get-content $tcpath).split(","))[1]
$action=((get-content $tcpath).split(","))[2]

$picpath=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\"
if(-not(test-path $picpath)){new-item -ItemType directory -path $picpath |out-null}
$logpath=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\step$($tcstep)_ATTO_benchmark_results.txt"

$actionss="screenshot"
Get-Module -name $actionss|remove-module
$mdpath=(Get-ChildItem -path $scriptRoot -r -file |?{$_.name -match "^$actionss\b" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global


$currentdisks= (get-psdrive -psprovider filesystem).name
$currentdiskstring=$currentdisks|Out-String
write-host "getdisk current all disks:$currentdiskstring"

$currentdisks2= ((Get-WmiObject -Class Win32_LogicalDisk | ?{$_.providername -notlike "\\*"}).name).replace(":","")
$currentdiskstring2=$currentdisks2|Out-String
write-host "getwinobj current all disks:$currentdiskstring2"

start-sleep -s 3
if(!($diskid -in $currentdisks -or $diskid -in $currentdisks2)){
write-host "Drive $diskid doesnot exist in $currentdiskstring or $currentdiskstring2, quit running, go to next step"
  $results="NG"
  $index="no disk $diskid exist (current disks:$currentdiskstring/$currentdiskstring2)"
   start-process explorer file:\\ -WindowStyle Maximized 
       start-sleep -s 5 
    &$actionss  -para3 nonlog　-para5 "diskcheck" 
     $shell = New-Object -ComObject Shell.Application
      foreach ($window in $shell.windows()){$window.quit()}

  }

else{
$attoexe=(Get-ChildItem $scriptRoot\* -r -file "ATTODiskBenchmark.exe"|Sort-Object lastwritetime|select -Last 1).fullname
if(!$attoexe){
$results="NG"
$index="fail to find ATTODiskBenchmark.exe in modules folder"
}
else{

do{
$checkrun=get-process -name ATTODiskBenchmark -ea SilentlyContinue
if($checkrun){
stop-process -name ATTODiskBenchmark -Force -ErrorAction SilentlyContinue
start-sleep -s 3
}

&$attoexe

start-sleep -s 3
$attoid=(get-process -name ATTODiskBenchmark|sort starttime|select -last 1).Id
$windowTitle=(get-process -name ATTODiskBenchmark).mainwindowtitle
$windowHandle = (get-process -name ATTODiskBenchmark).MainWindowHandle
$windowRect = New-Object RECT
[Win32]::GetWindowRect($windowHandle, [ref]$windowRect)

    $left = $windowRect.Left
    $top = $windowRect.Top

  [Microsoft.VisualBasic.interaction]::AppActivate($attoid)|out-null
   start-sleep -s 2
    [Clicker]::LeftClickAtPoint($left+60,$top+10)
   start-sleep -s 2 
  [System.Windows.Forms.SendKeys]::SendWait("$diskid")
   start-sleep -s 2 
   [System.Windows.Forms.SendKeys]::SendWait("%s")
   start-sleep -s 20

   $processName = "ATTODiskBenchmark"

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

    if($acceessmb -eq 0){
     (get-process -name ATTODiskBenchmark).CloseMainWindow()

    }
    else{
    
   &$actionss -para3 "nolog" -para5 "start"

    }


   }until($acceessmb -gt 0)


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

   &$actionss -para3 "nolog" -para5 "end"

   
    [Clicker]::LeftClickAtPoint($left+60,$top+10)
       start-sleep -s 2
     [System.Windows.Forms.SendKeys]::SendWait("%f")
     start-sleep -s 2
     [System.Windows.Forms.SendKeys]::SendWait("a")
    $timenow=get-date -format "yyMMdd_HHmmss"
   $filename="$($timenow)_step$($tcstep)_attoresults.bmk"
    Set-Clipboard $filename
   start-sleep -s 5
   
     [System.Windows.Forms.SendKeys]::SendWait("^v")
     start-sleep -s 2
     [System.Windows.Forms.SendKeys]::SendWait("%s")
     start-sleep -s 5
     (get-process -name ATTODiskBenchmark).CloseMainWindow()

     $attofile=((Get-ChildItem $env:userprofile\documents\*.bmk)|sort lastwritetime|select -last 1).fullname
    

     $results="OK"
     $index="check $($filename)"

     try{ move-item $attofile -Destination $picpath -Force }
     catch{
      $results="NG"
     $index="fail to get $($filename)"
     }
     
}
}
write-host "$results, $index"

######### write log #######

if($nonlog_flag.Length -eq 0){
Get-Module -name "outlog"|remove-module
$mdpath=(Get-ChildItem -path "C:\testing_AI\modules\"  -r -file |?{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

#write-host "Do $action!"
outlog $action $results $tcnumber $tcstep $index
}
   

   }

    export-modulemember -Function ATTO_benchmark