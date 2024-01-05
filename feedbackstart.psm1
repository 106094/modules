

function feedbackstart([string]$para1,[string]$para2,[string]$para3,[string]$para4){
   
  
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
 
  
Add-Type -AssemblyName System.Windows.Forms
$nonlog_flag=$para4

$action="FeedbackHub_start"
$tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
$tcnumber=((get-content $tcpath).split(","))[0]
$tcstep=((get-content $tcpath).split(","))[1]

$picpath=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\"
if(-not(test-path $picpath)){new-item -ItemType directory -path $picpath |out-null}


    $actionss ="screenshot"
    Get-Module -name $actionss|remove-module
    $mdpath=(Get-ChildItem -path $scriptRoot -r -file |Where-object{$_.name -match "^$actionss\b" -and $_.name -match "psm1"}).fullname
    Import-Module $mdpath -WarningAction SilentlyContinue
        

    $actionpcai ="pcai"
    Get-Module -name $actionpcai|remove-module
    $mdpath=(Get-ChildItem -path $scriptRoot -r -file |Where-object{$_.name -match "^$actionpcai\b" -and $_.name -match "psm1"}).fullname
    Import-Module $mdpath -WarningAction SilentlyContinue


# 打开反馈中心应用程序

 
<## reference ##
Start-Process "feedback-hub:" -WindowStyle Maximized
 do{
 start-sleep -s 5
 $settingfile=Get-ChildItem  "$env:USERPROFILE\AppData\Local\Packages\Microsoft.WindowsFeedbackHub_*\LocalState\content\FeedbackCategories.json"
 }until( $settingfile)
    $contentFeed = Get-Content $settingfile
    $cataindex = $contentFeed.IndexOf("$para1")

    $cata = $contentFeed.Substring($cataindex)
    $cataPropertyIndex = $cata.IndexOf("sortOrder")
    $property = $cata.Substring($cataPropertyIndex)
    $catacolonindex = $property.IndexOf(":")
    $savecontent = $contentFeed.Substring(0,$cataindex+$cataPropertyIndex+$catacolonindex+1) + "0" + $contentFeed.Substring($cataindex+$cataPropertyIndex+$catacolonindex+2)
    Set-Content -Path "$env:USERPROFILE\AppData\Local\Packages\Microsoft.WindowsFeedbackHub_8wekyb3d8bbwe\LocalState\content\FeedbackCategories.json" -Value $savecontent

    $contentFeed = Get-Content "$env:USERPROFILE\AppData\Local\Packages\Microsoft.WindowsFeedbackHub_8wekyb3d8bbwe\LocalState\content\FeedbackCategories.json" | ConvertFrom-Json
    $id = 0
    for($i=0;$i -lt $contentFeed.L1CategoryData.displayCategory.Length;$i++){
        if($contentFeed.L1CategoryData.displayCategory[$i].categoryName -match "$para1"){
            $id = $contentFeed.L1CategoryData.displayCategory[$i].id
        }       
    }

    for($i=0;$i -lt $contentFeed.L2CategoryData.uifContext.Length;$i++){
        
        if($contentFeed.L2CategoryData.uifContext[$i].displayFeature -eq "$para2" -and $contentFeed.L2CategoryData.uifContext[$i].displayCategoryId -eq $id){
            $contentFeed.L2CategoryData.uifContext[$i].sortOrder = 0
        }
    }
    $json = ConvertTo-Json $contentFeed -Depth 100 -Compress

    Set-Content -Path "$env:USERPROFILE\AppData\Local\Packages\Microsoft.WindowsFeedbackHub_8wekyb3d8bbwe\LocalState\content\FeedbackCategories.json" -Value $json


#$contentFeed = Get-Content "$env:USERPROFILE\AppData\Local\Packages\Microsoft.WindowsFeedbackHub_8wekyb3d8bbwe\LocalState\content\FeedbackCategories.json"
#$cataindex = $contentFeed.IndexOf("Gaming and Xbox")
#$cata = $contentFeed.Substring($cataindex)
#$cataPropertyIndex = $cata.IndexOf("sortOrder")
#$property = $cata.Substring($cataPropertyIndex)
#$catacolonindex = $property.IndexOf(":")
#$savecontent = $contentFeed.Substring(0,$cataindex+$cataPropertyIndex+$catacolonindex+1) + "0" + $contentFeed.Substring($cataindex+$cataPropertyIndex+$catacolonindex+2)
#Set-Content -Path "$env:USERPROFILE\AppData\Local\Packages\Microsoft.WindowsFeedbackHub_8wekyb3d8bbwe\LocalState\content\FeedbackCategories.json" -Value $savecontent
##>

# 打开反馈中心应用程序


if(get-process -name PilotshubApp -ea SilentlyContinue){
  stop-process -name PilotshubApp -ea SilentlyContinue
  start-sleep -s 10
  }
  
$winv= ([System.Environment]::OSVersion.Version).Build
$fbver=(Get-AppxPackage -AllUsers | Where-Object { $_.Name -match "feedback" }).version

Start-Process "feedback-hub:" 
start-sleep -s 60
 
 Get-Process -id (get-process -name ApplicationFrameHost).Id | Set-WindowState -State MAXIMIZE

 &$actionpcai -para1 "FeedbackHub" -para4 "nc" -para5 "nolog"

#region replaced by pcai action
<#
 start-sleep -s 2   
[System.Windows.Forms.SendKeys]::SendWait("+{TAB}")
[System.Windows.Forms.SendKeys]::SendWait("+{TAB}")
[System.Windows.Forms.SendKeys]::SendWait("{ENTER}")
start-sleep -s 2
[System.Windows.Forms.SendKeys]::SendWait("{TAB 3}")
start-sleep -s 2
[System.Windows.Forms.SendKeys]::SendWait(" ")
[System.Windows.Forms.SendKeys]::SendWait("{+}")
start-sleep -s 5
[System.Windows.Forms.SendKeys]::SendWait("+{tab}")
[System.Windows.Forms.SendKeys]::SendWait("+{tab}")
[System.Windows.Forms.SendKeys]::SendWait("+{tab}")
[System.Windows.Forms.SendKeys]::SendWait("+{tab}")
[System.Windows.Forms.SendKeys]::SendWait("+{tab}")


if($winv -lt 22000 -and $fbver -ne "1.2304.1243.0"){[System.Windows.Forms.SendKeys]::SendWait("{UP}")}

[System.Windows.Forms.SendKeys]::SendWait("{ENTER}")
start-sleep -s 2
#>
#endregion

<#Enter Advanced Diagnostics Interface

$hashfortabcount = @{
    "Display Issues" = 1
    "General" = 1
    "Hardware Buttons and USB" = 1
    "Media Issues" = 1
    "Mixed Reality Performance" = 2
    "Networking" = 1
    "Performance" = 1
    "Power" = 2
}


#third para
$count = 0
$typeofproblem = "$para3"
$top = $typeofproblem.Substring(0,1)
foreach($list in $hashfortabcount.Keys){
    if($list -eq $typeofproblem){
        $count = $($hashfortabcount[$list])
    }
}
##>
    start-sleep -s 2
    [System.Windows.Forms.SendKeys]::SendWait("{TAB}")
    start-sleep -s 2
    [System.Windows.Forms.SendKeys]::SendWait("{TAB}")
    start-sleep -s 2
    [System.Windows.Forms.SendKeys]::SendWait("{ENTER}")
    start-sleep -s 2
    [System.Windows.Forms.SendKeys]::SendWait("$para1")
    start-sleep -s 2
    [System.Windows.Forms.SendKeys]::SendWait("{ENTER}")
    start-sleep -s 2
    [System.Windows.Forms.SendKeys]::SendWait("{TAB}")
    start-sleep -s 2
    [System.Windows.Forms.SendKeys]::SendWait("{ENTER}")
    start-sleep -s 2
    [System.Windows.Forms.SendKeys]::SendWait("$para2")
    start-sleep -s 2
    [System.Windows.Forms.SendKeys]::SendWait("{ENTER}")
    start-sleep -s 2
    [System.Windows.Forms.SendKeys]::SendWait("{TAB}")
    #choose type of problem
    if($para3.Length -ne 0){    
    start-sleep -s 2
    [System.Windows.Forms.SendKeys]::SendWait("{ENTER}")
    start-sleep -s 2
    [System.Windows.Forms.SendKeys]::SendWait("$para3")
    start-sleep -s 2
    [System.Windows.Forms.SendKeys]::SendWait("{ENTER}")
    }
   

<##
    if($count -ne 0){
        for($i=0;$i -lt $count;$i++){
            [System.Windows.Forms.SendKeys]::SendWait($top)
            start-sleep -s 3
        }
    }
##>



    ######### write log  #######

$results="check screenshot"
$index=""

if($nonlog_flag.Length -eq 0){
Get-Module -name "outlog"|remove-module
$mdpath=(Get-ChildItem -path "C:\testing_AI\modules\"  -r -file |Where-object{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

#write-host "Do $action!"
outlog $action $results $tcnumber $tcstep $index

  }
   
    #[System.Windows.Forms.SendKeys]::SendWait(" ")  
 
   
 &$actionpcai -para1 "FeedbackHubstartrec" -para4 "nc" -para5 "nolog"
      
 &$actionss -para3 non_log -para5 "start_recording"

  <### hide window ##

      [System.Windows.Forms.SendKeys]::SendWait("% ")
      [System.Windows.Forms.SendKeys]::SendWait("n")
     start-sleep -s 1

##>

    #echo "Script wait 3min for user to reproduce issue"

    #$ws = New-Object -ComObject WScript.Shell  
    #$wsr = $ws.popup("Start recording with 3 minutes, Please reproduce issue",0,"Information",1 + 64)

    echo "start recording"
   

}
Export-ModuleMember -Function feedbackstart