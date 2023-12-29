

function diskpart_cmdline ([string]$para1,[string]$para2,[string]$para3,[string]$para4,[string]$para5){
      
    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force;
    $wshell=New-Object -ComObject wscript.shell
     $shell=New-Object -ComObject shell.application
      Add-Type -AssemblyName Microsoft.VisualBasic
        Add-Type -AssemblyName System.Windows.Forms,System.Drawing    

    $dpcmdline=$para1
    $disktype=$para2
    $raidtype=$para3
    $assingletter=$para4
    $nonlog_flag=$para5

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

$picpath=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\"
if(-not(test-path $picpath)){new-item -ItemType directory -path $picpath |out-null}
$logpath=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\step$($tcstep)_diskpart.txt"
new-item $logpath -Force |Out-Null

$results="OK"
$index="check diskpart content"

function diskpcmd($diskpcmds){
$diskpcmds|Out-String|add-content -path $logpath
$diskpcmds|diskpart|add-content -path $logpath
}


#region get working diskid handling


#os disk id
$osdisk=((Get-partition)|?{$_.DriveLetter -eq "C"}).Disknumber
$diskall=(Get-PhysicalDisk).DeviceId|?{$_ -ne $osdisk}
$ssddisks = (Get-PhysicalDisk | Where-Object { $_.MediaType -eq 'SSD' }).DeviceId

#usbdiskid
$useuid=(Get-Disk | Where-Object -FilterScript {$_.Bustype -Eq "USB"}).UniqueId
if($useuid){
$useuid2=$useuid.substring($useuid.length -10,10)
$usbletter=(Get-Partition|?{$_.uniqueid -match $useuid2}).DriveLetter|?{$_}
$usedisk=((Get-partition)|?{$_.DriveLetter -in $usbletter}).Disknumber|Get-Unique
$diskall=(Get-PhysicalDisk).DeviceId|%{
if(!($_ -in $osdisk -or $_ -in $usedisk)){
$_
}

}
}

write-host "All disk is $diskall"

$hddiskall=(Get-PhysicalDisk).DeviceId|%{
if(!($_ -in $osdisk -or $_ -in $usedisk -or  $_ -in $ssddisks)){
$_
}
}

if($hddiskall.count -gt 0){write-host "HD disk is $hddiskall"}

$ssddiskall=$ssddisks|%{
if(!($_ -in $osdisk -or $_ -in $usedisk -or  $_ -in $hddiskall)){
$_
}
}
if($ssddiskall.count -gt 0){write-host "SSD disk is $ssddiskall"}

if($disktype -match "HD"){
$diskall=$hddiskall
write-host "action disk ($disktype) is $diskall"
}

if($disktype -match "SSD"){
$diskall=$ssddiskall
write-host "action disk ($disktype) is $diskall"
}

if($diskall.count -gt 1){
$disk1=$diskall[0]
$disk2=$diskall[1]
$disk3=$diskall[2]
$disk4=$diskall[3]
$disk5=$diskall[4]
$disk6=$diskall[5]
$disk7=$diskall[6]
$disk8=$diskall[7]
}
if($diskall.count -eq 1){
$disk1=$diskall
}
#endregion

#region get vol # if need later

if($assingletter.Length -gt 0){

$diskmattext="\s"+$assingletter+"\s"
$volinfo="list volume"|diskpart
  $volinfo1=$volinfo -match $diskmattext
  $volno=(($volinfo1.split(" "))|?{$_.length -gt 0})[1]

  write-host "the disk $($assingletter) belongs to volume $($volno)"

}

#endregion

#region define command set

$ini_clngpt=@("select disk #", "clean","convert gpt")

$ini_clndynamic=@("select disk #", "clean","convert dynamic")

$ini_clndynamic=@("select disk #", "clean","convert dynamic")

#$fmtntfs=@("select disk #","create volume simple","select volume","format fs=ntfs quick")
$fmtntfs=@("select disk #","create partition primary","format fs=ntfs quick","assign letter=##")

$fmtntfs_512g=@("select disk #","create partition primary size=512000","format fs=ntfs quick","assign letter=##")

#$size1=([int64]((Get-CimInstance -ClassName Win32_LogicalDisk).Size/1GB)-7)*1024

$pardisk=@("select disk #","clean","convert gpt","list disk",`
"create partition primary size=#size","format fs=ntfs quick","assign letter=D",`
"create partition primary size=2048","format fs=fat quick","assign letter=E",`
"create partition primary size=4096","format fs=fat32 quick","assign letter=F",`
"create partition primary size=1024","format fs=ntfs quick","assign letter=G","list volume")

$add1v_ext23=@("select disk $($disk1)","create volume simple size=170667 disk=$($disk1) ",`
"select volume 3","extend disk $($disk2) size=170667","extend disk $($disk3) size=170667","assign letter=D",`
"format fs=ntfs quick","list volume")

$stripedisk=@("list volume","select volume $($volno)","format fs=ntfs quick",`
"delete volume","list disk","select disk $($disk1)",`
"create volume stripe disk=$($disk1),$($disk2),$($disk3) size= 512000",`
"assign letter=D","format fs=ntfs quick","list volume")

$detdisk=@("list disk","select disk #","det disk")

$diskpcmds=$dpcmdline

if( $dpcmdline -match "ini"){
$diskpcmds=$ini_clngpt
}
if( $dpcmdline -match "dynamic"){
$diskpcmds=$ini_clndynamic
}
if( $dpcmdline -match "ntfs\b"){
$diskpcmds=$fmtntfs
}
if( $dpcmdline -match "det"){
$diskpcmds=$detdisk
}
if( $dpcmdline -match "pardisk"){
$diskpcmds=$pardisk
}
if( $dpcmdline -match "add1v_ext23"){
$diskpcmds=$add1v_ext23
}
if( $dpcmdline -match "stripe"){
$diskpcmds=$stripedisk
}

if( $dpcmdline -match "ntfs512"){
$diskpcmds=$fmtntfs_512g
}

#endregion

#region raid type handling
if($raidtype.length -ne 0){

$raidmappinglog=(gci $picpath -Filter "*raidmapping.txt"|sort lastwritetime|select -Last 1).fullname

if($raidmappinglog){
$raidcontent=get-content $raidmappinglog

foreach($raidline in $raidcontent){
$diskraid=(($raidline.split(","))[3]) -replace "DISK ",""

if($raidline -match "non"){
$disknonraid=$disknonraid+@($diskraid)
}
if($raidline -match "RAID-1\b"){
$diskraid1=$diskraid1+@($diskraid)
}
if($raidline -match "RAID-0"){
$diskraid0=$diskraid0+@($diskraid)
}
if($raidline -match "RAID-5"){
$diskraid5=$diskraid5+@($diskraid)
}
if($raidline -match "RAID-10"){
$diskraidten=$diskraidten+@($diskraid)
}
}
$allraiddisk=$disknonraid+$diskraid1+$diskraid0+$diskraid5+$diskraidten

if($raidtype -match "non" -and $disknonraid.Count -gt 0){
$diskall=$disknonraid
write-host "NonRaid disk is $diskall"
}

if($raidtype -match "RAID" -and $raidtype -match "\-0\b" -and $diskraid0.Count -gt 0){
$diskall=$diskraid0
write-host "raid0 disk is $diskall"
}
if($raidtype -match "RAID" -and $raidtype -match "\-1\b" -and $diskraid1.Count -gt 0){
$diskall=$diskraid1
write-host "raid1 disk is $diskall"
}
if($raidtype -match "RAID" -and $raidtype -match "\-5\b" -and $diskraid5.Count -gt 0){
$diskall=$diskraid5
write-host "raid5 disk is $diskall"
}
if($raidtype -match "RAID" -and $raidtype -match "\-10\b" -and $diskraidten.Count -gt 0){
$diskall=$diskraidten
write-host "raid10 disk is $diskall"
}

<#
if($raidtype -match "non"){
if(($diskall|sort|Out-String) -eq ($allraiddisk|sort|Out-String)){
$diskall=""
$results="NG"
$index="No non-raid disk is found"
}
else{
$diskall=$diskall|?{$_ -notin $allraiddisk}
write-host "non-raid disk is $diskall"
}

}
#>
}
else{
$results="NG"
$index="no raid mapping info"
}

}
#endregion

if($results -ne "NG"){

if($diskall.count -gt 0){
#get list disk#

diskpcmd "list disk"

# diskpart cmd start#

if($dpcmdline.length -gt 0){
    if ($dpcmdline -match "add1v_ext23" -or $dpcmdline -match "stripe"){
        diskpcmd $diskpcmds
    }
    else{
        foreach($disknu in $diskall){
            $diskpcmds_new=$diskpcmds.replace("##",$assingletter)
            $size1 = (((Get-Disk -Number $disknu).Size/1GB)-8)*1024
            $diskpcmds_new=$diskpcmds_new.replace("#size",$size1)
            $diskpcmds_new=$diskpcmds_new.replace("#",$disknu)
            diskpcmd $diskpcmds_new
        }
}

#get list disk at the end again#
diskpcmd "list disk"
}

if($assingletter.Length -gt 0){
    $actionfexp="filexplorer"
    Get-Module -name $actionfexp|remove-module
    $mdpath=(gci -path $scriptRoot -r -file |?{$_.name -match "^$actionfexp\b" -and $_.name -match "psm1"}).fullname
    Import-Module $mdpath -WarningAction SilentlyContinue -Global
    $openpath=$assingletter+":\"
    &$actionfexp -para1  $openpath -para2 nonlog

}
}

else{
$results="NG"
$index="No matching disk is found"
}
}
Write-Host "$results, $index"

$dpcontents=get-content -path $logpath
if($dpcontents.Length -eq 0){
remove-item $logpath -Force
}

 ### close file explore windows

 $shell.Windows() |?{$_.name -eq "File Explorer"}| ForEach-Object { $_.Quit() }

######### write log #######

if($nonlog_flag.Length -eq 0){
Get-Module -name "outlog"|remove-module
$mdpath=(gci -path "C:\testing_AI\modules\"  -r -file |?{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

#write-host "Do $action!"
outlog $action $results $tcnumber $tcstep $index
}


   }

    export-modulemember -Function diskpart_cmdline