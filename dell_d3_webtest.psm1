
function dell_d3_webtest{
     
    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force;
    $wshell=New-Object -ComObject wscript.shell
    Add-Type -AssemblyName Microsoft.VisualBasic
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Windows.Forms,System.Drawing
      
      
    $source = @"
using System;
using System.Threading.Tasks;
using System.Runtime.InteropServices;
using System.Windows.Forms;
namespace KeySends
{
    public class KeySend
    {
        [DllImport("user32.dll")]
        public static extern void keybd_event(byte bVk, byte bScan, int dwFlags, int dwExtraInfo);
        private const int KEYEVENTF_EXTENDEDKEY = 1;
        private const int KEYEVENTF_KEYUP = 2;
        public static void KeyDown(Keys vKey)
        {
            keybd_event((byte)vKey, 0, KEYEVENTF_EXTENDEDKEY, 0);
        }
        public static void KeyUp(Keys vKey)
        {
            keybd_event((byte)vKey, 0, KEYEVENTF_EXTENDEDKEY | KEYEVENTF_KEYUP, 0);
        }
    }
}
"@
    Add-Type -TypeDefinition $source -ReferencedAssemblies "System.Windows.Forms"
    
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

if($PSScriptRoot.length -eq 0){
$scriptRoot="C:\testing_AI\modules"
}
else{
$scriptRoot=$PSScriptRoot
}


#$width  = (([string]::Join("`n", (wmic path Win32_VideoController get CurrentHorizontalResolution))).split("`n") -match "\d{1,}")[0]
#$height  = (([string]::Join("`n", (wmic path Win32_VideoController get CurrentVerticalResolution))).split("`n") -match "\d{1,}")[0]

$action="dellapp_webtest"
$tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
$tcnumber=((get-content $tcpath).split(","))[0]
$tcstep=((get-content $tcpath).split(","))[1]

$picpath=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\"
if(-not(test-path $picpath)){new-item -ItemType directory -path $picpath |out-null}

$appname="Dell Digital Delivery"

#---------------------------------------------------------------------------------------------------------------------

## Install D3

$actionmdI="driverinstall"
Get-Module -name $actionmdI|remove-module
$mdpathI=(Get-ChildItem -path $scriptRoot -r -file |?{$_.name -match "^$actionmdI\b" -and $_.name -match "psm1"}).fullname
Import-Module $mdpathI -WarningAction SilentlyContinue -Global

driverinstall -para1 "D3" -para2 "Dell-Alienware-Digital-Delivery-Application_CX6KY_WIN_5.0.62.0_A22.EXE" -para3 "Dell-Alienware-Digital-Delivery-Application_CX6KY_WIN_5.0.62.0_A22.EXE -s" -para4 "cmd" -para5 "nonlog"

#Get-AppXPackage -AllUsers | Foreach {Add-AppxPackage -DisableDevelopmentMode -Register "$($_.InstallLocation)\AppXManifest.xml"}
#Start-Sleep -s 3
#[KeySends.KeySend]::KeyDown("LWin")
#[KeySends.KeySend]::KeyDown("S")
#[KeySends.KeySend]::KeyUp("LWin")
#Start-Sleep -s 3
#[System.Windows.Forms.SendKeys]::SendWait($appname)
#[System.Windows.Forms.SendKeys]::SendWait("{ENTER}")
#Start-Sleep -s 40
#[System.Windows.Forms.SendKeys]::SendWait("{TAB}")
#Start-Sleep -s 5
#[System.Windows.Forms.SendKeys]::SendWait("{ENTER}")


## check if D3 install ##
$flag = 0
 echo "Watting for $appname Install , wait time is $flag minutes"

do{
     $checkd3= Get-AppxPackage | Where-Object {$_.Name -like "*DellDigitalDelivery*"}
     #$checkd3= Get-Package | where{$_.name -match $appname}
     #$flag += 1
     if(!$checkd3){
     Start-Sleep -s 60
     $flag += 1
     echo "Watting for $appname Install , wait time is $flag minutes"
     
     }
}until(($checkd3) -or ($flag -gt 10))  ## if 10 minute quit
 

if($checkd3){

$actionmd="screenshot"
Get-Module -name $actionmd|remove-module
$mdpath=(Get-ChildItem -path $scriptRoot -r -file |?{$_.name -match "^$actionmd\b" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

$screen = [System.Windows.Forms.Screen]::PrimaryScreen
$bounds = $screen.Bounds
$width  = $bounds.Width
$height = $bounds.Height


(get-process msedge -ea SilentlyContinue|?{$_.MainWindowHandle -ne 0}|stop-process)

#####

    [KeySends.KeySend]::KeyDown("LWin")
        [KeySends.KeySend]::KeyUp("LWin")
   
   Set-Clipboard -Value $appname
   Start-Sleep -s 5
   
   [System.Windows.Forms.SendKeys]::SendWait("$appname")
    Start-Sleep -s 10
   [System.Windows.Forms.SendKeys]::SendWait("~")
    Start-Sleep -s 30
    
   
## screen capture ##

&$actionmd  -para3 nonlog


   Start-Sleep -s 2
   [System.Windows.Forms.SendKeys]::SendWait("{tab}")
   Start-Sleep -s 2
   [System.Windows.Forms.SendKeys]::SendWait("~")
   Start-Sleep -s 2
   [System.Windows.Forms.SendKeys]::SendWait("{tab 3}")
   Start-Sleep -s 2
   [System.Windows.Forms.SendKeys]::SendWait("~")
    Start-Sleep -s 2
    
  do{
   Start-Sleep -s 2
   $edgeid=(get-process msedge -ea SilentlyContinue|?{($_.MainWindowTitle).length -gt 0}).Id
  }until($edgeid)
  
   Start-Sleep -s 10
  
  [Microsoft.VisualBasic.interaction]::AppActivate($edgeid)|out-null

  Set-Clipboard -Value "APEX"
   Start-Sleep -s 5
   [System.Windows.Forms.SendKeys]::SendWait("^f")   
   Start-Sleep -s 2
   [System.Windows.Forms.SendKeys]::SendWait("^v")   
   Start-Sleep -s 2
   [System.Windows.Forms.SendKeys]::SendWait("~")
   Start-Sleep -s 1
   [System.Windows.Forms.SendKeys]::SendWait("{esc}")

## screen capture ##

&$actionmd  -para3 nonlog -para5 "2"

   [System.Windows.Forms.SendKeys]::SendWait("~")



## screen capture ##

&$actionmd  -para3 nonlog -para5 "3"


## screen capture ##

&$actionmd  -para3 nonlog -para5 "4"

get-process msedge -ea SilentlyContinue|?{$_.MainWindowHandle -ne 0}|stop-process -Force

get-process dell.d3.uwp -ea SilentlyContinue|stop-process  -Force


$picfiles=(Get-ChildItem $picpath |?{$_.name -match ".jpg" -and $_.name -match "$action" }).FullName
$picfile=[string]::join("`n",$picfiles)


$results="check screenshots"
$index=$picfile
}

else{
$results="NG"
$index="No D3 installed"
}

######### write log  #######

Get-Module -name "outlog"|remove-module
$mdpath=(Get-ChildItem -path "C:\testing_AI\modules\"  -r -file |?{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

#write-host "Do $action!"
outlog $action $results $tcnumber $tcstep $index


  }

    export-modulemember -Function dell_d3_webtest