
function enable_MemoryDump {
    
    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force;
    $wshell=New-Object -ComObject wscript.shell
      Add-Type -AssemblyName Microsoft.VisualBasic
      Add-Type -AssemblyName System.Windows.Forms
      Add-Type -AssemblyName System.Windows.Forms,System.Drawing

#enable
wmic recoveros set DebugInfoType = 7

 #Set-ItemProperty -Path HKLM:SYSTEM\CurrentControlSet\Control\CrashControl -Name CrashDumpEnabled -Type DWord -Value 0x7 -Force

 Set-ItemProperty -Path HKLM:SYSTEM\CurrentControlSet\Control\CrashControl -Name AlwaysKeepMemoryDump -Type DWord -Value 00000001 -Force

#disable
# wmic recoveros set DebugInfoType = 0

if($PSScriptRoot.length -eq 0){
$scriptRoot="C:\testing_AI\modules"
}
else{
$scriptRoot=$PSScriptRoot
}

$action="Enable_MemoryDump"
$tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
$tcnumber=((get-content $tcpath).split(","))[0]
$tcstep=((get-content $tcpath).split(","))[1]

$timenow=get-date -format "yyMMdd_HHmmss"
#$picpath=(Split-Path -Parent $scriptRoot)+"\logs\screenshot\"
$picpath=(Split-Path -Parent $scriptRoot)+"\logs\$tcnumber\"
if(-not(test-path $picpath)){new-item -ItemType directory -path $picpath |out-null}

$actionmd="screenshot"
Get-Module -name $actionmd|remove-module
$mdpath=(gci -path $scriptRoot -r -file |?{$_.name -match "^$actionmd\b" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

$screen = [System.Windows.Forms.Screen]::PrimaryScreen
$bounds = $screen.Bounds
$width  = $bounds.Width
$height = $bounds.Height


start-sleep -Seconds 5

SystemPropertiesAdvanced   ##### call window

start-sleep -Seconds 2
[System.Windows.Forms.SendKeys]::SendWait("{tab}")
start-sleep -Seconds 2
[System.Windows.Forms.SendKeys]::SendWait("{tab}")
start-sleep -Seconds 2
[System.Windows.Forms.SendKeys]::SendWait("~")
start-sleep -Seconds 2

&$actionmd  -para3 nonlog

$picfile=(gci $picpath |?{$_.name -match ".jpg" -and $_.name -match "$action" }).FullName

$results="chceck screenshot"
$Index=$picfile

start-sleep -Seconds 2

if( $wshell.AppActivate('System Properties') -eq $true){
stop-process -name SystemPropertiesAdvanced
}

######### write log #######

Get-Module -name "outlog"|remove-module
$mdpath=(gci -path "C:\testing_AI\modules\"  -r -file |?{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

#write-host "Do $action!"
outlog $action $results $tcnumber $tcstep $index


  }

    export-modulemember -Function enable_MemoryDump