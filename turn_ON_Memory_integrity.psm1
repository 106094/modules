﻿
function turn_ON_Memory_integrity {
    
    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force;
    $wshell=New-Object -ComObject wscript.shell
      Add-Type -AssemblyName Microsoft.VisualBasic
      Add-Type -AssemblyName System.Windows.Forms

if($PSScriptRoot.length -eq 0){
$scriptRoot="C:\testing_AI\modules"
}
else{
$scriptRoot=$PSScriptRoot
}

$action="Turn_ON_Core_isolation_Memory_integrity"

$tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
$tcnumber=((get-content $tcpath).split(","))[0]
$tcstep=((get-content $tcpath).split(","))[1]

$picpath=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\"
if(-not(test-path $picpath)){new-item -ItemType directory -path $picpath |out-null}

$actionss ="screenshot"
Get-Module -name $actionss|remove-module
$mdpath=(Get-ChildItem -path $scriptRoot -r -file |Where-object{$_.name -match "^$actionss\b" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

#$width  = (([string]::Join("`n", (wmic path Win32_VideoController get CurrentHorizontalResolution))).split("`n") -match "\d{1,}")[0]
#$height  = (([string]::Join("`n", (wmic path Win32_VideoController get CurrentVerticalResolution))).split("`n") -match "\d{1,}")[0]

$setting=Get-ItemPropertyValue -Path HKLM:SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity -Name Enabled

if($setting -ne 1){

explorer.exe windowsdefender://coreisolation
#$cmd="%windir%\explorer.exe windowsdefender://coreisolation"
#start-process cmd -ArgumentList "/c $cmd"
start-sleep -s 5

 $id=((Get-Process *)|Where-object{$_.MainWindowTitle -match "Windows Security"}).Id
 start-sleep -s 5
 [Microsoft.VisualBasic.interaction]::AppActivate($id)|out-null

 ##screenshot##
&$actionss  -para3 nonlog -para5 "Core_isolation_status"


 <##
[System.Windows.Forms.SendKeys]::SendWait("{tab}")
start-sleep -s 2
[System.Windows.Forms.SendKeys]::SendWait("+{tab}")
start-sleep -s 2
[System.Windows.Forms.SendKeys]::SendWait(" ")
start-sleep -s 5
[Microsoft.VisualBasic.interaction]::AppActivate($id)|out-null
start-sleep -s 2
 (get-process -id $id).CloseMainWindow() 
 start-sleep -s 2
  ###>

}


#enable
   #Set-MpPreference -DisableRealtimeMonitoring
   #Set-ItemProperty -Path HKLM:SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios -Name CredentialGuard  -Type DWord -Value 00000000 -Force
   #Set-ItemProperty -Path HKLM:SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity -Name Enabled -Type DWord -Value 00000001 -Force

#disable
   #Set-ItemProperty -Path HKLM:SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity -Name Enabled -Type DWord -Value 00000000 -Force
     #Set-ItemProperty -Path HKLM:SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity -Name WasEnabledBy -Type DWord -Value 00000002 -Force

$results="-"
$index="check os setting screenshot"

######### write log #######

Get-Module -name "outlog"|remove-module
$mdpath=(Get-ChildItem -path "C:\testing_AI\modules\"  -r -file |Where-object{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

#write-host "Do $action!"
outlog $action $results $tcnumber $tcstep $index

if($setting -ne 1){

#[System.Windows.Forms.MessageBox]::Show($this, "請手動 turn On Memory Integrity 並依照Windows指示Reboot(Reboot後會再繼續自動執行排定流程)")
[Microsoft.VisualBasic.Interaction]::MsgBox(" 請手動 turn On Memory Integrity`n 並依照Windows指示Reboot `n (Reboot後會再繼續自動執行排定流程)",'OKOnly,SystemModal,Information', 'check')

 exit
 }
 else{
   Restart-Computer -Force
 }

  }

    export-modulemember -Function turn_ON_Memory_integrity