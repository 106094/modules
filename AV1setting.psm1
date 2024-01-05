function Av1setting ([string]$para1,[string]$para2){

    Add-Type -AssemblyName System.Windows.Forms
    
    if($PSScriptRoot.length -eq 0){
        $scriptRoot="C:\testing_AI\modules\"
    }
    else{
        $scriptRoot=$PSScriptRoot
    }

    
    $tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
    $tcnumber=((get-content $tcpath).split(","))[0]
    $tcstep=((get-content $tcpath).split(","))[1]

    $action="AV1_settings"

$screen = [System.Windows.Forms.Screen]::PrimaryScreen
$bounds = $screen.Bounds
$xco =  $bounds.Width/2
$yco = $bounds.Height*0.7

$actionss ="screenshot"
Get-Module -name $actionss|remove-module
$mdpath=(Get-ChildItem -path $scriptRoot -r -file |Where-object{$_.name -match "^$actionss\b" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

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
 
      
    $actionmd ="selenium_prepare"

    Get-ChildItem  "C:\testing_AI\modules\selenium\WebDriver.dll" |Unblock-File 
    Add-Type -Path "C:\testing_AI\modules\selenium\WebDriver.dll"

    Get-Module -name $actionmd|remove-module
    $mdpath=(Get-ChildItem -path $scriptRoot -r -file |Where-object{$_.name -match "^$actionmd\b" -and $_.name -match "psm1"}).fullname
    Import-Module $mdpath -WarningAction SilentlyContinue -Global

    $login = Get-Content "C:\testing_AI\settings\google_account.txt"
    $Account = $login[0]
    $Password = $login[1]

 try{

    if($para1 -eq "chrome"){
        &$actionmd  chrome nonlog
    }
    if($para1 -eq "firefox"){
        &$actionmd  firefox nonlog
    }

    if($para1 -eq "chrome"){
        $driver = New-Object OpenQA.Selenium.Chrome.ChromeDriver
    }
    if($para1 -eq "firefox"){
        $driver = New-Object OpenQA.Selenium.Firefox.FirefoxDriver
    }
    }
 catch{
    $results="NG"
    $index="fail to install web driver"
    }
    if($results -ne "NG"){
    ## maximum webbrowser window

    $driver.Manage().Window.Maximize()

    ## login google account if chrome or firefox ##

    $failcount=0

    if($para1 -match "firefox" -or $para1 -match "chrome" ){

        $driver.Navigate().GoToUrl("https://www.youtube.com")
         start-sleep -s 30  

    do{
         
        $loginbt=($driver.FindElement([OpenQA.Selenium.By]::ClassName("yt-spec-button-shape-next--icon-leading")))
        #$href = $loginbt.GetAttribute("href")
        $loginbt.click()
        start-sleep -s 10

        $inputid=($driver.FindElement([OpenQA.Selenium.By]::Id("identifierId")))
        #$href = $loginbt.GetAttribute("href")
        $inputid.SendKeys($Account)
        start-sleep -s 5

        $inputidnext=($driver.FindElement([OpenQA.Selenium.By]::Id("identifierNext")))
        $inputidnext.Click()
        #start-sleep -s 2
        #[System.Windows.Forms.SendKeys]::SendWait("{tab 3}")
        #start-sleep -s 2
        #[System.Windows.Forms.SendKeys]::SendWait("~")
        start-sleep -s 10

        ### check if captha
        $inputcaptcha=($driver.FindElement([OpenQA.Selenium.By]::Id("ca")))
        if($inputcaptcha.Displayed){
         $timenow=Get-Date
         $timenow2=Get-Date -format "yyyyMMdd_HHmm"
         $sysname="$env:USERNAME"
         $waringfile="\\192.168.2.249\srvprj\Inventec\Dell\Matagorda\07.Tool\_AutoTool_Monitor\warnings\$($sysname)_GoogleLoginCaptcha_$($timenow2).txt"
         New-item -path $waringfile -Force |Out-Null
        
         do{         
         write-host "waiting for manual help"
         start-sleep -s 30
         $timenow2=Get-Date
         $inputcaptcha=($driver.FindElement([OpenQA.Selenium.By]::Id("ca")))
         $wattingtime=(New-TimeSpan -start  $timenow -end $timenow2).TotalMinutes
         }until($wattingtime -gt 60 -or !($inputcaptcha.Displayed))
        

         if($wattingtime -gt 60){
         remove-item $waringfile -Force |Out-Null
          $driver.Close()
          $driver.Dispose()
              ######### write log #######
          $results="NG"
          $index="fail caused by Google Captcha"

         }

         if(!($inputcaptcha.Displayed)){
         remove-item $waringfile -Force |Out-Null
         }


        }
        
         if(!($inputcaptcha.Displayed)){

               
        $inputpasswd=$driver.FindElement([OpenQA.Selenium.By]::Id("password"))
        $inputpasswd.click()
        start-sleep -s 2
         $inputpasswd2=($driver.FindElement([OpenQA.Selenium.By]::Name("Passwd")))
         $inputpasswd2.SendKeys($Password)
        start-sleep -s 2

        $Passidnext=($driver.FindElement([OpenQA.Selenium.By]::Id("passwordNext")))
        $Passidnext.Click()
        start-sleep -s 60

        [System.Windows.Forms.SendKeys]::SendWait("{esc}")

        $driver.Navigate().GoToUrl("https://www.youtube.com/account_playback")
         start-sleep -s 20
         
         $checkpage=$driver.Url

      if($para1 -match "chrome" -and !($checkpage -match "https://www.youtube.com/account_playback")){
         $failcount++
         write-host "fail sync account $($failcount) time" 
        [System.Windows.Forms.SendKeys]::SendWait("{esc}")
        start-sleep -s 1
        [System.Windows.Forms.SendKeys]::SendWait("^+{delete}")
        start-sleep -s 2
        [Clicker]::LeftClickAtPoint($xco, $yco)
        start-sleep -s 1
        [System.Windows.Forms.SendKeys]::SendWait("{tab 2}")
        start-sleep -s 1
        [System.Windows.Forms.SendKeys]::SendWait("{Down 4}")
        start-sleep -s 1
        [System.Windows.Forms.SendKeys]::SendWait("{tab 5}")
        start-sleep -s 1
        [System.Windows.Forms.SendKeys]::SendWait("~")
        start-sleep -s 10
        [System.Windows.Forms.SendKeys]::SendWait("^w")
        start-sleep -s 1
        $driver.Navigate().GoToUrl("https://www.youtube.com")
        start-sleep -s 30
        
         }

       }
       }until($checkpage -match "https://www.youtube.com/account_playback" -or $wattingtime -gt 60 )

        if($checkpage -match "https://www.youtube.com/account_playback"){
        start-sleep -s 5
        [System.Windows.Forms.SendKeys]::SendWait("^f")

        Set-Clipboard "AV1"
        start-sleep -s 3
        [System.Windows.Forms.SendKeys]::SendWait("^V")
        start-sleep -s 3
        [System.Windows.Forms.SendKeys]::SendWait("{ESC}")
        start-sleep -s 3
        [System.Windows.Forms.SendKeys]::SendWait("{TAB 3}")
        start-sleep -s 1
        [System.Windows.Forms.SendKeys]::SendWait("{ENTER}")
                
        &$actionss -para3 nonlog -para5 AV1settings
    

    $results="-"
    $index="check screenshots"

    $driver.Close()
    $driver.Dispose()
    }
    }

}
    ######### write log #######
    if($para2.length -eq 0){
        Get-Module -name "outlog"|remove-module
        $mdpath=(Get-ChildItem -path "C:\testing_AI\modules\"  -r -file |Where-object{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
        Import-Module $mdpath -WarningAction SilentlyContinue -Global

        #write-host "Do $action!"
        outlog $action $results $tcnumber $tcstep $index
    }
}

export-modulemember -Function Av1setting