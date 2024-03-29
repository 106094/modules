﻿function clear_idracsession ([string]$para1){
      
  Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force;
    $wshell=New-Object -ComObject wscript.shell
      Add-Type -AssemblyName Microsoft.VisualBasic
       Add-Type -AssemblyName System.Windows.Forms
        Add-Type -AssemblyName System.Windows.Forms,System.Drawing    
        
    $nonlog_flag=$para1

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
try{
Add-Type -TypeDefinition $cSource -ReferencedAssemblies System.Windows.Forms,System.Drawing
}
catch{
write-host "."
}
     
if($PSScriptRoot.length -eq 0){
$scriptRoot="C:\testing_AI\modules"
}
else{
$scriptRoot=$PSScriptRoot
}

$tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
$tcnumber=((get-content $tcpath).split(","))[0]
$tcstep=((get-content $tcpath).split(","))[1]
$action="clear iDRAC sessions"
$index="check screenshots"

$checkidracset=test-path "C:\testing_AI\settings\idrac.txt"
if($checkidracset){
  $idracinfo=(get-content -path "C:\testing_AI\settings\idrac.txt").split(",")
  $idracip=$idracinfo[0]
  #$idracuser=$idracinfo[1]
  $idracpwd=$idracinfo[2]

$cmdline = "ssh root@$($idracip) -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no|$($idracpwd)|closessn -a|exit"

$picpath=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\"
if(-not(test-path $picpath)){new-item -ItemType directory -path $picpath |out-null}

$actionss="screenshot"
Get-Module -name $actionss|remove-module
$mdpath=(Get-ChildItem -path $scriptRoot -r -file |Where-object{$_.name -match "^$actionss\b" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global
   
               
  #### open cmd ##
  start-process cmd -WindowStyle Maximized

Start-Sleep -Seconds 5
$id2= (Get-Process -name cmd|Sort-Object StartTime -ea SilentlyContinue |Select-Object -last 1).id
#$cmdwindowhd=(Get-Process -name $cmdtype |Sort-Object StartTime -ea SilentlyContinue |Select-Object -last 1).MainWindowHandle 

### click cmd window ###

[Microsoft.VisualBasic.interaction]::AppActivate($id2)|out-null
start-sleep -s 2

[Clicker]::LeftClickAtPoint(50, 1)
Start-Sleep -Seconds 2
$wshell.SendKeys("~") 
Start-Sleep -Seconds 2

$cmdlines=$cmdline.split("|")
$k=0

foreach($cmdline in $cmdlines){
    write-host "now send : $cmdline"
    $k++
    Set-Clipboard -value $cmdline
    Start-Sleep -Seconds 5
    [Microsoft.VisualBasic.interaction]::AppActivate($id2)|out-null
    start-sleep -s 1
    [Clicker]::LeftClickAtPoint(1,1)
    $wshell.SendKeys("E")
    start-sleep -s 1
    $wshell.SendKeys("p")
    start-sleep -s 1 
    Start-Sleep -Seconds 3
    $wshell.SendKeys("~") 
    Start-Sleep -Seconds 3 
    }      

    
    [Clicker]::LeftClickAtPoint(1,1)
    $wshell.SendKeys("E")
    start-sleep -s 1
    $wshell.SendKeys("S")
    start-sleep -s 1 
    Start-Sleep -Seconds 3
    $wshell.SendKeys("~") 
    Start-Sleep -Seconds 3
    $cmdcontent=Get-Clipboard
    Start-Sleep -Seconds 5
    if($cmdcontent -match "successfully"){
        $results="OK"
         &$actionss  -para3 nonlog -para5 "sessionclear_ok"
    }
    else{
        $results="NG"
        &$actionss  -para3 nonlog -para5 "sessionclear_fail"
    }
             

         taskkill /PID $id2 /F  
  
  }
  else{
    
    $results="-"
    $index="no iDRAC settings"
  }
      
 ###>
    
    ######### write log #######

    if($nonlog_flag.Length -eq 0){
    Get-Module -name "outlog"|remove-module
    $mdpath=(Get-ChildItem -path "C:\testing_AI\modules\"  -r -file |Where-object{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
    Import-Module $mdpath -WarningAction SilentlyContinue -Global
    #write-host "Do $action!"
    outlog $action $results $tcnumber $tcstep $index
    }
    
  }

    export-modulemember -Function  clear_idracsession