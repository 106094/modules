
Function TaskManager([int]$para1,[int]$para2,[string]$para3){
    #Processes
    #Performance
    #App history
    #Startup apps
    #Users
    #Details
    #Services

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


    Start-Process Taskmgr

    Start-Sleep -Seconds 10



    Get-Process -id (get-process -name "*Taskmgr*").Id | Set-WindowState -State MAXIMIZE
    #$taskid = Get-Process -id (get-process -name "*Taskmgr*").Id


    if((Get-WmiObject -Class Win32_OperatingSystem).Caption -match "Windows 10"){        
        Start-Sleep -Seconds 10
        [System.Windows.Forms.SendKeys]::SendWait("{TAB 3}")
        Start-Sleep -Seconds 10
        [System.Windows.Forms.SendKeys]::SendWait("{Right $para1}")
        Start-Sleep -Seconds 10
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
    
    
    $actionss ="screenshot"
    Get-Module -name $actionss|remove-module
    $mdpath=(Get-ChildItem -path $scriptRoot -r -file |Where-object{$_.name -match "^$actionss\b" -and $_.name -match "psm1"}).fullname
    Import-Module $mdpath -WarningAction SilentlyContinue -Global

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