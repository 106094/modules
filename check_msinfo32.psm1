function check_msinfo32 ([string]$para1,[string]$para2){
      
    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force;
    #$wshell=New-Object -ComObject wscript.shell
      Add-Type -AssemblyName Microsoft.VisualBasic
      Add-Type -AssemblyName System.Windows.Forms
      Add-Type -AssemblyName System.Windows.Forms,System.Drawing
      
if($PSScriptRoot.length -eq 0){
$scriptRoot="C:\testing_AI\modules"
}
else{
$scriptRoot=$PSScriptRoot
}

$outlogtype=$para1
$nonlog_flag=$para2

$action="check_msinfo32"
$tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
$tcnumber=((get-content $tcpath).split(","))[0]
$tcstep=((get-content $tcpath).split(","))[1]
$picpath=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\"
if(-not(test-path $picpath)){new-item -ItemType directory -path $picpath |out-null}
$mslog=$picpath+"step$($tcstep)_msinfo.$($outlogtype)"

$results="NG"
$index="fail to open msinfo32"

#get report #
if($outlogtype -match "txt"){
Start-Process 'C:\Windows\System32\msinfo32.exe' -ArgumentList '/report', $mslog -Wait
}
if($outlogtype -match "nfo"){
Start-Process 'C:\Windows\System32\msinfo32.exe' -ArgumentList '/nfo', $mslog -Wait 
}

$actionss="screenshot"
Get-Module -name $actionss|remove-module
$mdpath=(Get-ChildItem -path $scriptRoot -r -file |Where-object{$_.name -match "^$actionss\b" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

#screenshots
start-process msinfo32
Start-Sleep -s 10
    
$process = Get-Process -name msinfo32  

if ($process) {
    
    $results="OK"
    $index="check screenshots"
   
# Define the ShowWindow function from the user32.dll
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class Win32ShowWindow {
    [DllImport("user32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
}
"@
# Maximize the window
[Win32ShowWindow]::ShowWindow($process.MainWindowHandle, 3) # 3 is for SW_MAXIMIZE
Start-Sleep -s 2
[System.Windows.Forms.SendKeys]::SendWait("{tab}")
Start-Sleep -s 2
       
## screen capture ##

    &$actionss  -para3 nonlog -para5 "1"
    [System.Windows.Forms.SendKeys]::SendWait("{PGDN}")
    Start-Sleep -s 5      
    &$actionss  -para3 nonlog -para5 "2"
    [System.Windows.Forms.SendKeys]::SendWait("{PGDN}")
    Start-Sleep -s 5       
    &$actionss  -para3 nonlog -para5 "3"
    (Get-Process -name msinfo32).CloseMainWindow()

}


######### write log  #######

if($nonlog_flag.Length -eq 0){
Get-Module -name "outlog"|remove-module
$mdpath=(Get-ChildItem -path "C:\testing_AI\modules\"  -r -file |Where-object{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

#write-host "Do $action!"
outlog $action $results $tcnumber $tcstep $index

}

}

  
    export-modulemember -Function check_msinfo32