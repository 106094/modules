
function gfx_install ([string]$para1,[string]$para2,[string]$para3,[string]$para4){
 
    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force;
    $wshell=New-Object -ComObject wscript.shell
     $shell=New-Object -ComObject shell.application
      Add-Type -AssemblyName Microsoft.VisualBasic
        Add-Type -AssemblyName System.Windows.Forms,System.Drawing 

#region functions

Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public class Window {
    [DllImport("user32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect);
}

public class Win32 {
    [DllImport("user32.dll", SetLastError = true)]
    public static extern IntPtr FindWindow(string lpClassName, string lpWindowName);

    [DllImport("user32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect);
}

public struct RECT {
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

#endregion 
     
if($PSScriptRoot.length -eq 0){
$scriptRoot="C:\testing_AI\modules"
}
else{
$scriptRoot=$PSScriptRoot
}


if($para1.length -eq 0){
$para1="N"
}
if($para2.length -eq 0){
$para2=""
}
if($para3.length -eq 0){
$para3=""
}
    $nn1=$para1
    $attachedmode=$para2
    $actiontype=$para3
    $nonlogflag=$para4

$tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
$tcnumber=((get-content $tcpath).split(","))[0]
$tcstep=((get-content $tcpath).split(","))[1]
$action=((get-content $tcpath).split(","))[2]

$picpath=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\"
if(-not(test-path $picpath)){new-item -ItemType directory -path $picpath |out-null}


$actioncp="copyingfiles"
Get-Module -name $actioncp|remove-module
$mdpath=(Get-ChildItem -path $scriptRoot -r -file |Where-object{$_.name -match "^$actioncp\b" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

$actioncmd="cmdline"
Get-Module -name $actioncmd|remove-module
$mdpath=(Get-ChildItem -path $scriptRoot -r -file |Where-object{$_.name -match "^$actioncmd\b" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

$actiondup="dup_install"
Get-Module -name $actiondup|remove-module
$mdpath=(Get-ChildItem -path $scriptRoot -r -file |Where-object{$_.name -match "^$actiondup\b" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

$actionexp="filexplorer"
Get-Module -name $actionexp|remove-module
$mdpath=(Get-ChildItem -path $scriptRoot -r -file |Where-object{$_.name -match "^$actionexp\b" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

$actionamdins="amdinstall"
Get-Module -name $actionamdins|remove-module
$mdpath=(Get-ChildItem -path $scriptRoot -r -file |Where-object{$_.name -match "^$actionamdins\b" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

$actionss="screenshot"
Get-Module -name $actionss|remove-module
$mdpath=(Get-ChildItem -path $scriptRoot -r -file |Where-object{$_.name -match "^$actionss\b" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

$inidrv=(Get-ChildItem "C:\testing_AI\logs\ini*\*" -r -Filter "*DriverVersion.csv"|Sort-Object lastwritetime|select -last 1).FullName
$checktype=(import-csv $inidrv|Where-object{$_.DeviceClass -match "DISPLAY"}).devicename

if($inidrv -and $checktype){
if($checktype -match "NVIDIA"){
$drvtype2="NV_general"
if($checktype -match "ada"){
$drvtype2="NV_A6000ada"
}
write-host "The Display Driver is $($drvtype2)"
}
if($checktype -match "AMD"){
$chekdrv=$checktype -match "[a-zA-Z]\d{4}"
if(!$chekdrv){$checktype -match "\d{4}"}
$drvtype2="AMD_"+$matches[0]
write-host "The Display Driver is $($drvtype2)"
}

## check if folder exist

$drvfd="$scriptRoot\driver\GFX\$($drvtype2)\$($nn1)"

## if no exist, copy it from server
if(!(test-path $drvfd )){
&$actioncp -para1 "\\192.168.2.249\srvprj\Inventec\Dell\Matagorda\07.Tool\_AutoTool\driver\GFX" -para2 "$scriptRoot\driver" -para3 nolog
}

## after copy 

if(test-path $drvfd){

$subf=@("$($drvfd)\")

## start install driver #
if($checktype -match "NVIDIA"){
$subf=@("$($drvfd)\driver","$($drvfd)\app","$($drvfd)\ControlPanel")
}

foreach($insfd in $subf){

$sub=(($insfd.replace($drvfd,"")).replace("\","")).trim()

$timenow=get-date -format "yyMMdd_HHmmss"
$logpath=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\$($timenow)_step$($tcstep)_DUPinstall.txt"
$logpath_extract=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\$($timenow)_step$($tcstep)_DUPextract.txt"
$extractpath=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\$($timenow)_step$($tcstep)_DUPextract\"
$extractfaillog=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\$($timenow)_step$($tcstep)_DUPextract_fail.txt"
$zipdes=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\$($timenow)_step$($tcstep)_MUPextract\"
$logpath3=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\$($timenow)_step$($tcstep)_MUPinstall.txt"
$dupnamepic1="DUP"
$dupnamepic="MUP"
$errorlevelp=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\$($timenow)_step$($tcstep)_errorlevel_pass.txt"
$errorlevelf=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\$($timenow)_step$($tcstep)_errorlevel_fail.txt"
$results="OK"
$results_ng="NG"
$index="check data after reboot"
$index_nofile="no DUP(exe) or MUP(zip) files"

if($sub.length -gt 0){
$logpath=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\$($timenow)_step$($tcstep)_$($sub)_DUPinstall.txt"
$logpath_extract=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\$($timenow)_step$($tcstep)_$($sub)_DUPextract.txt"
$extractpath=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\$($timenow)_step$($tcstep)_$($sub)_DUPextract\"
$extractfaillog=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\$($timenow)_step$($tcstep)_$($sub)_DUPextract_fail.txt"
$zipdes=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\$($timenow)_step$($tcstep)_$($sub)_MUPextract\"
$logpath3=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\$($timenow)_step$($tcstep)_$($sub)_MUPinstall.txt"
$dupnamepic1="DUP_$($sub)"
$dupnamepic="MUP_$($sub)"
$results="OK($($sub))"
$results_ng="NG($($sub))"
$index_nofile="$($sub) folder no DUP(exe) or MUP(zip) files"
}

$exefile=Get-ChildItem $insfd\*.exe -ea SilentlyContinue|sort lastwritetime|select -last 1
### DUP ##
if($exefile){

$runfile=$exefile.FullName
$runfilename=$exefile.basename
$runfilename2=$exefile.name

### DUP unattached mode ##

if($attachedmode.length -eq 0){

if($actiontype.Length -eq 0 -or $actiontype -match "extract"){

if(!(test-path $extractpath)){
new-item -ItemType directory -Path $extractpath|out-null
}
&$runfile /s /e=$extractpath /l=$logpath_extract

$exeresult=$?

if($exeresult -eq $true){
set-content -path $errorlevelp -Value "success" -Force
}
else{
set-content -path $errorlevelf -Value "fail"  -Force
}


do{
start-sleep -s 5
}until(!(get-process -name $runfilename -ErrorAction SilentlyContinue))

$extractcheck=(Get-ChildItem -path $extractpath -file -Recurse).count
if($extractcheck -gt 0){
&$actionexp -para1 $extractpath -para2 nonlog
$picfile=Get-ChildItem -path $picpath -r |Where-object{$_.Name -match "gfx_install_file_explore.jpg"}|sort lastwritetime|select -Last 1
$picfilename=($picfile.fullname).replace("gfx_install_file_explore.jpg","gfx_extract_file_explore.jpg")
if($sub.length -gt 0){
$picfilename=($picfile.fullname).replace("gfx_install_file_explore.jpg","gfx_$($sub)_extract_file_explore.jpg")
}

Rename-Item ($picfile.fullname) -NewName $picfilename
}
else{
set-content -path $extractfaillog -Value "extract fail, no extract files exists"
}

}

if($actiontype.Length -eq 0 -or $actiontype -match "install"){

$cmdbf=(get-process -name cmd -ea SilentlyContinue).Id

&$runfile /s /l=$logpath

$exeresult=$?
if($exeresult -eq $true){
set-content -path $errorlevelp -Value "success"
}
else{
set-content -path $errorlevelf -Value "fail"
}

start-sleep -s 10
$cmdaf=(get-process -name cmd -ea SilentlyContinue).Id|Where-object{$_ -notin $cmdbf}

if($cmdaf.count -gt 0){
$actionss="screenshot"
Get-Module -name $actionss|remove-module
$mdpath=(Get-ChildItem -path $scriptRoot -r -file |Where-object{$_.name -match "^$actionss\b" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

&$actionss -para3 nonlog -para5 "$($dupnamepic1)_cmdwindow"
stop-process -Id $cmdaf -Force
}

do{
start-sleep -s 5

$checksec=get-process * |Where-object{$_.MainWindowTitle -eq "windows security"}
if($checksec){
 write-host "security screen pop up"
 &$actionss -para3 nonlog -para5 "popup_securitycheck"
       $dll=get-process -name rundll32 -ErrorAction SilentlyContinue
      $wintitle=$dll.MainWindowTitle
      
$windowHandle2 =$dll.MainWindowHandle
$windowRect2 = New-Object RECT

 [Win32]::GetWindowRect($windowHandle2, [ref]$windowRect2)

    $left2 = $windowRect2.Left
    $top2 = $windowRect2.Top
    
  Start-Sleep -s 2
[Clicker]::LeftClickAtPoint($left2+100,$top2+20)
 Start-Sleep -s 5 
   [System.Windows.Forms.SendKeys]::SendWait("+{tab}")
     Start-Sleep -s 2
     
   [System.Windows.Forms.SendKeys]::SendWait("{enter}")

   Start-Sleep -s 2
}

}until(!(get-process -name $runfilename -ErrorAction SilentlyContinue))

}

}

### DUP attached mode install##

else{
if($actiontype.Length -eq 0 -or $actiontype -match "extract"){
&$actiondup -para1 $runfilename2 -para2 extract -para3 nolog
}
if($actiontype.Length -eq 0 -or $actiontype -match "install"){
&$actiondup -para1 $runfilename2 -para2 install -para3 nolog
}

}

}

#### MUP ##
else{

$zipfile=Get-ChildItem $insfd\*.zip|sort lastwritetime|select -last 1
$zipfilebname=$zipfile.BaseName
if($zipfile){
Expand-Archive $zipfile.FullName -DestinationPath  $zipdes -Force

if($actiontype.Length -eq 0 -or $actiontype -match "extract"){
&$actionexp -para1 $zipdes -para2 nonlog
}

#### MUP only support install ##
if($actiontype.Length -eq 0 -or $actiontype -match "install"){
if($checktype -match "AMD"){
$runfiles=(Get-ChildItem -path $zipdes -Recurse |Where-object{$_.name -match "ATISetup\.exe"　})
$runfiles_att=((Get-ChildItem -path $zipdes -Recurse |Where-object{$_.name -match "^Setup\.exe"|sort {($_.fullname).length}}|select -First 1).FullName).replace("$zipdes",".\")
$apprunfiles2=((Get-ChildItem -path $zipdes -Recurse |Where-object{$_.name -match "_License"}).FullName).replace("$zipdes",".\")
$apprunfiles1=((Get-ChildItem -path $zipdes -Recurse |Where-object{$_.name -match (($apprunfiles2.split("\\"))[-1].split("_"))[0]+"\.appx" }).FullName ).replace("$zipdes",".\")
$apprunfiles3=((Get-ChildItem -path $zipdes -Recurse |Where-object{$_.name -match "\.appx" -and $_.name -match "x64" }).FullName ).replace("$zipdes",".\")

}
if($checktype -match "NVIDIA"){
$runfiles=Get-ChildItem -path $zipdes -Recurse |Where-object{$_.name -match "installapp\.bat" -or $_.name -match "NVMUP\.exe"}
}


foreach($runfile in $runfiles){
$runfilefull=$runfile.fullname
$runfilebase=$runfile.basename

if($checktype -match "AMD"){

### MUP unattached mode ##

if($attachedmode.length -eq 0 -and $runfile -match "ATISetup\.exe"){

##AMD MUP Driver install
$installcmd=$runfilefull+" -install all -log $logpath3"
&$actioncmd -para1 $installcmd -para3 cmd -para5 nonlog

##AMD MUP APP install##
if($apprunfiles1 -and $apprunfiles2 -and $apprunfiles3){
$hsacmd="DISM /Online /Add-ProvisionedAppxPackage /PackagePath:""$apprunfiles1"""+`
  " /LicensePath:""$apprunfiles2"""+`
   " /DependencyPackagePath:""$apprunfiles3"""

&$actioncmd -para1 $hsacmd -para2 $zipdes -para3 cmd -para5 nonlog
}
else{
write-host "Error: lack DISM conditions"
}

}

###AMD MUP attached mode ##
if($attachedmode.length -gt 0 -and $runfiles_att -match "^Setup\.exe"){
&$actionamdins -para1 $runfiles_att -para2 "nonlog"
}

}

if($checktype -match "NVIDIA"){

if($runfilefull -match "NVMUP\.exe"){

###NV MUP unattached mode install (Driver/APP)##

if($attachedmode.length -eq 0){
&$runfilefull /s /v "LOGFILE=\""$($logpath3)"""
do{
start-sleep -s 5
}until(!(get-process -name $runfilebase -ErrorAction SilentlyContinue))
}
###NV MUP attached mode install (Driver/APP)##
if($attachedmode.length -ne 0){

## call again ## module lost by unknow reason
$actionss="screenshot"
Get-Module -name $actionss|remove-module
$mdpath=(Get-ChildItem -path $scriptRoot -r -file |Where-object{$_.name -match "^$actionss\b" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global
##>

&$runfilefull

$timestart=Get-Date

      do{
      Start-Sleep -s 10
       $timetill=Get-Date
       $nvmup=get-process -name NVMUP -ErrorAction SilentlyContinue
       $timegap=(New-TimeSpan -start $timestart -End $timetill).TotalSeconds
       }until ($timegap -gt 60 -or $nvmup)  ##expect DUP call MUP within 60sec
      
      if($nvmup){
      Start-Sleep -s 10
      $nvmup=get-process -name NVMUP -ErrorAction SilentlyContinue
      $wintitle=$nvmup.MainWindowTitle
      
$windowHandle2 =$nvmup.MainWindowHandle
$windowRect2 = New-Object RECT

 [Win32]::GetWindowRect($windowHandle2, [ref]$windowRect2)

    $left2 = $windowRect2.Left
    $top2 = $windowRect2.Top
    
[Microsoft.VisualBasic.interaction]::AppActivate($wintitle)|out-null
  Start-Sleep -s 2
[Clicker]::LeftClickAtPoint($left2+20,$top2+20)
 Start-Sleep -s 2
 
   [System.Windows.Forms.SendKeys]::SendWait("a")
 Start-Sleep -s 5

   &$actionss -para3 nonlog -para5 "$($dupnamepic)_step1"
   
   [System.Windows.Forms.SendKeys]::SendWait("n")

      &$actionss -para3 nonlog -para5 "$($dupnamepic)_step2"

  $ctn=0
 do{
 $ctn++
 Start-Sleep -s 60

 &$actionss -para3 nonlog -para5 "$($dupnamepic)_step3_$($ctn)"

   [System.Windows.Forms.SendKeys]::SendWait(" ")   
   Start-Sleep -s 10
  $nvmup=get-process -name NVMUP -ErrorAction SilentlyContinue
 }until(!$nvmup)


 }
 }

}

###NV MUP install withour NVMUP.exe  (ControlPanel) ##
if($runfile -match "installapp\.bat"){

$cmdbf=(get-process -name cmd -ea SilentlyContinue).Id

&$actioncmd -para1 $runfile -para3 cmd -para5 nonlog

start-sleep -s 10
$cmdaf=(get-process -name cmd -ea SilentlyContinue).Id|Where-object{$_ -notin $cmdbf}
if($cmdaf.count -gt 0){
&$actionss -para3 nonlog -para5 "$($runfilename)_cmdwindow"
stop-process -Id $cmdaf -Force
}
}

}

}

}

}

}

if(!$zipfile -and !$exefile){
$results=$results_ng
$index=$index_nofile
}

$resultsall=$resultsall+@($results)
$indexall=$indexall+@($index)


}
$results=$resultsall|Out-String
$index=$indexall|Out-String

}


else{
$results="NG"
$index="copy driver file fail"
}


}

else{
$results="NG"
$index="cannot find initial driver infomation"
}



write-host "$results,$index"

######### write log #######
if( $nonlogflag.Length -eq 0){

Get-Module -name "outlog"|remove-module
$mdpath=(Get-ChildItem -path "C:\testing_AI\modules\"  -r -file |Where-object{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

#write-host "Do $action!"
outlog $action $results $tcnumber $tcstep $index
}
    

   }

    export-modulemember -Function gfx_install