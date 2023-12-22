

function iometer_run ([string]$para1,[string]$para2,[string]$para3){
    
    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force;
    $wshell=New-Object -ComObject wscript.shell
    $shell=New-Object -ComObject shell.application
    Add-Type -AssemblyName Microsoft.VisualBasic
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Windows.Forms,System.Drawing 

    $clickSource = @'
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
Add-Type -TypeDefinition $clickSource -ReferencedAssemblies System.Windows.Forms,System.Drawing



    $paracheck=$PSBoundParameters.ContainsKey('para1')

    if( $paracheck -eq $false -or $para1.length -eq 0 ){
        $para1=""
    }

    $Toolpath=$para1
    $scriptName = $para2
    $nolog_flag=$para3

    if($PSScriptRoot.length -eq 0){
        $scriptRoot="C:\testing_AI\modules"
    }
    else{
        $scriptRoot=$PSScriptRoot
    }


    $tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
    $tcnumber=((get-content $tcpath).split(","))[0]
    $tcstep=((get-content $tcpath).split(","))[1]

    $iometerpath=(gci "$Toolpath\IOMETER.exe").FullName


    ############################## run ioMeter ##############################
    &$iometerpath

    $i = 0
    while(!$IOProcess){
        if(($i -eq 3)){
            &$iometerpath
            break
        }
        $IOProcess = Get-Process -Name "*IOmeter*"
        Start-Sleep -s 20
        $i += 1
    }

    Start-Sleep -s 5

    $IOProcess = Get-Process -Name "*IOmeter*"

    if(!$IOProcess){
        $results="NG"
        $action="Open IOMeter Failed"
    }

    [System.Windows.Forms.SendKeys]::Sendwait("^o")
    Start-Sleep -s 15
    [System.Windows.Forms.SendKeys]::Sendwait(($Toolpath+ "\" +$scriptName))
    Start-Sleep -s 5
    [System.Windows.Forms.SendKeys]::Sendwait("{ENTER}")

    Start-Sleep -s 5

    $actionsw ="Set_Window"
    Get-Module -name $actionsw|remove-module
    $mdpath=(gci -path $scriptRoot -r -file |?{$_.name -match "^$actionsw\b" -and $_.name -match "psm1"}).fullname
    Import-Module $mdpath -WarningAction SilentlyContinue -Global

    Set_Window -para1 "IOMeter" -para4 "nonlog"


    Start-Sleep -s 5

    [Clicker]::LeftClickAtPoint(270, 60)  ## click
    Start-Sleep -s 20
    [System.Windows.Forms.SendKeys]::Sendwait("C:\testing_AI\logs\$tcnumber\step$($tcstep)_iometerlog.csv")
    Start-Sleep -s 5
    [System.Windows.Forms.SendKeys]::Sendwait("{ENTER}")


    #calcu wait time
    $scriptText = Get-Content -Path "$Toolpath\$scriptName"

    foreach($text in $scriptText){
        if($text -match "hours"){
            $timeStamp = $scriptText[$text.ReadCount].TrimStart()
            $timeStamp = $timeStamp -split '\s+'
        }
    }

    $totalsec = [int]$timeStamp[0] *3600 + [int]$timeStamp[1] *60 + [int]$timeStamp[2]
    
    Start-Sleep -s $totalsec

    if(gci "C:\testing_AI\logs\$tcnumber\step$($tcstep)_iometerlog.csv"){
        $results="OK"
        $action="IOMeter Run Success"
    }else{
        $results="NG"
        $action="Log not exist"
    }
    

    ######### write log #######
    
    if($nolog_flag.length -eq 0){
        Get-Module -name "outlog"|remove-module
        $mdpath=(gci -path "C:\testing_AI\modules\"  -r -file |?{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
        Import-Module $mdpath -WarningAction SilentlyContinue -Global

        #write-host "Do $action!"
        outlog $action $results $tcnumber $tcstep $index
    }
}

    export-modulemember -Function iometer_run