function ipmisettings ([string]$para1){

   Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force;
    $wshell=New-Object -ComObject wscript.shell
      Add-Type -AssemblyName Microsoft.VisualBasic
       Add-Type -AssemblyName System.Windows.Forms
        Add-Type -AssemblyName System.Windows.Forms,System.Drawing
       
$paracheck1=$PSBoundParameters.ContainsKey('para1')

if($paracheck1 -eq $false -or $para1.Length -eq 0){
$para1="enable"
}
else{
$para1="disable"
}

if($PSScriptRoot.length -eq 0){
$scriptRoot="C:\testing_AI\modules"
}
else{
$scriptRoot=$PSScriptRoot
}

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

$width  = ([string]::Join("`n", (wmic path Win32_VideoController get CurrentHorizontalResolution))).split("`n") -match "\d{1,}" |select -first 1
$height  = ([string]::Join("`n", (wmic path Win32_VideoController get CurrentVerticalResolution))).split("`n") -match "\d{1,}" |select -first 1

$actionss="screenshot"
Get-Module -name $actionss|remove-module
$mdpath=(gci -path $scriptRoot -r -file |?{$_.name -match "^$actionss\b" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

$action="ipmisettings - $changeto"

$tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
$tcnumber=((get-content $tcpath).split(","))[0]
$tcstep=((get-content $tcpath).split(","))[1]

$picpath=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\"
if(-not(test-path $picpath)){new-item -ItemType directory -path $picpath |out-null}
 

$changeto=$para1

$idracinfo=(get-content -path "C:\testing_AI\settings\idrac.txt").split(",")
$idracip=$idracinfo[0]
$idracuser=$idracinfo[1]
$idracpwd=$idracinfo[2]

$cmdline="C:\testing_AI\modules\ipmitool1818\ipmitool"

$checkipmiset=& $cmdline  -I lanplus -H $idracip -U $idracuser -P $idracpwd chassis power status

if($checkipmiset -match "Chassis Power is on" ){
$results="OK"
$index="$checkipmiset (Enable already)"
}

else{

$actionmd ="selenium_prepare"

Get-Module -name $actionmd|remove-module
$mdpath=(gci -path $scriptRoot -r -file |?{$_.name -match "^$actionmd\b" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

&$actionmd  edge nonlog

gci  "C:\testing_AI\modules\selenium\WebDriver.dll" |Unblock-File 
Add-Type -Path "C:\testing_AI\modules\selenium\WebDriver.dll"
 try{
 $driver = New-Object OpenQA.Selenium.Edge.EdgeDriver
 [OpenQA.Selenium.Interactions.Actions]$actions = New-Object OpenQA.Selenium.Interactions.Actions ($driver)
 }
 catch{
 try{
 $driverpath=(gci -path C:\testing_AI\modules\selenium\_default\edge\*\msedgedriver.exe|sort lastwritetime|select -Last 1).FullName
  copy-item $driverpath -Destination C:\testing_AI\modules\selenium\ -Force

  $driver = New-Object OpenQA.Selenium.Edge.EdgeDriver
  [OpenQA.Selenium.Interactions.Actions]$actions = New-Object OpenQA.Selenium.Interactions.Actions ($driver)

   }
    catch{
    $results="NG"
    $index="fail to install web driver"
    }
    }

 try{
$driver.Manage().Window.Maximize()
$driver.Navigate().GoToUrl("https://$idracip")
  }
    catch{
    $results="NG"
    $index="fail to install web driver"
    }
    
 if($results -ne "NG"){
   
   start-sleep -s 10

 do{
start-sleep -s 5
 $detailbt=$driver.FindElement([OpenQA.Selenium.By]:: ID("details-button"))
 }until($detailbt.Text -match "advanced")

 if($detailbt -ne $null){ $detailbt.click()
 start-sleep -s 2
  $detailbt2=$driver.FindElement([OpenQA.Selenium.By]:: ID("proceed-link"))
   $detailbt2.click()
      }
    
    start-sleep -s 5

    do{
        start-sleep -s 2
        $usenameinp=$driver.FindElement([OpenQA.Selenium.By]::ClassName("cui-start-screen-username"))
    }until( $usenameinp.TagName -eq "input")
    
 start-sleep -s 5
 $usenameinp.SendKeys($idracuser)

   start-sleep -s 2 
  $passwordinp=$driver.FindElement([OpenQA.Selenium.By]::ClassName("cui-start-screen-password"))
 $passwordinp.SendKeys($idracpwd)
  start-sleep -s 2 
 $sumitbt=$driver.FindElement([OpenQA.Selenium.By]::CssSelector("button[ng-click='onButtonAction(\'login\')']"))
 $sumitbt.Click()

 start-sleep -s 5

 $radioButton=$driver.FindElement([OpenQA.Selenium.By]::CssSelector("input[type='radio'][name='pwd_option'][value='1']"))
  if(  $radioButton -ne $null){
  $radioButton.Click()
  
  $checkButton=$driver.FindElement([OpenQA.Selenium.By]::CssSelector("input[type='checkbox'][ng-model='config.disableDCW']"))
  $checkButton.Click()

   $submitBt2=$driver.FindElement([OpenQA.Selenium.By]::CssSelector("button[ng-click='onButtonAction(\'dcw\')']"))
    $submitBt2.Click()
  }
  
start-sleep -s 10

#if small screen,check the website control
 $findjudge = $driver.FindElement([OpenQA.Selenium.By]::XPath("//button[@class='navbar-toggle mobileMenu']"))
 $findjudge.Click()
 start-sleep -s 10

 $idsetby=$driver.FindElement([OpenQA.Selenium.By]::Id("settings"))
 $idsetby.Click()
 #$idsetby=$driver.FindElement([OpenQA.Selenium.By]::XPath( "//*[@id=""scrollArea""]/div[1]/div[2]/nav/div/ul[1]/li[6]"))
 #$idsetby.Click()

start-sleep -s 20
 

 $idsetconn=$driver.FindElement([OpenQA.Selenium.By]::Id( "settings.connectivity"))
 $idsetconn.Click()

 start-sleep -s 10

   $idsetconn2=$driver.FindElement([OpenQA.Selenium.By]::Name("multi_acc_settings.connectivity.network"))
 $idsetconn2.Click()

  start-sleep -s 5
  $ipmiset=$driver.FindElement([OpenQA.Selenium.By]::Name( "acc_settings.connectivity.network.ipmilan"))
   $ipmiset.Click()

  start-sleep -s 5
  
 $setelement = $driver.FindElement([OpenQA.Selenium.By]::Id("settings.connectivity.network.ipmilan.Enable"))
$selected_option = $setelement.GetAttribute("value")


if($selected_option -match $changeto){
$index="no need to change settings"
}

else{

$option1 = $driver.FindElement([OpenQA.Selenium.By]::Id("settings.connectivity.network.ipmilan.Enable"))

Start-Sleep -s 5
if($changeto -eq "enable"){
$option1.SendKeys("e")
}
if($changeto -eq "disable"){
$option1.SendKeys("d")
}
Start-Sleep -s 5

 $wshell.SendKeys("{tab 3}")
 Start-Sleep -s 1
 $wshell.SendKeys("~")

 Start-Sleep -s 5

 $wshell.SendKeys("{tab}")
 
 $wshell.SendKeys("~")

 Start-Sleep -s 5
  $index="change settings done"

}

&$actionss  -para3 nonlog -para5 "ipmisettings"

$picfile=(gci $picpath |?{$_.name -match ".jpg" -and $_.name -match "ipmisettings" }).FullName


  $setelement = $driver.FindElement([OpenQA.Selenium.By]::Id("settings.connectivity.network.ipmilan.Enable"))
$selected_option = $setelement.GetAttribute("value")

if($selected_option -match $changeto){
$results="OK"
$index=$picfile
}
else{
$results="NG"
$index="fail to change settings"
}

### close web ###

$driver.Close()
$driver.Quit()
if((get-process -Name msedgedriver -ErrorAction SilentlyContinue)){Stop-Process -Name msedgedriver}
}

}


### write to log ###

Get-Module -name "outlog"|remove-module
$mdpath=(gci -path "C:\testing_AI\modules\" -r -file |?{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

#write-host "Do $action!"
outlog $action $results  $tcnumber $tcstep $index


  }