Function Set_Window ([string]$para1,[string]$para2,[string]$para3,[string]$para4){

Add-Type -AssemblyName System.Windows.Forms



$paracheck1=$PSBoundParameters.ContainsKey('para1')

if($paracheck1 -eq $false -or $para1.Length -eq 0){
    $para1="paint"
}

$ProcessName = "*$para1*"

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


#---get window current size

Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public class SetWindowHelper {
    [DllImport("user32.dll")]
    public static extern bool GetWindowRect(IntPtr hWnd, out myRECT myrect);
}

public struct myRECT {
    public int Left;
    public int Top;
    public int Right;
    public int Bottom;
}
"@

$windowHandle = (Get-Process -Name $ProcessName).MainWindowHandle

$myrect = New-Object myRECT
[SetWindowHelper]::GetWindowRect($windowHandle, [ref]$myrect)

$appwindowWidth = $myrect.Right - $myrect.Left
$appwindowHeight = $myrect.Bottom - $myrect.Top

#Write-Output "Window Width: $windowWidth"
#Write-Output "Window Height: $windowHeight"

Add-Type @"
using System;
using System.Runtime.InteropServices;
public class PInvoke {
    [DllImport("user32.dll")] public static extern IntPtr GetDC(IntPtr hwnd);
    [DllImport("gdi32.dll")] public static extern int GetDeviceCaps(IntPtr hdc, int nIndex);
}
"@
$hdc = [PInvoke]::GetDC([IntPtr]::Zero)
$curwidth = [PInvoke]::GetDeviceCaps($hdc, 118) # width
$curheight = [PInvoke]::GetDeviceCaps($hdc, 117) # height

$screen = [System.Windows.Forms.Screen]::PrimaryScreen
$bounds = $screen.Bounds

$currentDPI = (Get-ItemProperty -Path "HKCU:\Control Panel\Desktop\WindowMetrics" -Name AppliedDPI).AppliedDPI

$dpisets=@(96,120,144,168)
$sclsets=@(100,125,150,175)

$index = $dpisets.IndexOf($currentDPI)
$calcu = $sclsets[$index] /100

$bounds.Width = $curwidth * $calcu
$bounds.Height = $curheight * $calcu

$windowwidth=$bounds.Width
$windowheight=$bounds.Height

#-------------------------------------------------------------------------------

#---full screen size
    Add-Type @"
using System;
using System.Runtime.InteropServices;
public class PInvoke {
    [DllImport("user32.dll")] public static extern IntPtr GetDC(IntPtr hwnd);
    [DllImport("gdi32.dll")] public static extern int GetDeviceCaps(IntPtr hdc, int nIndex);
}
"@
$hdc = [PInvoke]::GetDC([IntPtr]::Zero)
$curwidth = [PInvoke]::GetDeviceCaps($hdc, 118) # width
$curheight = [PInvoke]::GetDeviceCaps($hdc, 117) # height
#-------------------------------------------------------------------------------

#https://stackoverflow.com/questions/59953946/powershell-calculate-pixel-height-of-start-bar
#---taskbar size

function Get-TaskBarDimensions {
    param (
        [System.Windows.Forms.Screen]$Screen = [System.Windows.Forms.Screen]::PrimaryScreen
    )        

    $device = ($Screen.DeviceName -split '\\')[-1]
    if ($Screen.Primary) { $device += ' (Primary Screen)' }

    if ($Screen.Bounds.Equals($Screen.WorkingArea)) {
        Write-Warning "Taskbar is hidden on device $device or moved to another screen."
        return
    }


    # calculate heights and widths for the possible positions (left, top, right and bottom)
    $ScreenRect  = $Screen.Bounds
    $workingArea = $Screen.WorkingArea
    $left        = [Math]::Abs([Math]::Abs($ScreenRect.Left) - [Math]::Abs($WorkingArea.Left))
    $top         = [Math]::Abs([Math]::Abs($ScreenRect.Top) - [Math]::Abs($workingArea.Top))
    $right       = ($ScreenRect.Width - $left) - $workingArea.Width
    $bottom      = ($ScreenRect.Height - $top) - $workingArea.Height

    if ($bottom -gt 0) {
        # TaskBar is docked to the bottom
        return [PsCustomObject]@{
            X        = $workingArea.Left
            Y        = $workingArea.Bottom
            Width    = $workingArea.Width
            Height   = $bottom
            Position = 'Bottom'
            Device   = $device
        }
    }
    if ($left -gt 0) {
        # TaskBar is docked to the left
        return [PsCustomObject]@{
            X        = $ScreenRect.Left
            Y        = $ScreenRect.Top
            Width    = $left
            Height   = $ScreenRect.Height
            Position = 'Left'
            Device   = $device
        }
    }
    if ($top -gt 0) {
        # TaskBar is docked to the top
        return [PsCustomObject]@{
            X        = $workingArea.Left
            Y        = $ScreenRect.Top
            Width    = $workingArea.Width
            Height   = $top
            Position = 'Top'
            Device   = $device
        }
    }
    if ($right -gt 0) {
        # TaskBar is docked to the right
        return [PsCustomObject]@{
            X        = $workingArea.Right
            Y        = $ScreenRect.Top
            Width    = $right
            Height   = $ScreenRect.Height
            Position = 'Right'
            Device   = $device
        }
    }
}

$tbsize = Get-TaskBarDimensions

#-------------------------------------------------------------------------------


    #$ProcessName = $para1
    #$point = $para2
    #$X = $point.Split(",")[0]
    #$Y = $point.Split(",")[1]
    #$Width = $para3
    #$Height = $para4
    #$Passthru = $para5

    #$ProcessName = "*paint*"
    #$Width = $curwidth
    #$Height = $curheight - $tbsize.Height
    #$X = 0
    #$Y = 0





    
    $paracheck2=$PSBoundParameters.ContainsKey('para2')
    $paracheck3=$PSBoundParameters.ContainsKey('para3')
    $paracheck4=$PSBoundParameters.ContainsKey('para4')

    
    if($paracheck2 -eq $false -or $para2 -eq 0){
        #$para2= $curwidth
        $para2 = $windowwidth.ToString() + "," + $windowHeight.ToString()
    }
    if($paracheck3 -eq $false -or $para3 -eq 0){
        #$para3= $curheight - $tbsize.Height
        $para3 = "0,0"
    }

    $Width = ($para2 -split(","))[0]
    $Height = ($para2 -split(","))[1]
    $X = ($para3 -split(","))[0]
    $Y = ($para3 -split(","))[1]
    $nonlog_flag = $para4

    if($PSScriptRoot.length -eq 0){
        $scriptRoot="C:\testing_AI\modules"
    }else{
        $scriptRoot=$PSScriptRoot
    }



    Try {
        [void][Window2]
    } Catch {
        Add-Type -TypeDefinition @"
          using System;
          using System.Runtime.InteropServices;
          public class Window2 {
            [DllImport("user32.dll")]
            [return: MarshalAs(UnmanagedType.Bool)]
            public static extern bool GetWindowRect(IntPtr hWnd, out RECT2 lpRect);

            [DllImport("User32.dll")]
            public extern static bool MoveWindow(IntPtr handle, int x, int y, int width, int height, bool redraw);
          }
          public struct RECT2
          {
            public int Left;        // x position of upper-left corner
            public int Top;         // y position of upper-left corner
            public int Right;       // x position of lower-right corner
            public int Bottom;      // y position of lower-right corner
          }
"@
    }
    
    
    $Rectangle2 = New-Object RECT2
    $Handles = (Get-Process -Name $ProcessName).MainWindowHandle   ### 1.1//JosefZ
    foreach ($Handle in $Handles) {                              ### 1.1//JosefZ
        if ($Handle -eq [System.IntPtr]::Zero) { Continue }      ### 1.1//JosefZ
        $Return = [Window2]::GetWindowRect($Handle, [ref]$Rectangle2)
        
        
        if ($Return) {
            $Return = [Window2]::MoveWindow($Handle, $X, $Y, $Width, $Height, $True)
        }
        if ($Passthru) {
            $Rectangle2 = New-Object RECT2
            $Return = [Window2]::GetWindowRect($Handle, [ref]$Rectangle2)
            if ($Return) {
                $Height = $Rectangle2.Bottom - $Rectangle2.Top
                $Width = $Rectangle2.Right - $Rectangle2.Left
                $Size = New-Object System.Management.Automation.Host.Size -ArgumentList $Width, $Height
                $TopLeft = New-Object System.Management.Automation.Host.Coordinates -ArgumentList $Rectangle2.Left, $Rectangle2.Top
                $BottomRight = New-Object System.Management.Automation.Host.Coordinates -ArgumentList $Rectangle2.Right, $Rectangle2.Bottom
                if ($Rectangle2.Top -lt 0 -and $Rectangle2.Left -lt 0) {
                    Write-Warning "Window is minimized! Coordinates will not be accurate."
                }
                $Object = [pscustomobject]@{
                    ProcessName = $ProcessName
                    Size = $Size
                    TopLeft = $TopLeft
                    BottomRight = $BottomRight
                }
                $Object.PSTypeNames.insert(0, 'System.Automation.WindowInfo')
                $Object
            }
        }
    }

    ### write to log ###
    $action="Set_Window"

    if((Get-Process -Name $ProcessName)){
        $results="OK"
    }else{
        $results="NG"
    }
    
    $index="pointX :$X & ponitY :$Y & Width :$Width & Height :$Height"

    $tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
    $tcnumber=((get-content $tcpath).split(","))[0]
    $tcstep=((get-content $tcpath).split(","))[1]
    
    if($nonlog_flag.Length -eq 0){
        Get-Module -name "outlog"|remove-module
        $mdpath=(gci -path "C:\testing_AI\modules\" -r -file |?{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
        Import-Module $mdpath -WarningAction SilentlyContinue -Global

        #write-host "Do $action!"
        outlog $action $results  $tcnumber $tcstep $index
    }
    
}

 


Export-ModuleMember -Function Set_Window





