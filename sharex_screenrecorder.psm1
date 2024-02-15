
function sharex_screenrecorder ([int64]$para1,[string]$para2,[string]$para3){
    
  Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force;
  $wshell=New-Object -ComObject wscript.shell
    Add-Type -AssemblyName Microsoft.VisualBasic
    Add-Type -AssemblyName System.Windows.Forms
 

$paracheck=$PSBoundParameters.ContainsKey('para1')
$paracheck2=$PSBoundParameters.ContainsKey('para2')
$paracheck3=$PSBoundParameters.ContainsKey('para3')

if( $paracheck -eq $false -or $para1 -eq 0 ){
#write-host "no defined, setting 1 min after login"
$para1=30
}
if( $paracheck2 -eq $false -or $para2.Length -eq 0 ){
#write-host "no defined, setting 1 min after login"
$para2=""
}
if( $paracheck3 -eq $false -or $para3.Length -eq 0 ){
#write-host "no defined, setting 1 min after login"
$para3=""
}

if($PSScriptRoot.length -eq 0){
$scriptRoot="C:\testing_AI\modules"
}
else{
$scriptRoot=$PSScriptRoot
}

$recordtime=$para1
$indexname=$para2
$nonlogflag=$para3


$action="screenrecoder(shareX)"

$tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
$tcnumber=((get-content $tcpath).split(","))[0]
$tcstep=((get-content $tcpath).split(","))[1]

$picpath=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\"
if(-not(test-path $picpath)){new-item -ItemType directory -path $picpath |out-null}

$reclog=$picpath+"step$($tcstep)_recorder.mp4" 
if($indexname.length -ne 0){
$reclog=$picpath+"step$($tcstep)_$($indexname)_recorder.mp4"
}  

$results="OK"

#region check file and install

$configpath="$env:userprofile\Documents\ShareX\ApplicationConfig.json"
$exefilepath="C:\Program Files\ShareX\ffmpeg.exe"

if (!(test-path $configpath) -or (test-path $exefilepath)){

$sharexinstallexe="C:\testing_AI\modules\shareX\ShareX-15.0.0-setup.exe"

if(test-path $sharexinstallexe){

&$sharexinstallexe /verysilent

do{
Start-Sleep -s 5
$checkrun=get-process -name ShareX -ErrorAction SilentlyContinue
}until($checkrun)

Start-Sleep -s 5
$checkrun.CloseMainWindow()
Start-Sleep -s 2

}
else{
$results="NG"
$index="cannot find install exe file"
}

}

#endregion


if($results -ne "NG"){
#region modify settings json and run
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class PInvoke {
  [DllImport("user32.dll")] public static extern IntPtr GetDC(IntPtr hwnd);
  [DllImport("gdi32.dll")] public static extern int GetDeviceCaps(IntPtr hdc, int nIndex);
}
"@
$hdc = [PInvoke]::GetDC([IntPtr]::Zero)
$curwidth = [PInvoke]::GetDeviceCaps($hdc, 118) # width
$curheight = [PInvoke]::GetDeviceCaps($hdc, 117) # height

#$screen = [System.Windows.Forms.Screen]::PrimaryScreen
#$bounds = $screen.Bounds

$currentDPI = (Get-ItemProperty -Path "HKCU:\Control Panel\Desktop\WindowMetrics" -Name AppliedDPI).AppliedDPI

$dpisets=@(96,120,144,168)
$sclsets=@(100,125,150,175)

$index = $dpisets.IndexOf($currentDPI)
$calcu = $sclsets[$index] /100

$bWidth = $curwidth * $calcu
$bHeight = $curheight * $calcu

<# revise config json file
$jsoncontents=get-content $configpath
$lineafterjob="""CopyImageToClipboard, SaveImageToFile"","
$lineaudio="""virtual-audio-capturer"","
$lineres= """0, 0, $($bWidth), $($bHeight)"","

$newcontent=foreach($line in $jsoncontents){

if($line -match """AfterCaptureJob"""){
$line=($line -split "\:")[0] + ": "+$lineafterjob
}

if($line -match  """AudioSource"""){
$line=($line -split "\:")[0] + ": "+$lineaudio
}
if($line -match "ScreenRecordRegion"){
$line=($line -split "\:")[0] + ": "+$lineres
}

$line
}

$newcontent|set-content $configpath -Force
&$exefilepath  -startscreenrecorder -silent
Start-Sleep -s $recordtime
&$exefilepath  -startscreenrecorder -silent -autoclose

#>

#endregion

#region start recording
$size="$($bWidth)x$($bHeight)"

&$exefilepath -hide_banner -f gdigrab -thread_queue_size 1024 -rtbufsize 256M -framerate 30 -offset_x 0 -offset_y 0 -video_size $size -draw_mouse 1 -i desktop -c:v libx264 -r 30 -preset ultrafast -t $($recordtime) -tune zerolatency -crf 28 -pix_fmt yuv420p -movflags +faststart -y "$reclog"

#endregion
start-sleep -s 10

if(test-path $reclog){
$results="OK"
$index="check the recorded mp4 file"
}



if(!(Test-Path $reclog)){
$results="NG"
$index="fail to get mp4 file"
}

}


######### write log #######

if($nonlogflag.Length -eq 0){

Get-Module -name "outlog"|remove-module
$mdpath=(Get-ChildItem -path "C:\testing_AI\modules\"  -r -file |Where-object{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

#write-host "Do $action!"
outlog $action $results $tcnumber $tcstep $index

}

}

  export-modulemember -Function sharex_screenrecorder