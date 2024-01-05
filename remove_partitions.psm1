

function remove_partitions  ([string]$para1,[string]$para2,[string]$para3) {

    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force;
    $wshell=New-Object -ComObject wscript.shell
      $shell = New-Object -ComObject Shell.Application
      Add-Type -AssemblyName Microsoft.VisualBasic
      Add-Type -AssemblyName System.Windows.Forms

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

$paracheck1=$PSBoundParameters.ContainsKey('para1')
$paracheck2=$PSBoundParameters.ContainsKey('para2')
$paracheck3=$PSBoundParameters.ContainsKey('para3')

if($paracheck1 -eq $false -or $para1.Length -eq 0){
$para1="Z"
}
if($paracheck2 -eq $false -or $para2.Length -eq 0){
$para2=""
}
if($paracheck3 -eq $false -or $para3.Length -eq 0){
$para3=""
}

$dletter=$para1
$mletter=$para2
$nonlog_flag=$para3

if($PSScriptRoot.length -eq 0){
$scriptRoot="C:\testing_AI\modules\"
}
else{
$scriptRoot=$PSScriptRoot
}


$action="remove-partion $dletter"

$tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
$tcnumber=((get-content $tcpath).split(","))[0]
$tcstep=((get-content $tcpath).split(","))[1]

$picpath=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\"
if(-not(test-path $picpath)){new-item -ItemType directory -path $picpath |out-null}

    $actionss ="screenshot"
    Get-Module -name $actionss|remove-module
    $mdpath=(Get-ChildItem -path $scriptRoot -r -file |?{$_.name -match "^$actionss\b" -and $_.name -match "psm1"}).fullname
    Import-Module $mdpath -WarningAction SilentlyContinue -Global

  if( ((Get-Partition|?{$_.DriveLetter -eq $dletter}).DriveLetter -eq $dletter )){

  Remove-Partition -DriveLetter $dletter -Confirm:$false    ## remove partition

if($mletter.length -gt 0){
  $size = (Get-PartitionSupportedSize -DriveLetter $mletter).SizeMax  
  Resize-Partition -DriveLetter $mletter -Size $size                    ### entent C to maximun
   start-sleep -s 5
   }

## explore ##

Start-Process explorer file:\\ -WindowStyle Maximized

##screenshot##
&$actionss  -para3 nonlog

 foreach ($window in $shell.windows()){$window.quit()}

## screenshot disk management###

diskmgmt.msc

       start-sleep -s 5

       [Microsoft.VisualBasic.interaction]::AppActivate("Disk Management")|out-null
        start-sleep -s 2
        $wshell.SendKeys("% ")
        start-sleep -s 2
        $wshell.SendKeys("x")

         start-sleep -s 2
      

##screenshot##
&$actionss  -para3 nonlog -para5 diskmgmt

       [Microsoft.VisualBasic.interaction]::AppActivate("Disk Management")|out-null
        start-sleep -s 2
        $wshell.SendKeys("% ")
        start-sleep -s 2
        $wshell.SendKeys("c")

         start-sleep -s 2
         

     if( (Get-Partition|?{$_.DriveLetter -eq $dletter}).DriveLetter -eq $dletter){
      $results= "NG"
         }
      else{
      $results= "OK"
         }
   
 $index="check screenshot"
      }

else{

  $results= "NG"
 $index="No $dletter is found"
       
       }
######### write log #######

if($nonlog_flag.Length -eq 0){
Get-Module -name "outlog"|remove-module
$mdpath=(Get-ChildItem -path "C:\testing_AI\modules\"  -r -file |?{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

#write-host "Do $action!"
outlog $action $results $tcnumber $tcstep $index
}

  }

    export-modulemember -Function remove_partitions