
function dump_monitor([string]$para1,[string]$para2){
    
    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force;
    $wshell=New-Object -ComObject wscript.shell
      Add-Type -AssemblyName Microsoft.VisualBasic
      Add-Type -AssemblyName System.Windows.Forms
      $shell=New-Object -ComObject shell.application
      
 
 # create a new .NET type for  close  app windows
$signature = @"
[DllImport("user32.dll")]public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);
"@
Add-Type -MemberDefinition $signature -Name MyType -Namespace MyNamespace     

$paracheck1=$PSBoundParameters.ContainsKey('para1')
$paracheck2=$PSBoundParameters.ContainsKey('para2')

if($paracheck1 -eq $false -or $para1.Length -eq 0){
$para1="C:\"
}

if($paracheck2 -eq $false -or $para2.Length -eq 0){
$para2=""
}

$diskname=$para1
if($diskname[-1] -ne "\"){$diskname=$diskname=+"\"}

$dumpfile=$diskname+"Windows\MEMORY.DMP"
$dumplog=$diskname+"DumpStack.log"
$stop_flag=$para2

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

$action="dump file monitor"
$tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"

$tcnumber=((get-content $tcpath).split(","))[0]
$tcstep=((get-content $tcpath).split(","))[1]
$action=((get-content $tcpath).split(","))[2]
$timenow=get-date -format "yyMMdd_HHmmss"
$picpath=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\"
if(-not(test-path $picpath)){new-item -ItemType directory -path $picpath |out-null}

$actionmd="screenshot"
Get-Module -name $actionmd|remove-module
$mdpath=(gci -path $scriptRoot -r -file |?{$_.name -match "^$actionmd\b" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

$screen = [System.Windows.Forms.Screen]::PrimaryScreen
$bounds = $screen.Bounds
$width  = $bounds.Width
$height = $bounds.Height

### close file explore windows

  $shell.Windows() |?{$_.name -eq "File Explorer"}| ForEach-Object { $_.Quit() }

   start-sleep -s 2

### open C: ##

Start-Process explorer.exe $diskname  -WindowStyle maximized 

 start-sleep -s 5

 &$actionmd  -para3 nonlog

$checkdmp=test-path $dumpfile
if(!$checkdmp){
$results="OK"
$index="No Dump file is found"
} 
else {   
$timenow=get-date -format "yyMMdd_HHmm"
$newdumpname=$dumpfile.Replace("MEMORY","MEMORY_$($timenow)")
Move-Item $dumpfile $newdumpname -Force
Copy-Item $newdumpname $picpath -Force

if(test-path $dumplog){
$newlogname=$dumplog.Replace("DumpStack","DumpStack_$($timenow)")
Move-Item $dumplog $newlogname -Force
Copy-Item $newlogname $picpath -Force
}

$results="NG"
$index="check Dump files"

}

### close file explore windows

  $shell.Windows() |?{$_.name -eq "File Explorer"}| ForEach-Object { $_.Quit() }
  
######### write log #######

Get-Module -name "outlog"|remove-module
$mdpath=(gci -path "C:\testing_AI\modules\"  -r -file |?{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

#write-host "Do $action!"
outlog $action $results $tcnumber $tcstep $index

if($stop_flag.length -gt 0 -and $results -eq "NG"){

[System.Windows.Forms.MessageBox]::Show($this, "Dump File is found. Please check")   

exit
}


  }

    export-modulemember -Function dump_monitor