
function cmdline_endless ([string]$para1,[string]$para2,[string]$para3,[string]$para4,[string]$para5){
      
    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force;
    $wshell=New-Object -ComObject wscript.shell
      Add-Type -AssemblyName Microsoft.VisualBasic
       Add-Type -AssemblyName System.Windows.Forms
        Add-Type -AssemblyName System.Windows.Forms,System.Drawing    
        
    $cmdline=$para1
    $cmdpath=$para2
    $cmdtype=$para3
    $calltool=$para4
    $nonlog_flag=$para5

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

$tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
$tcnumber=((get-content $tcpath).split(","))[0]
$tcstep=((get-content $tcpath).split(","))[1]
$action=((get-content $tcpath).split(","))[2]

$picpath=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\"
if(-not(test-path $picpath)){new-item -ItemType directory -path $picpath |out-null}
$logpath=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\step-$($tcstep)-cmdresult.txt"

$actionss="screenshot"
Get-Module -name $actionss|remove-module
$mdpath=(Get-ChildItem -path $scriptRoot -r -file |Where-object{$_.name -match "^$actionss\b" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global


 if($cmdline.Length -eq 0){
  
 $results="NG"
 $index="No command line is found"

  }
  else {
    
    

## setlocation ###
   
   if($cmdpath.length -ne 0){
      Set-Location $cmdpath
     }
    
if($cmdtype -match "cmd"){
start-process cmd -WindowStyle Maximized
}
if($cmdtype -match "powershell"){
start-process "$PSHOME\powershell.exe"  -WindowStyle Maximized
}

Start-Sleep -Seconds 5
$id2= (Get-Process -name $cmdtype|sort StartTime -ea SilentlyContinue |select -last 1).id
$cmdwindowhd=(Get-Process -name $cmdtype |sort StartTime -ea SilentlyContinue |select -last 1).MainWindowHandle 

$checkrun1=(get-process -name  $calltool -ea SilentlyContinue).Id

### click cmd window ###

Set-Clipboard -value $cmdline
Start-Sleep -Seconds 5

[Microsoft.VisualBasic.interaction]::AppActivate($id2)|out-null
start-sleep -s 2

[Clicker]::LeftClickAtPoint(50, 1)
Start-Sleep -Seconds 2
$wshell.SendKeys("~") 
Start-Sleep -Seconds 2
$wshell.SendKeys("^v")
Start-Sleep -Seconds 2

  &$actionss  -para3 nonlog -para5 "cmd_input"

  $picfile= $picfile+@((Get-ChildItem $picpath |Where-object{$_.name -match ".jpg"}|sort creationtime|select -last 1).FullName)

$wshell.SendKeys("~")

### check call out exe is in process  ###
    
 do{  
  start-sleep -s 2
   $checkrun2=get-process -name  $calltool
    if($checkrun1.count -ne 0){ $checkrun2=get-process -name  $calltool|Where-object{$_.id -notin $checkrun1}}

    }until($checkrun2 )
         
$idtool=$checkrun2.Id

Start-Sleep -s 10

 ## screenshot ##
 
 [Microsoft.VisualBasic.interaction]::AppActivate($idtool)|out-null

  &$actionss  -para3 nonlog -para5 "$calltool"

  $picfile= $picfile+@((Get-ChildItem $picpath |Where-object{$_.name -match ".jpg" -and $_.name -match $action }|sort creationtime|select -last 1).FullName)
    
echo %errorlevel%

 if(!($calltool -match "cmd" -or $calltool -match "powershell")){ stop-process -id $idtool -Force}
  
### copy text in window  ###
    
    do{
    
    start-sleep -s 2
    [Microsoft.VisualBasic.interaction]::AppActivate($id2)|out-null
     start-sleep -s 1
    [Clicker]::LeftClickAtPoint(1,1)
    $wshell.SendKeys("E")
    start-sleep -s 1
    $wshell.SendKeys("S")
    start-sleep -s 1
    $wshell.SendKeys("~")
    start-sleep -s 1
    $index2=Get-Clipboard
    start-sleep -s 2
     $checkend=$index2[-1]
     if($checkend.length -gt 0){$endcheck=$checkend.Substring($checkend.length-1,1)}
     else{$endcheck=""}
     }until($endcheck -eq ">" -and $checkend.length -gt 0 )

  if($cmdtype -match "cmd"){
     　Set-Clipboard -value "echo %errorlevel%"
       Start-Sleep -s 5
        $wshell.SendKeys("^v") 
         }
        if($cmdtype -match "powershell"){
      $wshell.SendKeys("\?")
         }
        Start-Sleep -s 2
         $wshell.SendKeys("~")

  do{
    
    start-sleep -s 2
    [Microsoft.VisualBasic.interaction]::AppActivate($id2)|out-null
     start-sleep -s 1
    [Clicker]::LeftClickAtPoint(1,1)
    $wshell.SendKeys("E")
    start-sleep -s 1
    $wshell.SendKeys("S")
    start-sleep -s 1
    $wshell.SendKeys("~")
    start-sleep -s 1
    $index2=Get-Clipboard
    start-sleep -s 2
     $checkend=$index2[-1]
     if($checkend.length -gt 0){$endcheck=$checkend.Substring($checkend.length-1,1)}
     else{$endcheck=""}
     }until($endcheck -eq ">" -and $checkend.length -gt 0 )


  &$actionss  -para3 nonlog -para5 "cmd_end"

    
   $picfile= $picfile+@((Get-ChildItem $picpath |Where-object{$_.name -match ".jpg" -and $_.name -match $action }|sort creationtime|select -last 1).FullName)

$datenow=get-date -format "yyMMdd_HHmmss"
$logpath=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\$($datenow)_step$($tcstep)_cmdresult.txt"

 set-content $logpath -Value  $index2
 
  taskkill /PID $id2 /F

 ###>

 $results="check log"
 $index="check screen shots"
 
 

 }
  
######### write log #######

if($nonlog_flag.Length -eq 0){
Get-Module -name "outlog"|remove-module
$mdpath=(Get-ChildItem -path "C:\testing_AI\modules\"  -r -file |Where-object{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

#write-host "Do $action!"
outlog $action $results $tcnumber $tcstep $index
}
    


   }

    export-modulemember -Function cmdline_endless