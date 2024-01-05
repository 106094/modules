function hibernaten ([int]$para1, [int]$para2, [int]$para3, [string]$para4){

$paracheck1=$PSBoundParameters.ContainsKey('para1')
$paracheck2=$PSBoundParameters.ContainsKey('para2')
$paracheck3=$PSBoundParameters.ContainsKey('para3')
$paracheck4=$PSBoundParameters.ContainsKey('para4')

    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force;
    $wshell=New-Object -ComObject wscript.shell
      Add-Type -AssemblyName Microsoft.VisualBasic
       Add-Type -AssemblyName System.Windows.Forms
        Add-Type -AssemblyName System.Windows.Forms,System.Drawing
                
        #$width  = (([string]::Join("`n", (wmic path Win32_VideoController get CurrentHorizontalResolution))).split("`n") -match "\d{1,}")[0]
        #$height  = (([string]::Join("`n", (wmic path Win32_VideoController get CurrentVerticalResolution))).split("`n") -match "\d{1,}")[0]

#region import functions

### cmd and windows termial settings for windows 11 ###

 $Version = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\'
if($Version.CurrentBuildNumber -ge 22000){
## wt json file ##

$wtsettings=get-content "$env:USERPROFILE\AppData\Local\Packages\Microsoft.WindowsTerminal*\localState\settings.json"

function ConvertTo-Hashtable {
    [CmdletBinding()]
    [OutputType('hashtable')]
    param (
        [Parameter(ValueFromPipeline)]
        $InputObject
    )

    process {
        ## Return null if the input is null. This can happen when calling the function
        ## recursively and a property is null
        if ($null -eq $InputObject) {
            return $null
        }

        ## Check if the input is an array or collection. If so, we also need to convert
        ## those types into hash tables as well. This function will convert all child
        ## objects into hash tables (if applicable)
        if ($InputObject -is [System.Collections.IEnumerable] -and $InputObject -isnot [string]) {
            $collection = @(
                foreach ($object in $InputObject) {
                    ConvertTo-Hashtable -InputObject $object
                }
            )

            ## Return the array but don't enumerate it because the object may be pretty complex
            Write-Output -NoEnumerate $collection
        } elseif ($InputObject -is [psobject]) { ## If the object has properties that need enumeration
            ## Convert it to its own hash table and return it
            $hash = @{}
            foreach ($property in $InputObject.PSObject.Properties) {
                $hash[$property.Name] = ConvertTo-Hashtable -InputObject $property.Value
            }
            $hash
        } else {
            ## If the object isn't an array, collection, or other object, it's already a hash table
            ## So just return it.
            $InputObject
        }
    }
}

$wshash=$wtsettings | ConvertFrom-Json | ConvertTo-HashTable
$guidcmd=($wshash.profiles.list|Where-object{$_.name -match "command"}).guid

$wtsettings|%{

if($_ -match "defaultProfile"){
$_= """defaultProfile"": ""$guidcmd"","
}
$_

}|set-content "$env:USERPROFILE\AppData\Local\Packages\Microsoft.WindowsTerminal*\localState\settings.json"

###�@default app settings
## https://support.microsoft.com/en-us/windows/command-prompt-and-windows-powershell-for-windows-11-6453ce98-da91-476f-8651-5c14d5777c20

$RegPath = 'HKCU:\Console\%%Startup'
if(!(test-path $RegPath)){New-Item -Path $RegPath}
$RegKey = 'DelegationConsole'
$RegValue = '{B23D10C0-E52E-411E-9D5B-C09FDF709C7D}'
set-ItemProperty -Path $RegPath -Name $RegKey -Value $RegValue -Force | Out-Null

$RegKey2 = 'DelegationTerminal'
$RegValue2 = '{B23D10C0-E52E-411E-9D5B-C09FDF709C7D}'
set-ItemProperty -Path $RegPath -Name $RegKey2 -Value $RegValue2 -Force | Out-Null
}

Add-Type @"
using System;
using System.Runtime.InteropServices;
public class Window {
    [DllImport("user32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect);
}
public struct RECT
{
    public int Left;
    public int Top;
    public int Right;
    public int Bottom;
}
"@

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

Function Set-Window {
    <#
        .SYNOPSIS
            Sets the window size (height,width) and coordinates (x,y) of
            a process window.

        .DESCRIPTION
            Sets the window size (height,width) and coordinates (x,y) of
            a process window.

        .PARAMETER ProcessName
            Name of the process to determine the window characteristics

        .PARAMETER X
            Set the position of the window in pixels from the top.

        .PARAMETER Y
            Set the position of the window in pixels from the left.

        .PARAMETER Width
            Set the width of the window.

        .PARAMETER Height
            Set the height of the window.

        .PARAMETER Passthru
            Display the output object of the window.

        .NOTES
            Name: Set-Window
            Author: Boe Prox
            Version History
                1.0//Boe Prox - 11/24/2015
                    - Initial build
                1.1//JosefZ (https://superuser.com/users/376602/josefz) - 19.05.2018
                    - treats more process instances of supplied process name properly

        .OUTPUT
            System.Automation.WindowInfo

        .EXAMPLE
            Get-Process powershell | Set-Window -X 2040 -Y 142 -Passthru

            ProcessName Size     TopLeft  BottomRight
            ----------- ----     -------  -----------
            powershell  1262,642 2040,142 3302,784   

            Description
            -----------
            Set the coordinates on the window for the process PowerShell.exe
        
    #>
    [OutputType('System.Automation.WindowInfo')]
    [cmdletbinding()]
    Param (
        [parameter(ValueFromPipelineByPropertyName=$True)]
        $ProcessName,
        [int]$X,
        [int]$Y,
        [int]$Width,
        [int]$Height,
        [switch]$Passthru
    )
    Begin {
        Try{
            [void][Window]
        } Catch {
        Add-Type @"
              using System;
              using System.Runtime.InteropServices;
              public class Window {
                [DllImport("user32.dll")]
                [return: MarshalAs(UnmanagedType.Bool)]
                public static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect);

                [DllImport("User32.dll")]
                public extern static bool MoveWindow(IntPtr handle, int x, int y, int width, int height, bool redraw);
              }
              public struct RECT
              {
                public int Left;        // x position of upper-left corner
                public int Top;         // y position of upper-left corner
                public int Right;       // x position of lower-right corner
                public int Bottom;      // y position of lower-right corner
              }
"@
        }
    }
    Process {
        $Rectangle = New-Object RECT
        $Handles = (Get-Process -Name $ProcessName).MainWindowHandle   ### 1.1//JosefZ
        foreach ( $Handle in $Handles ) {                              ### 1.1//JosefZ
            if ( $Handle -eq [System.IntPtr]::Zero ) { Continue }      ### 1.1//JosefZ
            $Return = [Window]::GetWindowRect($Handle,[ref]$Rectangle)
            If (-NOT $PSBoundParameters.ContainsKey('Width')) {            
                $Width = $Rectangle.Right - $Rectangle.Left            
            }
            If (-NOT $PSBoundParameters.ContainsKey('Height')) {
                $Height = $Rectangle.Bottom - $Rectangle.Top
            }
            If ($Return) {
                $Return = [Window]::MoveWindow($Handle, $x, $y, $Width, $Height,$True)
            }
            If ($PSBoundParameters.ContainsKey('Passthru')) {
                $Rectangle = New-Object RECT
                $Return = [Window]::GetWindowRect($Handle,[ref]$Rectangle)
                If ($Return) {
                    $Height = $Rectangle.Bottom - $Rectangle.Top
                    $Width = $Rectangle.Right - $Rectangle.Left
                    $Size = New-Object System.Management.Automation.Host.Size -ArgumentList $Width, $Height
                    $TopLeft = New-Object System.Management.Automation.Host.Coordinates -ArgumentList $Rectangle.Left, $Rectangle.Top
                    $BottomRight = New-Object System.Management.Automation.Host.Coordinates -ArgumentList $Rectangle.Right, $Rectangle.Bottom
                    If ($Rectangle.Top -lt 0 -AND $Rectangle.LEft -lt 0) {
                        Write-Warning "Window is minimized! Coordinates will not be accurate."
                    }
                    $Object = [pscustomobject]@{
                        ProcessName = $ProcessName
                        Size = $Size
                        TopLeft = $TopLeft
                        BottomRight = $BottomRight
                    }
                    $Object.PSTypeNames.insert(0,'System.Automation.WindowInfo')
                    $Object            
                }
            }
        }
    }
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

#endregion

if($paracheck1 -eq $false -or $para1 -eq 0){
$para1=[int]1
}
if($paracheck2 -eq $false -or $para2 -eq 0){
$para2=[int]90
}
if($paracheck3 -eq $false -or $para3 -eq 0){
$para3=[int]60
}
if($paracheck4 -eq $false -or $para4 -eq 0){
$para4=""
}

$countn=$para1
$delaytime=$para2
$sleeptime=$para3
$nonlog_flag=$para4

if($PSScriptRoot.length -eq 0){
$scriptRoot="C:\testing_AI\modules"
}
else{
$scriptRoot=$PSScriptRoot
}

### s4 tool prepare ##

$pl="pwrtest"

 $pwrtest1= test-path  "C:/dash/tools/pwrtest/$($pl).exe"

 if( $pwrtest1 -eq $false){
  $fpath=(Get-ChildItem -path $scriptRoot -r -file -filter "*$pl*exe").fullname

  if( (test-path "C:\dash\tools\$pl\") -eq $false){new-item -ItemType directory -Path "C:/dash/tools/$pl/" |Out-Null }
  copy-item  $fpath -Destination "C:/dash/tools/$pl/" -Force
  $pwrtest1= test-path  "C:/dash/tools/$($pl)/$($pl).exe"
  }
  
   if($pwrtest1 -eq $false){
        write-host "tool ready fail"
      } else{
      write-host "tool ready"
      }

<####

  /c:n         n indicates number of cycles (1 is default)
  /d:n         n indicates delay time (in seconds; 90 is default)
  /p:n         n indicates sleep time (in seconds; 60 is default)
               (if wake timer isnt supported for hibernate, system will restart and immediately resume after writing hiber file)
  /h:y         indicates hybrid sleep should be enabled
               (default is system policy)
  /h:n         indicates hybrid sleep should be disabled
               (default is system policy)
  /s:all       indicates cycling through all supported power states in order
  /s:rnd       indicates cycling through all supported power states randomly
  /s:1         indicates target state is always S1
  /s:3         indicates target state is always S3 (default)
  /s:4         indicates target state is always S4
  /s:hibernate indicates target state is always hibernate (S4)
  /s:standby   indicates target state is any available Standby state (S1 or S3)
  /unattend    indicates not to change system execution state after wakeup
  /e:n         n indicates timeout to wait for transition end event
               (in seconds; 120 is default)

###>

$tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
$tcnumber=((get-content $tcpath).split(","))[0]
$tcstep=((get-content $tcpath).split(","))[1]
$action="S4 x $countn"
$picpath=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\"
if(-not(test-path $picpath)){new-item -ItemType directory -path $picpath |out-null}

$actionmd ="screenshot"
Get-Module -name $actionmd|remove-module
$mdpath=(Get-ChildItem -path $scriptRoot -r -file |Where-object{$_.name -match "^$actionmd\b" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

$screen = [System.Windows.Forms.Screen]::PrimaryScreen
$bounds = $screen.Bounds
$width  = $bounds.Width
$height = $bounds.Height


$timen=get-date -Format "yyMMdd_HHmmss"
$logn="$($picpath)_$($timen)_step$($tcstep)_S4_cycle_$($countn).txt"

$logfile=(Split-Path -Parent $scriptRoot)+"\logs\logs_timemap.csv"
#$lastlogtime = (import-csv $logfile |Where-object{$_.actions -match "s4" -or $_.actions -match "hibernate"}|select -Last 1).Time
$lastlogtime = (Get-ChildItem $logfile).lastwritetime

$s4count=(Get-WinEvent -FilterHashtable @{ LogName='System'; StartTime=$lastlogtime; Id='42' } -ErrorAction SilentlyContinue).count

$checkexe=((get-process -name pwrtest -ErrorAction SilentlyContinue).Id).count

if($checkexe -eq 0){
Start-Sleep -s 20
$checkexe=((get-process -name pwrtest -ErrorAction SilentlyContinue).Id).count
}

if($checkexe -ne 0){

## running ##

exit
}

if($checkexe -eq 0){

if($s4count -lt $countn){

## test / retest 


### create shortcut of S4 ##

New-Item -path $logn -Force

<###
New-Item -ItemType SymbolicLink -Path "$env:USERPROFILE\desktop\S4.log" -Target $logn -force  -ErrorAction SilentlyContinue| out-null
###>

$path = "$env:USERPROFILE\desktop\S4.lnk"
$link = $wshell.CreateShortcut($path)
$link.TargetPath = $logn
$link.Save()

### run ##

 $id0=(Get-Process cmd).Id
set-location "C:/dash/tools/$($pl)/"
  
start-process cmd -WindowStyle Maximized
start-sleep -s 3
$id3=(Get-Process cmd).Id|Where-object{$_ -notin $id0}

[Microsoft.VisualBasic.interaction]::AppActivate($id3)|out-null
start-sleep -s 3

$countn2=$countn-$s4count

Set-Clipboard -value "pwrtest.exe /sleep /c:$countn2 /s:4 /d:$delaytime /p:$sleeptime >> $logn" 
Start-Sleep -Seconds 5

[Clicker]::LeftClickAtPoint(50, 1)
Start-Sleep -Seconds 2
$wshell.SendKeys("~") 
Start-Sleep -Seconds 2
$wshell.SendKeys("^v")
Start-Sleep -Seconds 2

&$actionmd  -para3 nonlog -para5 start

$wshell.SendKeys("~")
Start-Sleep -Seconds 5

exit
 
}

if($s4count -ge $countn){

## complete

start-sleep -s 100  ## wait enter desktop ##

$results="OK"
$index="check screenshot"

$cmdids=  (Get-Process cmd).id

foreach($cmdid in $cmdids) {
  
  Set-Clipboard -value "na" ## reset clickboard

  Start-Sleep -Seconds 2
  
  [Microsoft.VisualBasic.interaction]::AppActivate($cmdid)|out-null
  Get-Process -id $cmdid  | Set-WindowState -State MAXIMIZE
   Start-Sleep -Seconds 1
   [Clicker]::LeftClickAtPoint(1,1)
    start-sleep -s 1

    $wshell.SendKeys("E")
    start-sleep -s 1
    $wshell.SendKeys("S")
    start-sleep -s 1
    $wshell.SendKeys("~")
    start-sleep -s 1
    $contents=Get-Clipboard
    start-sleep -s 3

    if($contents -match "pwrtest" -and $contents -match "sleep"){
    
   #[Microsoft.VisualBasic.interaction]::AppActivate($lastid)|out-null
   #Start-Sleep -Seconds 1
  
  &$actionmd  -para3 nonlog -para5 end

        start-sleep -s 1
        taskkill /PID $cmdid /F 


    }
    else{   Get-Process -id $cmdid  | Set-WindowState -State MINIMIZE }

}


### hide cmd windows of terminal ###

$wtids=(get-process WindowsTerminal -ea SilentlyContinue).Id
if($wtids){
foreach($wtid in $wtids){
Get-Process -id $wtid | Set-WindowState -State Minimize
}
}

$results="ok"
$index="check $picfile"


######## record log #######

if($nonlog_flag.Length -eq 0){
    Get-Module -name "outlog"|remove-module
    $mdpath=(Get-ChildItem -path "C:\testing_AI\modules\" -r -file |Where-object{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
    Import-Module $mdpath -WarningAction SilentlyContinue -Global

    #write-host "Do $action!"
    outlog $action $results  $tcnumber $tcstep $index
}

}

}



  }

  
    export-modulemember -Function  hibernaten