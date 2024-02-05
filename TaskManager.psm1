
Function TaskManager([int]$para1,[int]$para2,[string]$para3){
    #Processes
    #Performance
    #App history
    #Startup apps
    #Users
    #Details
    #Services
    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force;
    #$wshell=New-Object -ComObject wscript.shell
    #$shell=New-Object -ComObject shell.application
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
    
    


    $paracheck1=$PSBoundParameters.ContainsKey('para1')
    $paracheck2=$PSBoundParameters.ContainsKey('para2')

    if($paracheck1 -eq $false -or $para1 -eq 0){
        $para1= 0
    }
    if($paracheck2 -eq $false -or $para2 -eq 0){
        $para2= 0
    }
    
    $tablist = @{
        0 = "Processes"
        1 = "Performance"
        2 = "App history"
        3 = "Startup apps"
        4 = "Users"
        5 = "Details"
        6 = "Services"
    }

    $Performancelist = @{
        0 = "CPU"
        1 = "Memory"
        2 = "Disk"
        3 = "Ethernet"
        4 = "GPU"
    }

    $selectTab = $tablist[$para1]
    $selectTabPer = $Performancelist[$para2]
    $nonlog_flag=$para3
  
    Add-Type -AssemblyName System.Windows.Forms
    

    if($PSScriptRoot.length -eq 0){
        $scriptRoot="C:\testing_AI\modules\"
    }else{
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
    $actionss ="screenshot"
    Get-Module -name $actionss|remove-module
    $mdpath=(Get-ChildItem -path $scriptRoot -r -file |Where-object{$_.name -match "^$actionss\b" -and $_.name -match "psm1"}).fullname
    Import-Module $mdpath -WarningAction SilentlyContinue -Global


    Start-Process Taskmgr

    Start-Sleep -Seconds 10
    Get-Process -id (get-process -name "*Taskmgr*").Id | Set-WindowState -State MAXIMIZE
    #$taskid = Get-Process -id (get-process -name "*Taskmgr*").Id

    &$actionss  -para3 nonlog -para5 "OpenTaskManager"

    [Clicker]::LeftClickAtPoint(100, 10)  ## click

    if((Get-WmiObject -Class Win32_OperatingSystem).Caption -match "Windows 10"){        
        Start-Sleep -Seconds 10
        [System.Windows.Forms.SendKeys]::SendWait("{TAB 3}")
        Start-Sleep -Seconds 10
        [System.Windows.Forms.SendKeys]::SendWait("{Right $para1}")
        Start-Sleep -Seconds 10

        if($para1 -eq 1){
            [System.Windows.Forms.SendKeys]::SendWait("{TAB}")
            Start-Sleep -Seconds 10
            [System.Windows.Forms.SendKeys]::SendWait(" ")

            Start-Sleep -Seconds 10
            [System.Windows.Forms.SendKeys]::SendWait("{down $para2}")
            Start-Sleep -Seconds 10
            [System.Windows.Forms.SendKeys]::SendWait(" ")
       }
    }else{
        
       # [System.Windows.Forms.SendKeys]::SendWait("^+{ESC}")
        Start-Sleep -s 10
        [System.Windows.Forms.SendKeys]::SendWait("{tab}")
        Start-Sleep -s 10
        [System.Windows.Forms.SendKeys]::SendWait("{down}")
        [System.Windows.Forms.SendKeys]::SendWait("{down $para1}")
        Start-Sleep -s 10
        [System.Windows.Forms.SendKeys]::SendWait("~")

        if($para1 -eq 1){
            Start-Sleep -s 5
            [System.Windows.Forms.SendKeys]::SendWait("^c")
            $clipb = Get-Clipboard

            while(!($clipb -match "CPU")){         
                [System.Windows.Forms.SendKeys]::SendWait("{UP}")
                Start-Sleep -s 5
                [System.Windows.Forms.SendKeys]::SendWait("{ENTER}")
                Start-Sleep -s 5
                [System.Windows.Forms.SendKeys]::SendWait("^c")
                Start-Sleep -s 5
                $clipb = Get-Clipboard
            }
            
            Start-Sleep -s 10
            [System.Windows.Forms.SendKeys]::SendWait("{down $para2}")
            Start-Sleep -s 10
            [System.Windows.Forms.SendKeys]::SendWait("{ENTER}")
        }
    }
    
    
    
    if($selectTabPer){
        ##screenshot##
        &$actionss  -para3 nonlog -para5 $selectTab_$selectTabPer
    }else{
        ##screenshot##
        &$actionss  -para3 nonlog -para5 $selectTab
    }



    Stop-Process -Name "*taskmgr*"

    ### save logs ##  
    $action = "TaskManager-Tabselect"
    $results = "-"
    $index = $selectTab

    if($nonlog_flag.Length -eq 0){
        Get-Module -name "outlog"|remove-module
        $mdpath=(Get-ChildItem -path "C:\testing_AI\modules\"  -r -file |Where-object{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
        Import-Module $mdpath -WarningAction SilentlyContinue -Global

        #write-host "Do $action!"
        outlog $action $results  $tcnumber $tcstep $index
    }
}


# 匯出模絁E�E�E�E�E�E�E�E�E員
Export-ModuleMember -Function TaskManager