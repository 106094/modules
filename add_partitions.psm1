

function add_partitions  ([string]$para1,[string]$para2, [string]$para3,[string]$para4,[string]$para5) {

    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force;
    $wshell=New-Object -ComObject wscript.shell
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
$paracheck2=$PSBoundParameters.ContainsKey('para3')
$paracheck2=$PSBoundParameters.ContainsKey('para4')
$paracheck2=$PSBoundParameters.ContainsKey('para5')


if($paracheck1 -eq $false -or $para1.Length -eq 0){

 $fromdiskid=((Get-Disk)|?{$_.BootFromDisk -eq $true}).Number

 $para1 = ((Get-partition)|?{$_.DiskId -eq ((Get-Disk)|?{$_.BootFromDisk -eq $true}).path}|?{$_.type -eq "Basic"}).DriveLetter
}
else{
$fromdiskid=((get-disk)|?{$_.path -eq (((Get-partition)|?{$_.DriveLetter -eq $para1}).DiskId)}).Number
}

if($paracheck2 -eq $false -or $para2.Length -eq 0){
 $para2="FAT32"
}
if($paracheck3 -eq $false -or $para3.Length -eq 0){
$para3="Z"
}
if($paracheck4 -eq $false -or $para4.Length -eq 0){
$para4=[uint64]1GB
}
if($paracheck5 -eq $false -or $para5.Length -eq 0){
$para5="NewData"
}


$fromdisklt=$para1
$formattype=$para2
$dletter=$para3
$size=($para4 / 1GB) * 1GB
$label=$para5


if($PSScriptRoot.length -eq 0){
$scriptRoot="C:\testing_AI\modules\"
}
else{
$scriptRoot=$PSScriptRoot
}


$actionss="screenshot"
Get-Module -name $actionss|remove-module
$mdpath=(gci -path $scriptRoot -r -file |?{$_.name -match "^$actionss\b" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global


$action="add new partition_disk-$($dletter)_format-$($formattype)_ size-$($para4)_label_$($label)"

$tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
$tcnumber=((get-content $tcpath).split(","))[0]
$tcstep=((get-content $tcpath).split(","))[1]

$picpath=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\"
if(-not(test-path $picpath)){new-item -ItemType directory -path $picpath |out-null}


  if( -not ((Get-Partition|?{$_.DriveLetter -eq $dletter}).DriveLetter -eq $dletter )){

#1. Get-Disk
   # Get-Disk
#2. Choose a Disk and Clear Data Using Clear-Disk
   # clear-disk -number x -removedata
#3. Create a New Partition, Format the Volume, and Add a Drive Letter 
   # new-partition -disknumber X -usemaximumsize | format-volume -filesystem NTFS -newfilesystemlabel newdrive
   # get-partition -disknumber X | set-partition -newdriveletter X
  
# Creating Multiple Partitions or Partitions of Different Sizes
 # new-partition -disknumberX -size XXgb - driveletter X | format-volume -filesystem NTFS -new filesystemlabel newdrive1
 # new-partition -disknumberX -size $MaxSize - driveletter Y | format-volume -filesystem NTFS -new filesystemlabel newdrive2
  # New-Partition -DiskNumber 0 -Size 100GB -MbrType IFS -IsActive -DriveLetter Z
   # Get-Disk | Where-Object PartitionStyle -Eq "RAW" | Initialize-Disk -PassThru | New-Partition -AssignDriveLetter -UseMaximumSize | Format-Volume
   
  $resizeC= (Get-Volume -Drive $fromdisklt).Size - $size
  
     #$sysd=((Get-Disk)|?{$_.BootFromDisk -eq $true}).Number


    get-partition -DriveLetter $fromdisklt| resize-partition -size $resizeC
   
    new-partition -disknumber $fromdiskid -Size $size  -driveletter $dletter  | format-volume -FileSystem $formattype -newfilesystemlabel $label -Full -Confirm:$false -Force
 
     start-sleep -s 10 

       [Microsoft.VisualBasic.interaction]::AppActivate("Microsoft")|out-null
       start-sleep -s 3
       $wshell.SendKeys("{tab}")
        start-sleep -s 3
        $wshell.SendKeys("~")

        
       [Microsoft.VisualBasic.interaction]::AppActivate("Location")|out-null
      start-sleep -s 2
     $shell = New-Object -ComObject Shell.Application
      foreach ($window in $shell.windows()){$window.quit()}
       start-sleep -s 2
        $wshell.SendKeys("~")
      
      start-sleep -s 3

    
 start-process explorer file:\\ -WindowStyle Maximized

       start-sleep -s 5
       
## screenshot###

&$actionss  -para3 nonlog　-para5 "check1"
   
$picfile1=(gci $picpath |?{$_.name -match ".jpg" -and $_.name -match "check1" }).FullName

     $shell = New-Object -ComObject Shell.Application
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
 
 
&$actionss  -para3 nonlog　-para5 "diskmgmt"
   
$picfile2=(gci $picpath |?{$_.name -match ".jpg" -and $_.name -match "diskmgmt" }).FullName
     
 start-sleep -s 2

       [Microsoft.VisualBasic.interaction]::AppActivate("Disk Management")|out-null
        start-sleep -s 2
        $wshell.SendKeys("% ")
        start-sleep -s 2
        $wshell.SendKeys("c")

         start-sleep -s 2

####
    $index="check screenshots"

     if( (Get-Partition|?{$_.DriveLetter -eq $dletter}).DriveLetter -eq $dletter){
      $results= "OK"
       }
      else{
      $results= "NG"
      }
      }

else{
 $results= "NG"
 $index= "disk $dletter already exists"
}

######### write log #######


if($PSScriptRoot.length -eq 0){
$scriptRoot="C:\testing_AI\modules"
}
else{
$scriptRoot=$PSScriptRoot
}

$action="add partitions"

Get-Module -name "outlog"|remove-module
$mdpath=(gci -path "C:\testing_AI\modules\"  -r -file |?{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

#write-host "Do $action!"
outlog $action $results $tcnumber $tcstep $index


  }

    export-modulemember -Function add_partitions