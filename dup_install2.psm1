function dup_install2([string]$para1,[string]$para2,[string]$para3){
    
   Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force;
    #$wshell=New-Object -ComObject wscript.shell
      Add-Type -AssemblyName Microsoft.VisualBasic
      Add-Type -AssemblyName System.Windows.Forms

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

$duptype=$para1
$extractorinstall=$para2
$nonlog_flag=$para3

if($PSScriptRoot.length -eq 0){
$scriptRoot="C:\testing_AI\modules"
}
else{
$scriptRoot=$PSScriptRoot
}

$actionexp="filexplorer"
Get-Module -name $actionexp|remove-module
$mdpath=(Get-ChildItem -path $scriptRoot -r -file |Where-object{$_.name -match "^$actionexp\b" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

$actionss ="screenshot"
Get-Module -name $actionss|remove-module
$mdpath=(Get-ChildItem -path $scriptRoot -r -file |Where-object{$_.name -match "^$actionss\b" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

$actiontype=$extractorinstall
if($actiontype.Length -eq 0){$actiontype="extract_and_install"}
$action="DUP_$($actiontype)"

$tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
$tcnumber=((get-content $tcpath).split(","))[0]
$tcstep=((get-content $tcpath).split(","))[1]

$picpath=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\"
if(-not(test-path $picpath)){new-item -ItemType directory -path $picpath |out-null}

#defaul dup filename collect

$installfile=(Get-ChildItem ($scriptRoot+"\driver\$duptype\$($drvtype2)\N\") -File |Where-object{$_.name -match "\.exe"} |Sort-Object lastwritetime|Select-Object -first 1).fullname
 $installfilebn=(split-path -Leaf $installfile) -replace "\.exe",""

 write-host "The Display Type is $($drvtype2)"
 write-host "The Display Driver SWB is $($SWB)"

if($installfile){

$dupname10=$installfilebn.substring(0,10)
$dupnamepic=$installfilebn

## stop running ##
 
if($dupname10.Length -gt 0){
stop-process -name "$dupname10*" -ea SilentlyContinue
}
## extract ##

if($extractorinstall.Length -eq 0 -or $extractorinstall -match "extract"){

&$installfile 

do{
start-sleep -s 1
$dupid=(get-process -name "$dupname10*").Id
$windowTitle=(get-process -name "$dupname10*").mainwindowtitle
}until ($dupid -and $windowTitle)

$windowHandle = (get-process -name "$dupname10*").MainWindowHandle
$windowRect = New-Object RECT

 [Win32]::GetWindowRect($windowHandle, [ref]$windowRect)

    $left = $windowRect.Left
    $top = $windowRect.Top
    #$right = $windowRect.Right
    #$bottom = $windowRect.Bottom
         

[Microsoft.VisualBasic.interaction]::AppActivate($dupid)|out-null
  Start-Sleep -s 2
[Clicker]::LeftClickAtPoint($left+10,$top+10)
  Start-Sleep -s 2
   [System.Windows.Forms.SendKeys]::SendWait("{tab}")
   Start-Sleep -s 1
   [System.Windows.Forms.SendKeys]::SendWait("{tab}") 
   Start-Sleep -s 1
   [System.Windows.Forms.SendKeys]::SendWait("{tab}") 
   Start-Sleep -s 1
   [System.Windows.Forms.SendKeys]::SendWait("{tab}") 
  
   &$actionss -para3 nonlog -para5 "$($dupnamepic)_extract_start"
   
   [System.Windows.Forms.SendKeys]::SendWait(" ")
      Start-Sleep -s 5

     
   &$actionss -para3 nonlog -para5 "$($dupnamepic)_extract_selectfolder"

   [System.Windows.Forms.SendKeys]::SendWait("{tab}")
   Start-Sleep -s 1
   [System.Windows.Forms.SendKeys]::SendWait("{tab}") 
     Start-Sleep -s 1
     
   [System.Windows.Forms.SendKeys]::SendWait("{RIGHT}")
    Start-Sleep -s 1
   [System.Windows.Forms.SendKeys]::SendWait("{tab}")
   Start-Sleep -s 1
   [System.Windows.Forms.SendKeys]::SendWait(" ")
         
    $datenow=Get-Date -Format "yyMMdd_HHmmss"
    $newfd="$($datenow)_step$($tcstep)_$($installfilebn)_extract"
     Set-Clipboard -value $newfd
      start-sleep -s 5
     [System.Windows.Forms.SendKeys]::SendWait("^v")
     Start-Sleep -s 2
   [System.Windows.Forms.SendKeys]::SendWait("~")
   Start-Sleep -s 5
   [System.Windows.Forms.SendKeys]::SendWait("{tab}")
   Start-Sleep -s 1
   [System.Windows.Forms.SendKeys]::SendWait("{tab}")
   Start-Sleep -s 1
   [System.Windows.Forms.SendKeys]::SendWait(" ")

   $extractpath="$env:userprofile\$newfd"
    start-sleep -s 5

   do{
     start-sleep -s 5
     $checkextract=(get-process -name "$dupname10*"|Where-object{$_.mainwindowtitle.length -gt 0}).mainwindowtitle
       }until($checkextract.count -gt 0)
 
    start-sleep -s 5
    
    [Microsoft.VisualBasic.interaction]::AppActivate($dupid)|out-null
      Start-Sleep -s 2
    [Clicker]::LeftClickAtPoint($left+10,$top+10)
     Start-Sleep -s 1
  
   [System.Windows.Forms.SendKeys]::SendWait("{tab}")
   Start-Sleep -s 1
   [System.Windows.Forms.SendKeys]::SendWait("{tab}")
   Start-Sleep -s 1
   [System.Windows.Forms.SendKeys]::SendWait("{tab}")
      
    &$actionss -para3 nonlog -para5 "$($dupnamepic)_extract_complete"

   [System.Windows.Forms.SendKeys]::SendWait(" ")

   Move-Item  $extractpath -Destination $picpath -Force
   $extractpath2=$picpath+(Split-Path -Leaf $extractpath)

 if($dupname10.Length -gt 0){
stop-process -name "$dupname10*" -ea SilentlyContinue
}

&$actionexp -para1  $extractpath2 -para2 nonlog

   }

## install ##

if($extractorinstall.Length -eq 0 -or $extractorinstall -match "install"){

$datenow=Get-Date -Format "yyMMdd_HHmmss"
$enumerate_ibefore="$picpath$($datenow)_step$($tcstep)_enumerate_before_install.csv"
$enumd=pnputil /enum-drivers
set-content $enumerate_ibefore -value $enumd -Force

 $cmdbf=(get-process -name cmd -ea SilentlyContinue).Id

&$installfile 
do{
start-sleep -s 1
$dupid=(get-process -name "$dupname10*").Id
$windowTitle=(get-process -name "$dupname10*").mainwindowtitle
}until ($dupid -and $windowTitle)

$windowHandle = (get-process -name "$dupname10*").MainWindowHandle
$windowRect = New-Object RECT

 [Win32]::GetWindowRect($windowHandle, [ref]$windowRect)

    $left = $windowRect.Left
    $top = $windowRect.Top
    #$right = $windowRect.Right
    #$bottom = $windowRect.Bottom
         

[Microsoft.VisualBasic.interaction]::AppActivate($dupid)|out-null
  Start-Sleep -s 2
[Clicker]::LeftClickAtPoint($left+10,$top+10)
 Start-Sleep -s 2
   [System.Windows.Forms.SendKeys]::SendWait("{tab}")
   Start-Sleep -s 2
   [System.Windows.Forms.SendKeys]::SendWait("{tab}")
   Start-Sleep -s 2
   [System.Windows.Forms.SendKeys]::SendWait("{tab}")
   Start-Sleep -s 2
  
   &$actionss -para3 nonlog -para5 "$($dupnamepic)_install_start"
   

   [System.Windows.Forms.SendKeys]::SendWait(" ")

  
   do{
     start-sleep -s 5
     $checkextract=(get-process -name "$dupname10*"|Where-object{$_.mainwindowtitle.length -gt 0}).mainwindowtitle
       }until($checkextract.count -gt 0)
 
    start-sleep -s 5
    
    [Microsoft.VisualBasic.interaction]::AppActivate($dupid)|out-null
       Start-Sleep -s 2
     [Clicker]::LeftClickAtPoint($left+10,$top+10)
     Start-Sleep -s 2
  
   [System.Windows.Forms.SendKeys]::SendWait("{tab}")
    Start-Sleep -s 2
   [System.Windows.Forms.SendKeys]::SendWait("{tab}")
    Start-Sleep -s 2
   [System.Windows.Forms.SendKeys]::SendWait("{tab}")
      
    &$actionss -para3 nonlog -para5 "$($dupnamepic)_install_complete"

   [System.Windows.Forms.SendKeys]::SendWait(" ")
   
$datenow=get-date -format "yyMMdd_HHmmss"
$enumerate_iafter="$picpath$($datenow)_step$($tcstep)_enumerate_after_install.csv"
$enumd=pnputil /enum-drivers
set-content $enumerate_iafter -value $enumd -Force

 if($dupname10.Length -gt 0){
stop-process -name "$dupname10*" -ea SilentlyContinue
}

}

## getinfo ##

if($extractorinstall.Length -eq 0 -or $extractorinstall -match "info"){


&$installfile 

do{
start-sleep -s 1
$dupid=(get-process -name "$dupname10*").Id
$windowTitle=(get-process -name "$dupname10*").mainwindowtitle
}until ($dupid -and $windowTitle)

$windowHandle = (get-process -name "$dupname10*").MainWindowHandle
$windowRect = New-Object RECT

 [Win32]::GetWindowRect($windowHandle, [ref]$windowRect)

    $left = $windowRect.Left
    $top = $windowRect.Top
    #$right = $windowRect.Right
    #$bottom = $windowRect.Bottom
     

[Microsoft.VisualBasic.interaction]::AppActivate($dupid)|out-null
  Start-Sleep -s 2
[Clicker]::LeftClickAtPoint($left+10,$top+10)    
  Start-Sleep -s 2
   [System.Windows.Forms.SendKeys]::SendWait("{tab}")
   Start-Sleep -s 1
   [System.Windows.Forms.SendKeys]::SendWait("{tab}")
   Start-Sleep -s 1
   [System.Windows.Forms.SendKeys]::SendWait(" ")
    Start-Sleep -s 1


   [Clicker]::LeftClickAtPoint($left+10,$top+10)  
   Start-Sleep -s 2 
   [System.Windows.Forms.SendKeys]::SendWait("{tab}")
   Start-Sleep -s 1
   [System.Windows.Forms.SendKeys]::SendWait("{tab}")
   Start-Sleep -s 1 
    
    $heads=@("fixes_enhancement","Devices","Operating_Systems","Description","Updates")
    #$infotext=@()

    foreach($head in $heads){
   
     Set-Clipboard -Value " "
   
    $datenow=Get-Date -Format "yyMMdd_HHmmss"
    $dupinfo="$picpath$($datenow)_step$($tcstep)_DUP_info_$($head).txt"

    &$actionss -para3 nonlog -para5 "$($dupnamepic)_info_$($head)"
    [System.Windows.Forms.SendKeys]::SendWait("{tab}")
      start-sleep -s 1
    [System.Windows.Forms.SendKeys]::SendWait("^a")
      start-sleep -s 1
    [System.Windows.Forms.SendKeys]::SendWait("^c")
    start-sleep -s 2
    $infotextcontent=get-clipboard
    start-sleep -s 5
   #$infotext=$infotext+@("$($head):"+"`n" + "$($infotextcontent)")
    Set-Content -path $dupinfo -Value  $infotextcontent -Force

    [System.Windows.Forms.SendKeys]::SendWait("+{tab}")
     start-sleep -s 1

   [System.Windows.Forms.SendKeys]::SendWait("{DOWN}")
   
    }
    
    [System.Windows.Forms.SendKeys]::SendWait("{tab}")
     Start-Sleep -s 1 
    [System.Windows.Forms.SendKeys]::SendWait(" ")
     Start-Sleep -s 1 
    [System.Windows.Forms.SendKeys]::SendWait("%{F4}")

    #Set-Content -path $dupinfo -Value $infotext -Force

 if($dupname10.Length -gt 0){
stop-process -name "$dupname10*" -ea SilentlyContinue
}


}
$results="OK"
$index="check screenshots"
}
else{
$results="NG"
$index="no DUP filename is found"
}

######### write log #######

if($nonlog_flag.Length -eq 0 -or $timespanmin -gt 30){
Get-Module -name "outlog"|remove-module
$mdpath=(Get-ChildItem -path "C:\testing_AI\modules\"  -r -file |Where-object{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

#write-host "Do $action!"
outlog $action $results $tcnumber $tcstep $index
}
  }

    export-modulemember -Function  dup_install2