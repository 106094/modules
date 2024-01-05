
function initial([string]$para1,[string]$para2,[string]$para3){

###########  Check Time/Revise setting input  -> move to dellgui
###########  Check IDRAC IP/username/passwd -> move to dellgui
###########  Check Time/BIOS/OS/CPU/Memory/disk
###########  Get Eventlog/Clear Eventlog
###########  Check Yellow Bang
###########  Check if need setup memory integrity -> move to autostart
###########  save Device/SW versions
###########  set auto logon 
###########  DM screentshot
###########  Winver screentshot
###########  Windows Update screentshot -> ossettings_check
###########  Coreisolation -> ossettings_check
###########  copy powersettings to ini folder
###########  turn off notification

    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force;
    $wshell=New-Object -ComObject wscript.shell
      Add-Type -AssemblyName Microsoft.VisualBasic
      Add-Type -AssemblyName System.Windows.Forms

$paracheck=$PSBoundParameters.ContainsKey('para1')
$paracheck2=$PSBoundParameters.ContainsKey('para2')
$paracheck3=$PSBoundParameters.ContainsKey('para3')

if( $paracheck -eq $false -or $para1.length -eq 0 ){
#write-host "no defined, setting 1 min after login"
$para1=""
}

if( $paracheck2 -eq $false -or $para2.length -eq 0 ){
#write-host "no defined, setting 1 min after login"
$para2=""
}

if( $paracheck3 -eq $false -or $para3.length -eq 0 ){
#write-host "no defined, setting 1 min after login"
$para3=""
}

$nondia_flag=$para1
$nonlog_flag=$para2
$noncapt_flag=$para3
  
  ## delete autostart @ desktop


 # create a new .NET type for  close  app windows
$signature = @"
[DllImport("user32.dll")]public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);
"@
Add-Type -MemberDefinition $signature -Name MyType -Namespace MyNamespace
 
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
   
function outwords{

param(
    [string]$line,
    [int]$timeset
    
    )
    
$i=0
do{
write-host $line[$i]  -NoNewline
$i++
start-sleep -millisecond $timeset
}until($i -eq $line.length)

write-host ""

}

function ShowWindow( $hwnd ){

    $constants = @{
        ShowWindowCommands = @{ #from https://pinvoke.net/default.aspx/Enums/ShowWindowCommands.html
            Hide = 0; #completely hides the window
            Normal = 1; #if min/max'd, restores to original size and position
            ShowMinimized = 2; #activates and minimizes window
            Maximize = 3; #activates and maximizes window
            ShowMaximized = 3; #activates and maximizes window
            ShowNoActivate = 4; #shows a window in its most recent size and position without activating it
            Show = 5; #activates the window and displays it in its current size and position
            Minimize = 6; #minimizes and activates the next top-level window
            ShowMinNoActive = 7; #minimizes and activates no windows"
            ShowNA = 8; #shows a window in its current size and position without activating it
            Restore = 9; #activates and displays window. if min/max'd, restores to original size and position
            ShowDefault = 10; #sets the window to its default show state
            ForceMinimize = 11; #Windows 2000/XP-only feature. minimize window even if thread is hung
        };
        WindowLongParam = { #from https://www.pinvoke.net/default.aspx/Constants/GWL%20-%20GetWindowLong.html
            SetWndProc = -4; #sets new address for procedure (can't be changed unless the window belongs to the same thread)
            SetHndInst = -6; #sets a new application instance handle
            SetHndParent = -8 #unsepecified
            SetId = -12 #sets a new identifier of the child window
            SetStyle = -16 #sets a new window style
            SetExtStyle = -20 #sets a new extended window style
            SetUserData = -21 #sets the user data associated with the window
            #there's a few more of these that are positive for the dialog box procedure
        };
        WindowsStyles = {
            #see https://learn.microsoft.com/en-us/windows/win32/winmsg/window-styles
            # and
            #  http://pinvoke.net/default.aspx/Constants.Window%20styles
            # for more... (there's a lot)
            Minimize = 0x20000000; #hexadecimal of 536870912
        }
    }

    $sigs = '[DllImport("user32.dll", EntryPoint="GetWindowLong")]
    public static extern IntPtr GetWindowLong(IntPtr hWnd, int nIndex);
    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
    [DllImport("User32.dll")]
    public static extern int GetWindowThreadProcessId(IntPtr hWnd, int lpdwProcessId);
    [DllImport("user32.dll")]
    public static extern bool AttachThreadInput(uint idAttach, uint idAttachTo, bool fAttach);
    [DllImport("user32.dll", SetLastError=true)]
    public static extern bool BringWindowToTop(IntPtr hWnd);
    [DllImport("user32.dll")]
    public static extern IntPtr GetForegroundWindow();'

    $type = Add-Type -MemberDefinition $sigs -Name WindowAPI5 -IgnoreWarnings -PassThru
    
    $type::ShowWindow( $hwnd, $constants.ShowWindowCommands.Minimize )
    $type::ShowWindow( $hwnd, $constants.ShowWindowCommands.Restore )

    [int] $currentlyFocusedWindowProcessId = $type::GetWindowThreadProcessId($type::GetForegroundWindow(), 0)
    [int] $appThread = [System.AppDomain]::GetCurrentThreadId()

    if( $currentlyFocusedWindowProcessId -ne $appThread ){
    
        $type::AttachThreadInput( $currentlyFocusedWindowProcessId, $appThread, $true )
        $type::BringWindowToTop( $hwnd )
        $type::ShowWindow( $hwnd, $constants.ShowWindowCommands.Show )
        $type::AttachThreadInput( $currentlyFocusedWindowProcessId, $appThread, $false )

    } else {
        $type::BringWindowToTop( $hwnd )
        $type::ShowWindow( $hwnd, $constants.ShowWindowCommands.Show )
    }

}


