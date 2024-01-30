
function pcai ([string]$para1,[int]$para2,[string]$para3,[string]$para4,[string]$para5){
    
  Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force;
  $wshell=New-Object -ComObject wscript.shell
    Add-Type -AssemblyName Microsoft.VisualBasic
     Add-Type -AssemblyName System.Windows.Forms
      Add-Type -AssemblyName System.Windows.Forms,System.Drawing
try{    
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class Window {
  [DllImport("user32.dll")]
  [return: MarshalAs(UnmanagedType.Bool)]
  public static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect);
}
public struct RECT
{
  public int Left;
  public int Top;
  public int Right;
  public int Bottom;
}
"@
$cSource = @'
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
Add-Type -TypeDefinition $cSource -ReferencedAssemblies System.Windows.Forms,System.Drawing
}catch{
write-output "dummy"
}
if($PSScriptRoot.length -eq 0){
$scriptRoot="C:\testing_AI\modules"
}
else{
$scriptRoot=$PSScriptRoot
}

$actionss="screenshot"
Get-Module -name $actionss|remove-module
$mdpath=(Get-ChildItem -path $scriptRoot -r -file |Where-object{$_.name -match "^$actionss\b" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global
#&$actionss  -para3 nonlog  -para5 ""

$paracheck=$PSBoundParameters.ContainsKey('para1')
$paracheck2=$PSBoundParameters.ContainsKey('para2')
$paracheck3=$PSBoundParameters.ContainsKey('para3')
$paracheck4=$PSBoundParameters.ContainsKey('para4')
$paracheck5=$PSBoundParameters.ContainsKey('para5')

if( $paracheck -eq $false -or $para1.length -eq 0 ){
#write-host "no defined, setting 1 min after login"
$para1="no_define"
}
if($paracheck2 -eq $false -or $para2 -eq 0){
$para2=370
}
if($paracheck3 -eq $false -or $para3.Length -eq 0){
$para3=""
}
if($paracheck4 -eq $false -or $para4.Length -eq 0){
$para4=""
}
if($paracheck5 -eq $false -or $para5.Length -eq 0){
$para5=""
}

$scriptname=$para1
$waitlimit=$para2
$groupname=$para3
$pcaioption=$para4
$nonlog_flag=$para5


$tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
$tcnumber=((get-content $tcpath).split(","))[0]
$tcstep=((get-content $tcpath).split(","))[1]

if($groupname.Length -ne 0){
$picpath0=(Split-Path -Parent $scriptRoot)+"\logs\$tcnumber\"
#$picpath=(Split-Path -Parent $scriptRoot)+"\logs\$tcnumber\$groupname\"
$scriptpath=(Split-Path -Parent $scriptRoot)+"\logs\$tcnumber\$groupname\step_$($tcstep)_$scriptname\"
}
else{
$picpath0=(Split-Path -Parent $scriptRoot)+"\logs\$tcnumber\"
#$picpath=(Split-Path -Parent $scriptRoot)+"\logs\$tcnumber\$scriptname\"
$scriptpath=(Split-Path -Parent $scriptRoot)+"\logs\$tcnumber\step$($tcstep)_pcai_$($scriptname)\"
}


#if(-not(test-path $picpath)){new-item -ItemType directory -path $picpath  -Force |out-null}
if(-not(test-path $scriptpath)){new-item -ItemType directory -path $scriptpath  -Force |out-null}

#$width  = ([string]::Join("`n", (wmic path Win32_VideoController get CurrentHorizontalResolution))).split("`n") -match "\d{1,}"
#$height  = ([string]::Join("`n", (wmic path Win32_VideoController get CurrentVerticalResolution))).split("`n") -match "\d{1,}"

### start to run pcai ##

$runflag="run"

if($scriptname -ne "no_define"){

#$checkgfx=(Get-WmiObject -Class Win32_VideoController | Select-Object Name,AdapterCompatibility).name

$inidrv=(Get-ChildItem "C:\testing_AI\logs\ini*\*" -r -Filter "*DriverVersion.csv"|Sort-Object lastwritetime|Select-Object -last 1).FullName
$checktype=(import-csv $inidrv|Where-object{$_.DeviceClass -match "DISPLAY"}).devicename
if($checkgfx -match "AMD"){
  $drvtype="AMD"
}
if($checkgfx -match "NVidia"){
  $drvtype="NV"
}
if (($scriptname -match "^nv" -and $checkgfx -match "AMD") -or ($scriptname -match "^amd" -and $checkgfx -match "NVIDIA")){
 $runflag="skip"
 $results="na"
 $index="$($drvtype), skip"
}

if ($runflag -eq "run"){
(get-process -name msedge -ea SilentlyContinue).CloseMainWindow()
$checkrun=(get-process -Name "AutoTool" -ea SilentlyContinue).Id
if($checkrun){
taskkill /F /IM AutoTool.exe
}

$scriptname=$scriptname.replace(".ScriptAction","")

$action="pcai-$scriptname"
$scriptname=$scriptname.replace(".ScriptAction","")
$scriptfull=( Get-ChildItem "C:\testing_AI\modules\PC_AI_Tool*\Main\Windows\*\script\*" |Where-Object { $_.name -match "^$($scriptname)\." -and $_.name -match "\.ScriptAction"} ).FullName

if(!$scriptfull -or $scriptfull.Length -eq 0){
  $results="NG"
  $index="PCAI script not found"
}
else{

$oldresult=(Get-ChildItem C:\testing_AI\modules\PC_AI_Tool*\Main\Windows\Report\*\*.html).count

### wait 3D mark window open ##

if($scriptfull -match "3dmark"){
do{
start-sleep -s 5
if(get-process -name 3Dmark -ea SilentlyContinue){
$3dmarkwdopenstart=(get-process -name 3Dmark -ea SilentlyContinue|Where-object{$_.MainWindowTitle -match "Edition"}).StartTime
$3dmarkwdopentime=(New-TimeSpan -start $3dmarkwdopenstart -end (get-date)).TotalSeconds
}
}until($3dmarkwdopentime -gt 180)
}

$pcaipath=(Get-ChildItem C:\testing_AI\modules\PC_AI_Tool*\AutoTool.exe).FullName

function runpcai {

Set-Clipboard -value "$pcaipath $scriptfull /n /c"

start-process cmd -WindowStyle Maximized
$id2= (Get-Process -name cmd|Sort-Object StartTime -ea SilentlyContinue |Select-Object -last 1).id
$checkrun=(get-process -Name "AutoTool" -ErrorAction SilentlyContinue).Id
if($checkrun){
taskkill /F /IM AutoTool.exe
}
Start-Sleep -Seconds 5
[Microsoft.VisualBasic.interaction]::AppActivate($id2)|out-null
Start-Sleep -Seconds 2
[Clicker]::LeftClickAtPoint(50, 1)
Start-Sleep -Seconds 2
$wshell.SendKeys("~") 
Start-Sleep -Seconds 2
$wshell.SendKeys("^v")
Start-Sleep -Seconds 2
$wshell.SendKeys("~")

&$actionss  -para3 nonlog  -para5 "pcai_run"

(Get-Process -id $id2).CloseMainWindow()

####  check if running ###
Start-Sleep -Seconds 2
$checkrun=(get-process -Name "AutoTool").Id
$checkrun

}

$startpcaitime=Get-Date
$runpcai=runpcai  ## tool fail to execute ##

if($runpcai){
$results="OK"
$index="PCAI running"
$startpcaitime=Get-Date

###  collect results and screenshot -> close PCAI ##

do{
start-sleep -s 30
$newresult=(Get-ChildItem C:\testing_AI\modules\PC_AI_Tool*\Main\Windows\Report\*\*.html).count
$runtimemin= (New-TimeSpan -start $startpcaitime -End (Get-Date)).TotalMinutes
}until (($newresult - $oldresult) -gt 0 -or $runtimemin -gt $waitlimit)

## if fail to get result, run again 

if(($newresult - $oldresult) -eq 0){
$startpcaitime=Get-Date
$runpcai=runpcai   ## tool fail to execute ##

do{
start-sleep -s 60
$newresult=(Get-ChildItem C:\testing_AI\modules\PC_AI_Tool*\Main\Windows\Report\*\*.html).count
$runtimemin= (New-TimeSpan -start $startpcaitime -End (Get-Date)).TotalMinutes
}until (($newresult - $oldresult) -gt 0 -or $runtimemin -gt $waitlimit)
}

start-sleep -s 5
$checkfinish=((get-process -Name msedge -ErrorAction SilentlyContinue|Where-object{($_.MainWindowTitle) -match "allion"}).id).Count

if($checkfinish -ge 1){
(get-process -name msedge).CloseMainWindow()
}

$checkrun=(get-process -Name "AutoTool" -ErrorAction SilentlyContinue).Id

if($checkrun){
taskkill /F /IM AutoTool.exe
}

#remove-item C:\testing_AI\modules\PC_AI_Tool*\Token*.xml -Force
if(($newresult - $oldresult) -gt 0){
start-sleep -s 5
$pcairesult=(Get-ChildItem -path C:\testing_AI\modules\PC_AI_Tool*\Main\Windows\Report\* -Directory|Sort-Object creationtime |Select-Object -last 1).fullname
Move-Item $pcairesult $scriptpath -Force
move-item C:\testing_AI\logs\*.png  $picpath0 -Force ## merge all pic
start-sleep -s 5
## rename pic filename
$renamepics=Get-ChildItem -path $picpath0 -Filter "*.png"
foreach($renamepic in $renamepics){
if(!($renamepic.name -match "^\d{6}_${6}")){
$datewrite=get-date((Get-ChildItem $renamepic.fullname).LastWriteTime) -format "yyMMdd_HHmmss"
$newname=$datewrite+"_"+$renamepic.Name
rename-item $renamepic.fullname -NewName $newname ## rename as same date format
}

}

$results="OK"
$index="check results folder and screenshots"

}
else{
$results="NG"
$index="fail to collect results"
}

## kill PCAI  taskschedule

$taskExists =Get-ScheduledTask | Where-Object {$_.TaskName -like "PC AI Tool" } 

if($taskExists){

start-process cmd -ArgumentList '/c schtasks /delete /TN "PC AI Tool" -f' 
start-sleep -s 30

 $taskExists =Get-ScheduledTask | Where-Object {$_.TaskName -like "PC AI Tool" } 
 if(-not($taskExists)){ Write-Host "taskschedule delete OK"} else{ Write-Host "taskschedule delete NG"}  
  }
  else{
    Write-Host "there is no ""PC AI Tool"" task is found now"
  }

}
else{

$results="NG"
$index="PCAI fail to execute"

}
}
}

}

else{
$results="NG"
$index="PCAI script no define"
} 

######### write log #######

if($nonlog_flag.length -eq 0){

Get-Module -name "outlog"|remove-module
$mdpath=(Get-ChildItem -path "C:\testing_AI\modules\"  -r -file |Where-object{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

#write-host "Do $action!"
outlog $action $results $tcnumber $tcstep $index
}

if($pcaioption.length -match "exit"){
exit
}


}

  export-modulemember -Function pcai