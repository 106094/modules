
function ipmitool_shutdown ([int]$para1,[int]$para2,[int]$para3,[string]$para4) {

   Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force;
    $wshell=New-Object -ComObject wscript.shell
      Add-Type -AssemblyName Microsoft.VisualBasic
      Add-Type -AssemblyName System.Windows.Forms
      Add-Type -AssemblyName System.Windows.Forms,System.Drawing
      #$psObject = New-Object psobject
        
 $paracheck=$PSBoundParameters.ContainsKey('para1')
 $paracheck2=$PSBoundParameters.ContainsKey('para2')
 $paracheck3=$PSBoundParameters.ContainsKey('para3')
 $paracheck4=$PSBoundParameters.ContainsKey('para4')


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

if( $paracheck -eq $false -or $para1 -eq 0 ){
$para1="1"
}
if( $paracheck2 -eq $false -or $para2 -eq 0 ){
$para2="60"
}
if( $paracheck3 -eq $false -or $para3 -eq 0 ){
$para3="10"
}
if( $paracheck4 -eq $false -or $para4 -eq 0 ){
$para4=""
}


$ccount=[int64]$para1
$waitossec=$para2
$waitbfcssec=$para3
$nonlog_flag=$para4


$timenow=get-date -Format "yyyy/M/d HH:mm:ss"
    
if($PSScriptRoot.length -eq 0){
$scriptRoot="C:\testing_AI\modules"
}
else{
$scriptRoot=$PSScriptRoot
}

$tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
$tcnumber=((get-content $tcpath).split(","))[0]
$tcstep=((get-content $tcpath).split(","))[1]
$action=((get-content $tcpath).split(","))[2]

$logspath=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\$($tcstep)_ipmishutdown\cb_result.csv"
$faillogspath=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\$($tcstep)_ipmishutdown\cb_result_fail.csv"

$inifd_tcnumber=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)"
$inifd_ini=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\$($tcstep)_ipmishutdown\sys\ini"
$sysfd=split-path $inifd_ini

if(!(test-path $inifd_tcnumber)){ new-item -ItemType directory -path  $inifd_tcnumber -Force|Out-Null}
  if(!(test-path $inifd_ini)){ new-item -ItemType directory -path  $inifd_ini -Force|Out-Null}
  
$timenow2=get-date

#region check oobe
$checkoobe1=get-process -name *|Where-object{$_.name -match "WWAHost"}
$checkoobe2=get-process -name *|Where-object{$_.name -match "WebExperienceHostApp"}

