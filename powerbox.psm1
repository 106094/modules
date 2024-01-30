function powerbox ([string]$para1,[int64]$para2,[int64]$para3,[int64]$para4,[string]$para5){
      
  Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force;
    $wshell=New-Object -ComObject wscript.shell
      Add-Type -AssemblyName Microsoft.VisualBasic
       Add-Type -AssemblyName System.Windows.Forms
        Add-Type -AssemblyName System.Windows.Forms,System.Drawing
        $ping = New-Object System.Net.NetworkInformation.Ping
        
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

if($para2 -le 30){
$para2=30
}
if($para3 -eq 10){
$para3=10
}

$boxip=$para1
$ontime=$para2
$offtime=$para3
$cycletime=$para4
$nonlog_flag=$para5
$tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
$tcnumber=((get-content $tcpath).split(","))[0]
$tcstep=((get-content $tcpath).split(","))[1]
$action=((get-content $tcpath).split(","))[2]
$cmdline = $cmdline.Replace("##","$tcstep")

$picpath=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\"
if(-not(test-path $picpath)){new-item -ItemType directory -path $picpath |out-null}
$logpath=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\step$($tcstep)_cmd_output.txt"

$logcsv=(Split-Path -Parent $scriptRoot)+"\logs\logs_timemap.csv"
$starttime=(Get-ChildItem $logcsv).lastwritetime
$timepassed=(New-TimeSpan -start $starttime -end (Get-Date)).TotalMinutes + 2

$results="OK"
$index="powerbox action ok"

$actionts="taskschedule_atlogin"
Get-Module -name $actionts|remove-module
$mdpath=(Get-ChildItem -path $scriptRoot -r -file |Where-object{$_.name -match "^$actionts\b" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

$actiontsd="taskschedule_delete"
Get-Module -name $actiontsd|remove-module
$mdpath=(Get-ChildItem -path $scriptRoot -r -file |Where-object{$_.name -match "^$actiontsd\b" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

if($timepassed -lt $cycletime -or $cycletime -eq 0){

$actionss="screenshot"
Get-Module -name $actionss|remove-module
$mdpath=(Get-ChildItem -path $scriptRoot -r -file |Where-object{$_.name -match "^$actionss\b" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

#ping bix IP

    $testconnect=($ping.Send($boxip, 1000)).Status
    if($testconnect -ne "Success"){
        $results="NG"
        $index="powerbox PIN FAIL"
    }

 #ping ok, start send command
if($results -eq "OK"){
    
    &$actionts -para3 nonlog

    $cmdline_on="curl http://snmp:1234@$($boxip)/delay1.cgi?led=0,$($ontime),$($ontime),3,4,5,6,7,8"
    $cmdline_off="curl http://snmp:1234@$($boxip)/delayf1.cgi?led=0,$($offtime),$($offtime),3,4,5,6,7,8"
    $cmdport="curl http://snmp:1234@$($boxip)/offon.cgi?led=11000000"   
    
    $cmdlines=@($cmdline_on,$cmdline_off,$cmdport)  
       
    start-process cmd -WindowStyle Maximized
    Start-Sleep -Seconds 5
    $id2= (Get-Process -name $cmdtype|Sort-Object StartTime -ea SilentlyContinue |Select-Object -last 1).id
   
    ### click cmd window ###

[Microsoft.VisualBasic.interaction]::AppActivate($id2)|out-null
start-sleep -s 2

[Clicker]::LeftClickAtPoint(50, 1)
Start-Sleep -Seconds 2
$wshell.SendKeys("~") 
Start-Sleep -Seconds 2

foreach($cmdline in $cmdlines){
    Write-Output "now send : $cmdline"
    Set-Clipboard -value $cmdline
    Start-Sleep -Seconds 5
    [Microsoft.VisualBasic.interaction]::AppActivate($id2)|out-null
    start-sleep -s 1
    [Clicker]::LeftClickAtPoint(1,1)
    $wshell.SendKeys("E")
    start-sleep -s 1
    $wshell.SendKeys("p")
    start-sleep -s 1 
    $wshell.SendKeys("~") 
     } 

     &$actionss -para1 1 -para3 nonlog -para5 "cmd_end"

    if($cycletime -eq 0){
        &$actiontsd -para1 nonlog
        if($nonlog_flag.Length -eq 0){
        Get-Module -name "outlog"|remove-module
        $mdpath=(Get-ChildItem -path "C:\testing_AI\modules\"  -r -file |Where-object{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
        Import-Module $mdpath -WarningAction SilentlyContinue -Global
        #write-host "Do $action!"
        outlog $action $results $tcnumber $tcstep $index
        }
    }
     
    taskkill /PID $id2 /F  

 }
}
######### write log #######
if($timepassed -ge $cycletime){
    #remove taskschedule
    &$actiontsd -para1 nonlog
if($nonlog_flag.Length -eq 0){
Get-Module -name "outlog"|remove-module
$mdpath=(Get-ChildItem -path "C:\testing_AI\modules\"  -r -file |Where-object{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global
#write-host "Do $action!"
outlog $action $results $tcnumber $tcstep $index
}
    
  }

}
    export-modulemember -Function powerbox