## edge disable the "Microsoft Edge closed unexpectedly" pop-up message

#https://www.technipages.com/how-to-disable-restore-pages-prompt-in-microsoft-edge

reg add “HKLM\Software\Policies\Microsoft\Edge” /v “HideRestoreDialogEnabled” /t REG_DWORD /d “1” /f


######  basic check folders ######

if($PSScriptRoot.length -eq 0){
$scriptRoot="C:\testing_AI\modules\"
}
else{
$scriptRoot=$PSScriptRoot
}

$dd=get-date -format "yyMMdd_HHmmss"
$action="Initialization"
$tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
$tcnumber=((get-content $tcpath).split(","))[0]
$tcstep=((get-content $tcpath).split(","))[1]

$daver_path=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)"
if(-not(test-path $daver_path)){new-item -ItemType directory $daver_path |Out-Null }

$index=$daver_path

$actionmd ="screenshot"
Get-Module -name $actionmd|remove-module
$mdpath=(get-childitem -path $scriptRoot -r -file |where-object{$_.name -match "^$actionmd\b" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

#$screen = [System.Windows.Forms.Screen]::PrimaryScreen
#$bounds = $screen.Bounds
#$width  = $bounds.Width
#$height = $bounds.Height

Add-Type -AssemblyName System.Windows.Forms,System.Drawing

#$width  = ([string]::Join("`n", (wmic path Win32_VideoController get CurrentHorizontalResolution))).split("`n") -match "\d{1,}"
#$height  = ([string]::Join("`n", (wmic path Win32_VideoController get CurrentVerticalResolution))).split("`n") -match "\d{1,}"


###########  Check Time/Revise ########
 
  if($nondia_flag.length -eq 0){       
### bring cmd　window to the front 

$hwnd=(get-process cmd).MainWindowHandle

ShowWindow( $hwnd ) |Out-Null

  $id="Taipei"

  $time1=get-date -Format "yy/MM/dd HH:mm"
  
  $desid=(Get-TimeZone *).id -match $id

   $timezone=(Get-TimeZone -ListAvailable|where-object{$_.id -match "$id" }).id
    Set-TimeZone -id $timezone |Out-Null
 
    $line2 ="Good day! Let's Setup up the sytem time first."
& outwords $line2 50

Write-Host ""


 ### read time setting input


 do{

   $yr=(get-date).Year

   $yset= read-host "Input the year (example:$yr) or Enter if same as current setting"
   if($yset.length -eq 0){$yset=$yr}

   $mset= read-host "Input the Month (1~12) or Enter if same as current setting"   
   if($mset.length -eq 0){$mset=(get-date).Month}

   $dset= read-host "Input the day (1~31) or Enter if same as current setting"
   if($dset.length -eq 0){$dset=(get-date).Day}

   $hset= read-host "Input Hour (0~24) or Enter if same as current setting"
   if($hset.length -eq 0){$hset=(get-date).Hour}
   $minset= read-host "Input Minute (0~60) or Enter if same as current setting"
   if($minset.length -eq 0){$minset= (get-date).Minute }
   
   $settime=[DateTime]"$($yset)-$($mset)-$($dset) $($hset):$($minset)"
   $timez=(Get-TimeZone).id
   
  
   $ans=read-host "$($settime) ($($timez)) - Is the setting time correct? (Enter:yes,N:no)"
   
   }until (-not ($ans -match "n"))
 

    Set-Date -Date  $settime |Out-Null
    
 $line2 ="Time setting is OK."
& outwords $line2 20
Write-Host ""
  }


  
###########  Check Time/BIOS/OS/CPU/Memory/disk ########
 
 $systeminfolog="$daver_path\$($dd)_step$($tcstep)_SystemInfo.txt"
 $inisys=0
 do{

remove-item  $systeminfolog -Force -ErrorAction SilentlyContinue
 
 if($nondia_flag.length -eq 0 -and $inisys -eq 0){   
    $line2 ="Now we check the system information"
& outwords $line2 20
Write-Host ""
}

$syslines=$null
 $timenow= (get-date -Format "yyyy-M-d HH:mm") + " / " +(Get-TimeZone).id
  $timenow=$timenow.ToString()
    $syslines=$timenow
    
#$BIOS=systeminfo | findstr /I /c:bios
$BIOS=(Get-CimInstance -ClassName Win32_BIOS).SMBIOSBIOSVersion

 $sysline= [string]::Join("`n","------------",$BIOS )
    $syslines= [string]::Join("`n",$syslines,$sysline)
    
Get-CimInstance -ClassName Win32_Processor|foreach-object{
 $cpu=$_.DeviceID +" : "+ $_.Name
 $cpus=  $cpus+@($cpu) 

  }

    $sysline= [string]::Join("`n","------------", [string]::Join("`n", $cpus) )
     $syslines= [string]::Join("`n",$syslines,$sysline)

$CompObject =  Get-WmiObject -Class WIN32_OperatingSystem
$RAM = (($CompObject.TotalVisibleMemorySize - $CompObject.FreePhysicalMemory)/1024)
$RAM2 = [math]::Round(($CompObject.TotalVisibleMemorySize - $CompObject.FreePhysicalMemory)/1024/1024)

$RAM = (Get-WmiObject -class "cim_physicalmemory" | Measure-Object -Property Capacity -Sum).Sum /1024/1024
$RAM2=$RAM/1024

     $sysline= [string]::Join("`n","------------","System RAM : $($RAM2) GB,($($RAM) MB)" )
       $syslines= [string]::Join("`n",$syslines,$sysline)

      
$disks=  (Get-WmiObject Win32_PnPSignedDriver|where-object{$_.DeviceClass -match "disk"}).FriendlyName

  $sysline= [string]::Join("`n", "------------","DiskInfo: ",[string]::Join("`n",$disks))
    $syslines= [string]::Join("`n",$syslines,$sysline)

    
$name=(Get-WmiObject Win32_OperatingSystem).caption
 $bit=(Get-WmiObject Win32_OperatingSystem).OSArchitecture
 $Versiona=(Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name DisplayVersion).DisplayVersion
  $Version = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\'
   $OScheck=" $name, $bit, $Versiona (OS Build $($Version.CurrentBuildNumber).$($Version.UBR))"
  
     $sysline= [string]::Join("`n","------------","OS Version: ",$OScheck )
       $syslines= [string]::Join("`n",$syslines,$sysline)

  $comutername=[System.Security.Principal.WindowsIdentity]::GetCurrent().Name
    $sysline= [string]::Join("`n","------------","Computer Name\User Name: ",$comutername)
       $syslines= [string]::Join("`n",$syslines,$sysline)

  Write-Host ""
     Write-Host  $syslines  

      
  if($nondia_flag.length -eq 0 -and $inisys -eq 0){   
  
   $line= "Is above system information correct? (Enter:yes,N:no)"
   $ans=read-host $line
   if($ans -match "n"){exit}

   }

   Write-Host ""
   
 New-Item -Path  $systeminfolog -value  $syslines -Force | out-null

 $checksys_words= (get-content $systeminfolog  | Measure-Object -Line -Character -Word -IgnoreWhiteSpace).Words

 $inisys++

 if($checksys_words -le 2){Start-Sleep -s 60}

} until( $checksys_words -gt 2 )
 
 #### get-eventlog

 $evtfile="$daver_path\$($dd)_step$($tcstep)_Eventlog.csv"
 
 get-winevent -FilterHashtable @{logname='application','system','setup','Microsoft-Windows-Diagnostics-Performance/Operational'} -Oldest `
 | select-object -property Level,LevelDisplayName,LogName,TimeCreated,ProviderName,Id,TaskDisplayName,Message `
  |export-csv -LiteralPath $evtfile -Encoding UTF8 -NoTypeInformation
  
 ###########  Clear Eventlog ########

 Write-Host "clear eventlog"
 Get-EventLog -LogName * | ForEach-Object { Clear-EventLog $_.Log }
 Write-Host "clear eventlog done"
 Write-Host ""
 #>

  ###########  Check Yellow Bang ########

$ye=Get-WmiObject Win32_PnPEntity|where-object{ $_.ConfigManagerErrorCode -ne 0}|Select-Object Name,Description, DeviceID, Manufacturer
# Get-PnpDevice -InstanceId *|?{$_.Status -match "error" }

if($ye.count -gt 0){
$yefile= "$daver_path\$($dd)_step$($tcstep)_yellowbang.csv" 
$ye|Export-Csv $yefile -Encoding UTF8 -NoTypeInformation


  if($nondia_flag.length -eq 0){   
  
$line= "With Yellow Bang in device manager, continue? (Enter:yes,N:no)"
Start-Process devmgmt.msc
Start-Sleep -s 3

$hwnd=(get-process cmd).MainWindowHandle

ShowWindow( $hwnd ) |Out-Null

Start-Sleep -s 2
$ans=read-host $line
if($ans -match "n"){exit}
}

}


if($ye.count -eq 0){
write-host "No Yellow Band, continue..."
$ans="Y"
}


if($wshell.AppActivate('Device Manager') -eq $true){

stop-process -name mmc

}


####check if need setup memory integrity ###

  if($nondia_flag.length -eq 0){   

$memory_turnoncheck=(import-csv C:\testing_AI\settings\flowsettings.csv).programs
if($memory_turnoncheck -match "Memory_integrity"){

$setting=Get-ItemPropertyValue -Path HKLM:SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity -Name Enabled -ErrorAction SilentlyContinue

if( ($memory_turnoncheck -match "turn_ON" -and $setting -ne 1) -or ($memory_turnoncheck -match "turn_OFF" -and $setting -ne 0) ){
  Write-Host ""
 & outwords "Setup Memory integrity need manual action, please wait..."  20
 }

}

else{
  
  Write-Host ""
 & outwords "Initial checks complete! Auto tool will take charge of following tests since now on."  20
 Write-Host ""
  & outwords  "You are free to go. See you next time. "  20
  }

}

### hide cmd window ##

 if((get-process "cmd" -ea SilentlyContinue)){ 
$lastid=  (Get-Process cmd |Sort-Object StartTime -ea SilentlyContinue |Select-Object -last 1).id
 Get-Process -id $lastid  | Set-WindowState -State MINIMIZE
  }


###########  save SW versions ######## move to check DM ##

#Get-WmiObject Win32_PnPSignedDriver|select DeviceName, DriverVersion, HardwareID, Signer, IsSigned, DriverProviderName, InfName|?{$_.InfName -match "oem"}|Export-Csv $daver_path\DriverVersion_$($dd).csv -Encoding UTF8 -NoTypeInformation
#Get-WmiObject Win32_PnPSignedDriver|select DeviceName, DriverVersion, HardwareID, Signer, IsSigned, DriverProviderName, InfName|Export-Csv $daver_path\DriverVersion_all_$($dd).csv -Encoding UTF8 -NoTypeInformation
#Get-CimInstance win32_product | Select-object Name,Version,Vendor,InstallDate,PackageFullName | Export-csv "$daver_path\$($dd)_step$($tcstep)_AppVersion.csv" -Encoding UTF8 -NoTypeInformation 
#Get-AppxPackage | Select-object Name,Version,Vendor,InstallDate,PackageFullName | Export-csv "$daver_path\$($dd)_step$($tcstep)_AppVersion.csv"  -Append  -Encoding UTF8  -NoTypeInformation
#Get-Package | select name, Version,ProviderName,Source,FastPackageReference |Export-Csv -Path  $daver_path\packages_$($dd).csv -Encoding UTF8  -NoTypeInformation

###########  set auto logon ########

powercfg /SETDCVALUEINDEX SCHEME_CURRENT SUB_NONE CONSOLELOCK 0

### DM screentshot ###

Get-Module -name "checkDM"|remove-module
$mdpath=(get-childitem -path "C:\testing_AI\modules\"  -r -file |where-object{$_.name -match "checkDM" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global


  if($noncapt_flag.Length -eq 0){   
    checkDM -para2 "nooutput"
    }

  else{
   checkDM -para2 "nooutput" -para3 "nocapture"
  }


  if($noncapt_flag.Length -eq 0){   
    
### Winver screentshot ###

 start-sleep -s 2

 winver
 
 start-sleep -s 5
   
 $wshell.AppActivate('about') 
    
&$actionmd  -para3 nonlog -para5 "step$($tcstep)_Winver"

if( $wshell.AppActivate('about') -eq $true){

stop-process -name winver
 
}

## install windows update package ##

#Set-PSRepository -Name PSGallery -installationPolicy Trusted
#Install-Module PSWindowsUpdate  -WarningAction Continue

$modname="ossettings_check"

Get-Module -name $modname|remove-module
$mdpath=(get-childitem -path "C:\testing_AI\modules\"  -r -file |where-object{$_.name -match $modname -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

#write-host "Do $action!"
&$modname -para1 "windowsupdate" -para3 "nonlog"
&$modname -para1 "coreiso" -para3 "nonlog"


### msinfo32 screentshot ###

 Start-Process msinfo32 

 start-sleep -s 5
   
 $wshell.AppActivate('system information') 
    [System.Windows.Forms.SendKeys]::SendWait("% ")
    [System.Windows.Forms.SendKeys]::SendWait("x")
     start-sleep -s 2
          
&$actionmd  -para3 nonlog -para5 "step$($tcstep)_msinfo32"

 start-sleep -s 2

if( $wshell.AppActivate('system information') -eq $true){

stop-process -name msinfo32 -Force
 
}

###########  copy powersettings to ini folder


$powerlog1="$env:userprofile\desktop\powercfg_before.txt"
$powerlog2="$env:userprofile\desktop\powercfg_after.txt"

if(Test-Path $powerlog1 -ea SilentlyContinue){move-item $powerlog1 -Destination $daver_path }
if(Test-Path $powerlog2 -ea SilentlyContinue){move-item $powerlog2 -Destination $daver_path }

}

###########  turn off notification
#by New-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\PushNotifications" -Name "ToastEnabled" -Value 0 -PropertyType DWORD -Force
# Define the registry path and value name
$registryPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\PushNotifications"
$valueName = "ToastEnabled"

# Check if the registry path exists
if (-not (Test-Path $registryPath)) {
    # Create the registry path if it does not exist
    New-Item -Path $registryPath -Force
}

# Check if the ToastEnabled property exists
if (-not (Test-Path "$registryPath\$valueName")) {
    # Create the ToastEnabled property and set it to 1 (enabled) by default
    New-ItemProperty -Path $registryPath -Name $valueName -Value 0 -PropertyType DWORD -Force
}

# Now retrieve the current value of ToastEnabled
$currentValue = Get-ItemPropertyValue -Path $registryPath -Name $valueName

if ($currentValue -eq 1) {
    # Notifications are enabled, let's disable them
    Set-ItemProperty -Path $registryPath -Name $valueName -Value 0
    Write-Host "Windows notifications have been disabled."
} 

###########  record logs ########

if($nonlog_flag.length -eq 0){

$picfiles=(get-childitem $daver_path |where-object{$_.name -match ".jpg" }).FullName
$picfile=[string]::join("`n",$picfiles)

$results="check files and screenshots"
$index="$picfile"

Get-Module -name "outlog"|remove-module
$mdpath=(get-childitem -path "C:\testing_AI\modules\" -r -file |where-object{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global


#write-host "Do $action!"
outlog $action $results  $tcnumber $tcstep $index
}

}


    export-modulemember -Function initial