if($checkoobe1 -or $checkoobe2){

$actionss="screenshot"
Get-Module -name $actionss|remove-module
$mdpath=(Get-ChildItem -path $scriptRoot -r -file |Where-object{$_.name -match "^$actionss\b" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

&$actionss  -para3 nonlog -para5 "oobe"
stop-process -name WWAHost -Force -ErrorAction SilentlyContinue
stop-process -name WebExperienceHostApp -Force -ErrorAction SilentlyContinue
&$actionss  -para3 nonlog -para5 "oobe_close"

}


### disable windows update ###

Get-Module -name "disable_wu"|remove-module
$mdpath=(Get-ChildItem -path "C:\testing_AI\modules\" -r -file |Where-object{$_.name -match "disable_wu" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global
disable_wu -para1 nolog

do{
   start-sleep -s 2
    $taskexist= Get-ScheduledTask | Where-Object {$_.TaskName -match "Auto_Run" }
   } until( $taskexist )

### initial collecting data ##

if(-not(Test-Path $logspath)){

new-item $logspath -force | Out-Null 

$countcb=0

  ### collecting same info as initial ##

Get-Module -name "initial"|remove-module
$mdpath=(Get-ChildItem -path "C:\testing_AI\modules\" -r -file |Where-object{$_.name -match "initial" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global
initial -para1 nodialog -para2 nolog -para3 nocapture

 ## data moving ##
 
$collectings=(Get-ChildItem -Path $inifd_tcnumber -File |Where-object{$_.LastWriteTime -gt $timenow2}).FullName
$collectings
foreach($collecting in $collectings){
move-Item $collecting -Destination $inifd_ini -Force -ErrorAction SilentlyContinue 
}

write-host "done moving"

  }
  
else{

write-host "wait $waitossec seconds after startup... "
start-Sleep -s $waitossec

if((Get-ChildItem $sysfd -file).count -gt 0){
$errorfoler=(Get-ChildItem $sysfd -file).fullname
$errorfolername=(Get-ChildItem $sysfd -file).name 
$lastfolder=(Get-ChildItem $sysfd -Directory|Sort-Object creationtime|Select-Object -Last 1).name
if(($lastfolder -$errorfolername) -eq 1){
remove-item $errorfoler -Force
rename-item (Get-ChildItem $sysfd -Directory|Sort-Object creationtime|Select-Object -Last 1).fullname -NewName $($errorfolername)
}

else{
remove-item $errorfoler -Force
do{
start-sleep -s 1
new-item -ItemType directory -Path $errorfoler -Force |out-null
start-sleep -s 1
$countcb=(Get-ChildItem $sysfd -Directory).count-1
$countname=split-path -leaf $errorfoler
write-host "folder count $($countcb) ; error folder $($countname)" 

if(($countcb-$countname) -eq 1 ){
remove-item $errorfoler -Force
rename-item (Get-ChildItem $sysfd -Directory|Sort-Object creationtime|Select-Object -Last 1).fullname -NewName $($countname)

}


}until((Get-Item -path $errorfoler).PSisContainer -and $countname -eq $countcb)
write-host "folder $errorfoler missing, re-create ok "
}
}


$countcb=(Get-ChildItem $sysfd -Directory).count-1
$inifd_sysct="$sysfd\$($countcb)"
write-host " #$($countcb) cb checking"

### after shutdown check result ###

write-host "checking #$($countcb) cycle and saving files in  folder name $($inifd_sysct)"

Get-Module -name "initial"|remove-module
$mdpath=(Get-ChildItem -path "C:\testing_AI\modules\" -r -file |Where-object{$_.name -match "initial" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global
initial -para1 nodialog -para2 nolog　-para3 nocapture
 
 ## data moving ##
 
$collectings=(Get-ChildItem -Path $inifd_tcnumber -File |Where-object{$_.LastWriteTime -gt $timenow2}).FullName
$collectings
foreach($collecting in $collectings){
move-Item $collecting -Destination $inifd_sysct -Force -ErrorAction SilentlyContinue 
}

write-host "done moving to $inifd_sysct"


### check DUMP ##

$dumpcheck="FAIL"
$dumpfile="C:Windows\MEMORY.DMP"
$dumplog="C:DumpStack.log"

$checkdmp=test-path $dumpfile
if(!$checkdmp){
$dumpcheck="PASS"
} 
else {   
$newdumpname=$dumpfile.Replace("MEMORY","MEMORY_$($timenow)")
Move-Item $dumpfile $newdumpname -Force
  
if(test-path $dumplog){
$newlogname=$dumplog.Replace("DumpStack","DumpStack_$($timenow)")
Move-Item $dumplog $newlogname -Force
}

Copy-Item $newdumpname $inifd_sysct -Force
Copy-Item $newlogname $inifd_sysct -Force
}


}

#region while loop complete ##

######### remove backup text files  #######

if($countcb -ge $ccount){

write-host "Cycle $countcb finished"

### check logs and file to csv ##

add-content -path $logspath -value "cycle,time_start,time_end,Sys_Check,DRV_Check,YB_Check,APP_Check,Dump_Check"

$cyfoldes=Get-ChildItem -Path $sysfd -directory -Exclude "ini" |Sort-Object {[int]$_.Name}

### compare results ###
$driverfilename1=(Get-ChildItem $inifd_ini\*DriverVersion.csv |Sort-Object lastwritetime |Select-Object -Last 1|Where-object{$_.name -notmatch "all"}).FullName
$old_drivercsv=import-csv -path $driverfilename1|Sort-Object InfName
$old_sysfile= (Get-ChildItem -path $inifd_ini\*SystemInfo.txt|Sort-Object lastwritetime |Select-Object -Last 1).fullname
$old_sys=get-content -path $old_sysfile |Select-Object  -Skip  1  
$old_appfile=(Get-ChildItem $inifd_ini\*AppVersion*.csv|Sort-Object lastwritetime |Select-Object -Last 1).FullName
$old_appcsv=import-csv -path $old_appfile|Sort-Object Name
$old_yb=test-path "$inifd_ini\*yellowbang.csv"

foreach($cyfolde in $cyfoldes){

$inifd_sysct=$cyfolde.fullname
$timestart=get-date((Get-ChildItem $inifd_sysct\*start.jpg|Sort-Object lastwritetime |Select-Object -Last 1 ).LastWriteTime) -Format  "yyyy/M/d HH:mm:ss"
$timeend =get-date((Get-ChildItem $inifd_sysct\*SystemInfo.txt|Sort-Object lastwritetime |Select-Object -Last 1 ).LastWriteTime) -Format  "yyyy/M/d HH:mm:ss"
write-host " check $inifd_sysct"
##driver## 

$fd_count=$cyfolde.name
$driverfilename2=(Get-ChildItem $inifd_sysct\*DriverVersion.csv|Sort-Object lastwritetime |Select-Object -Last 1 |Where-object{$_.name -notmatch "all"}).FullName
$new_drivercsv=import-csv -path $driverfilename2|Sort-Object InfName
$old_yb=test-path "$inifd_ini\*yellowbang.csv"
$drvcheck="FAIL"
$drvdiffc=((Compare-Object $old_drivercsv $new_drivercsv|Where-object{$_.SideIndicator -eq "<=" -or $_.SideIndicator -eq "=>" }).SideIndicator).count
if($drvdiffc -eq 0){$drvcheck="PASS"}

## yellowbang ##
$ybcheck="FAIL"
$new_yb=test-path "$inifd_sysct\*yellowbang.csv"
if($old_yb -eq $false -and $new_yb -eq $false ){
$ybcheck="PASS"
}
else{
$old_ybct=get-content ((Get-ChildItem "$inifd_ini\*yellowbang.csv"|Sort-Object lastwritetime |Select-Object -Last 1).FullName)
$new_ybct=get-content ((Get-ChildItem "$inifd_sysct\*yellowbang.csv" |Sort-Object lastwritetime |Select-Object -Last 1 ).FullName)
$ybdiffc=((Compare-Object $old_ybct $new_ybct|Where-object{$_.SideIndicator -eq "<=" -or $_.SideIndicator -eq "=>" }).SideIndicator).count
if($ybdiffc -eq 0){$ybcheck="PASS"}
}

### system ##
$new_sysfile= (Get-ChildItem $inifd_sysct\*SystemInfo.txt |Sort-Object lastwritetime |Select-Object -Last 1 ).fullname
$new_sys=get-content -path $new_sysfile |Select-Object  -Skip  1  
$syscheck="FAIL"
$sysdiffc=((Compare-Object $old_sys $new_sys|Where-object{$_.SideIndicator -eq "<=" -or $_.SideIndicator -eq "=>" }).SideIndicator).count
if($sysdiffc -eq 0){$syscheck="PASS"}

## APP ##
$new_appfile=(Get-ChildItem -path $inifd_sysct\*AppVersion*.csv|Sort-Object lastwritetime |Select-Object -Last 1).fullname
$new_appcsv=import-csv -path $new_appfile|Sort-Object Name
$appcheck="FAIL"
$appdiffc=((Compare-Object $old_appcsv $new_appcsv|Where-object{$_.SideIndicator -eq "<=" -or $_.SideIndicator -eq "=>" }).SideIndicator).count
if($appdiffc -eq 0){$appcheck="PASS"}

## DUMP ##
$dumpcheck="FAIL"
$dumpfile_new="$inifd_sysct\MEMORY*.DMP"
$dumplog_new="$inifd_sysct\DumpStack.log"

$checkdmp=test-path $dumpfile_new
$checkdmp2=test-path $dumplog_new
if($checkdmp -eq $false -and $checkdmp2 -eq $false) {$dumpcheck="PASS"}

"{0},{1},{2},{3},{4},{5},{6},{7}" -f "","","","","","","","" | add-content -path  $logspath -force  -Encoding  UTF8

$updatelogs=import-csv $logspath -Encoding UTF8 

$updatelogs[-1].cycle="$fd_count"
$updatelogs[-1].time_start=$timestart
$updatelogs[-1].time_end=$timeend
$updatelogs[-1].DRV_Check=$drvcheck
$updatelogs[-1].Sys_Check=$syscheck
$updatelogs[-1].APP_Check=$appcheck
$updatelogs[-1].Dump_Check=$dumpcheck
$updatelogs[-1].YB_Check=$ybcheck

$updatelogs|   export-csv -path  $logspath  -Force -Encoding UTF8 -NoTypeInformation

## fail folder #
if($drvcheck -eq "FAIL" -or $syscheck -eq "FAIL"  -or $appcheck -eq "FAIL" -or $dumpcheck -eq "FAIL"  -or $ybcheck -eq "FAIL"){
$inifd_sysctf=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\$($tcstep)_ipmishutdown\sys\$($fd_count)_fail"
Move-Item -Path $inifd_sysct -Destination $inifd_sysctf -Force
}
}

#########   copy result to main folder  #######

## filter fail #
$failcontents=import-csv $logspath -Encoding UTF8 |Where-object{$_."DRV_Check" -match "fail" -or $_."Sys_Check" -match "fail" -or $_."APP_Check" -match "fail" -or $_."Dump_Check" -match "fail"-or $_."YB_Check" -match "fail"}
if(($failcontents."cycle").Count -ne 0){
$failcontents|   export-csv -path  $faillogspath  -Force -Encoding UTF8 -NoTypeInformation
}


$timenow=get-date -Format "yyMMdd_HHmmss"
$logspath_end=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\$($timenow)_step$($tcstep)_ipmishutdown_cb_result.csv"
$logspath_end2=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\$($timenow)_step$($tcstep)_ipmishutdown_cb_result_fail.csv"
Copy-Item $logspath $logspath_end -Force
if(test-path $faillogspath){Copy-Item$faillogspath  $logspath_end2 -Force}

$results="OK"

$failcsv=import-csv $logspath | Where-Object{$_.DRV_Check -match "Fail" -or $_.Sys_Check -match "Fail" -or $_.YB_Check -match "Fail" -or $_.APP_Check -match "Fail" -or $_.Dump_Check -match "Fail"}
if(($failcsv.Cycle).count -gt 0){$results="NG"}

$index="check $logspath"

######### write log #######
if($nonlog_flag.length -eq 0){

    Get-Module -name "outlog"|remove-module
    $mdpath=(Get-ChildItem -path "C:\testing_AI\modules\"  -r -file |Where-object{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
    Import-Module $mdpath -WarningAction SilentlyContinue -Global

    #write-host "Do $action!"
    outlog $action $results $tcnumber $tcstep $index
}
### remove taskschedule##
#start-process cmd -ArgumentList '/c schtasks /delete /TN "Auto_Run" -f' 
#start-sleep -s 10

}
#endregion

#region while loop not yet complete ##

else{

$newct=$countcb + 1

write-host "# $($newct) cycle starting ..."

## make sure the directory ##

$inifd1=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\$($tcstep)_ipmishutdown\sys\$($newct)\"

do{
start-sleep -s 1
if(test-path $inifd1){remove-item $inifd1 -Recurse -Force -ea SilentlyContinue}
new-item -ItemType directory -Path $inifd1 -Force |out-null
$pathnew=(get-item -path $inifd1).FullName
}until((get-item -path $inifd1).PSisContainer)

write-host "create folder $($pathnew) done"


## check exist task schedule at logon ##

 $taskexist= Get-ScheduledTask | Where-Object {$_.TaskName -match "Auto_Run" }

 if(! $taskexist){

$timeset=[double]1
$TimeSpan = New-TimeSpan -Minutes $timeset
$trigger = New-JobTrigger -AtLogOn -RandomDelay $TimeSpan #00:05:00
#$trigger2 = New-JobTrigger -AtStartup -RandomDelay $TimeSpan #00:05:00

$taskaction = New-ScheduledTaskAction -Execute "C:\testing_AI\AutoRun.bat"
$Stset = New-ScheduledTaskSettingsSet -Priority 0 -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries

$user=[System.Security.Principal.WindowsIdentity]::GetCurrent().Name
$STPrin= New-ScheduledTaskPrincipal   -User "$user"  -RunLevel Highest

Register-ScheduledTask -Action $taskaction -Trigger $trigger -Settings $Stset -Force -TaskName "Auto_Run" -Principal $STPrin

start-sleep -s 10

do{
   start-sleep -s 2
     $taskexist= Get-ScheduledTask | Where-Object {$_.TaskName -like "Auto_Run*" }
   } until( $taskexist )
 
 }
    
write-host "task setting ok"
   
### cold boot entering ###

$idracinfo=(get-content -path "C:\testing_AI\settings\idrac.txt").split(",")
$idracip=$idracinfo[0]
$idracuser=$idracinfo[1]
$idracpwd=$idracinfo[2]

$cmdline="C:\testing_AI\modules\ipmitool1818\ipmitool -I lanplus -H $idracip -U $idracuser -P $idracpwd chassis power status"

$cmdline2="C:\testing_AI\modules\ipmitool1818\ipmitool -I lanplus -H $idracip -U $idracuser -P $idracpwd chassis power cycle"

$cmdline3="ping $idracip"

write-host "Cycle $($newct) is going to run"

function cmdipmi{

do{

$contents=$null

$id0=(Get-Process cmd).Id
start-process cmd -WindowStyle Maximized
start-sleep -s 2
$id2=(Get-Process cmd).Id|Where-object{$_ -notin $id0}
[Microsoft.VisualBasic.interaction]::AppActivate($id2)|out-null

### click cmd window and hit enter###
[Clicker]::LeftClickAtPoint(50, 1)
  start-sleep -s 2
 $wshell.SendKeys("~") 

### send command ## 
 Set-Clipboard "$cmdline"
   start-sleep -s 5
[System.Windows.Forms.SendKeys]::SendWait("^v")
 start-sleep -s 2
 [System.Windows.Forms.SendKeys]::SendWait("~")
  start-sleep -s 2
  $i=0
  do{
    $i++
    Set-Clipboard -Value " "
   [Clicker]::LeftClickAtPoint(1,1)
    start-sleep -s 1
    $wshell.SendKeys("E")
    start-sleep -s 1
    $wshell.SendKeys("S")
    start-sleep -s 1
    $wshell.SendKeys("~")
    start-sleep -s 2
    $contents=Get-Clipboard
    start-sleep -s 5
    $lastline=$contents[-1]
    $lastline2=$lastline.ToString()
    $lastline3=$lastline2.Substring($lastline2.length-1,1)
    
    if($i -gt 10){

      taskkill /F /PID $id2
      start-process cmd -WindowStyle Maximized
      start-sleep -s 2
      $id2=(Get-Process cmd).Id|Where-object{$_ -notin $id0}
      [Microsoft.VisualBasic.interaction]::AppActivate($id2)|out-null
      
      ### click cmd window and hit enter###
      [Clicker]::LeftClickAtPoint(50, 1)
        start-sleep -s 2
       $wshell.SendKeys("~") 
      
      ### send command ## 
       Set-Clipboard "$cmdline"
         start-sleep -s 5
      [System.Windows.Forms.SendKeys]::SendWait("^v")
       start-sleep -s 2
       [System.Windows.Forms.SendKeys]::SendWait("~")
        start-sleep -s 2
        $i=0

    }

    }until( $lastline3 -eq ">")



if($contents -like "*Error*"){

### if fail ###
   
### send command ## 
 Set-Clipboard "$cmdline3"
   start-sleep -s 5
[System.Windows.Forms.SendKeys]::SendWait("^v")
 start-sleep -s 2
 [System.Windows.Forms.SendKeys]::SendWait("~")
  start-sleep -s 10
    
  do{
  
    Set-Clipboard -Value " "
   [Clicker]::LeftClickAtPoint(1,1)
    start-sleep -s 1
    $wshell.SendKeys("E")
    start-sleep -s 1
    $wshell.SendKeys("S")
    start-sleep -s 1
    $wshell.SendKeys("~")
    start-sleep -s 2
    $contents=Get-Clipboard
    start-sleep -s 5
    $lastline=$contents[-1]
    $lastline2=$lastline.ToString()
    $lastline3=$lastline2.Substring($lastline2.length-1,1)

    }until( $lastline3 -eq ">")

        $timenow=get-date -format "yyMMdd_HHmmss"     
        $picfile2=$inifd1+"$($timenow)_error_and_ping.jpg"

        $screen = [System.Windows.Forms.Screen]::PrimaryScreen
        $bounds = $screen.Bounds
        $bmp = New-Object System.Drawing.Bitmap($bounds.Width, $bounds.Height)
        $graphics = [System.Drawing.Graphics]::FromImage($bmp)
        $graphics.CopyFromScreen($bounds.X, $bounds.Y, 0, 0, $bounds.Size)
        $graphics.Dispose()
        $bmp.Save($picfile2)
        start-sleep -s 2
        $graphics.Dispose()
        $bmp.Dispose()        
        
   taskkill /F /PID $id2

}

}until(!($contents  -like "*Error*"))

 Set-Clipboard "$cmdline2"
  start-sleep -s 5
[System.Windows.Forms.SendKeys]::SendWait("^v")
 start-sleep -s 2

 ### screenshot##
   
        $timenow=get-date -format "yyMMdd_HHmmss"     
        $picfile=$inifd1+"$($timenow)_start.jpg"

        $screen = [System.Windows.Forms.Screen]::PrimaryScreen
        $bounds = $screen.Bounds
        $bmp = New-Object System.Drawing.Bitmap($bounds.Width, $bounds.Height)
        $graphics = [System.Drawing.Graphics]::FromImage($bmp)
        $graphics.CopyFromScreen($bounds.X, $bounds.Y, 0, 0, $bounds.Size)
        $graphics.Dispose()
        $bmp.Save($picfile)
        start-sleep -s 2
        $graphics.Dispose()
        $bmp.Dispose()        
     
    start-sleep -s $waitbfcssec
 
 [System.Windows.Forms.SendKeys]::SendWait("~")

 # & invoke-Expression "$cmdline"

  start-sleep -s 20

  }

 do{

  cmdipmi

  ## if fail to shutdown ##

   [Clicker]::LeftClickAtPoint(1,1)
    start-sleep -s 1
    $wshell.SendKeys("E")
    start-sleep -s 1
    $wshell.SendKeys("S")
    start-sleep -s 1
    $wshell.SendKeys("~")
    start-sleep -s 1
    $contents2=Get-Clipboard
    start-sleep -s 5


}until ( $contents2 -match "IPMI LAN send command failed")
            
exit

}

#endregion

 }
 

    export-modulemember -Function ipmitool_shutdown

<##
    #(Get-ChildItem C:\Users\MG_W251\Desktop\logs\TC-120562\6_ipmishutdown\sys -directory).FullName|Where-object{(Get-ChildItem $_ -file).count -eq 0}
    (Get-ChildItem C:\Users\MG_W251\Desktop\logs\TC-120562\6_ipmishutdown\sys -directory).FullName|Where-object{(Get-ChildItem $_ -file).count -eq 0}|remove-item -Force
$folders=((Get-ChildItem C:\Users\MG_W251\Desktop\logs\TC-120562\6_ipmishutdown\sys -directory -Exclude "*ini*")|Sort-Object {[int64]($_.Name)}).FullName

foreach($folder in $folders){
$folders2=((Get-ChildItem C:\Users\MG_W251\Desktop\logs\TC-120562\6_ipmishutdown\sys -directory -Exclude "*ini*")|Sort-Object {[int64]($_.Name)}).FullName

$index=$folders2.indexof($folder)
$fdname=Split-Path -Leaf $folder

if($fdname -ne $index+1){
write-host "rename $folder as $($index+1)"

Rename-Item $folder -NewName $($index+1)
}
}
#>