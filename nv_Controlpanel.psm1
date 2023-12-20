
function nv_Controlpanel {
    
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

$action="nv_Controlpanel copy settings"

$tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
$tcnumber=((get-content $tcpath).split(","))[0]
$tcstep=((get-content $tcpath).split(","))[1]

$path_setting1="C:\ProgramData\NVIDIA Corporation\Drs"
$path_setting2=(gci "$env:userprofile\AppData\Local\Packages\NVIDIACorp*\SystemAppData\Helium\" -directory).fullname
$path_run=(gci "C:\Program Files\WindowsApps\NVIDIACorp.NVIDIAControlPane*\" -directory).fullname
 
### find the system gfx model ##
 $drvname=(Get-WmiObject Win32_VideoController | Select-Object name|?{$_.name -match "NVIDIA"} ).name

 if( $drvname){

### copy settigns ##
$settingf1=(gci C:\testing_AI\settings\nv_Controlpanel\$drvname\* -file).fullname
#$settingf2=(gci C:\testing_AI\settings\nv_Controlpanel\$drvname\SystemAppData\Helium\* -file).fullname

$settingf1| %{Copy-Item $_ -Destination $path_setting1 -Force }
#$settingf2| %{Copy-Item $_ -Destination $path_setting2 -Force }

#set-location $path_run
#start-process .\nvcplui.exe -WindowStyle Maximized

#start-sleep -s 10


$results="-"
$index="check pcai steps"
}
else{
$results="na"
$index="non-NVIDIA, bypass"
}
#scrshot -para1 NV_Controlpanel_opened

#stop-process nvcplui -Force

######### write log #######

Get-Module -name "outlog"|remove-module
$mdpath=(gci -path "C:\testing_AI\modules\"  -r -file |?{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

#write-host "Do $action!"
outlog $action $results $tcnumber $tcstep $index


  }

    export-modulemember -Function nv_Controlpanel