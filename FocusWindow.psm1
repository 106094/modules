

function FocusWindow ([string]$para1){
    
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

$action="Focus window"
$tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
$tcnumber=((get-content $tcpath).split(","))[0]
$tcstep=((get-content $tcpath).split(","))[1]
$logpath="C:\testing_AI\logs\$($tcnumber)"
if( -not(test-path  $logpath )){new-item -ItemType directory  $logpath -Force -ea SilentlyContinue |out-null}

$appname = $para1
   # 根据进程名获取进程对象
$process = Get-Process -Name $appname

# 获取主窗口句柄
$windowHandle = $process.MainWindowTitle

# 使用 User32.dll 中的函数来激活窗口
Add-Type -TypeDefinition @"
    using System;
    using System.Runtime.InteropServices;

    public static class User32 {
        [DllImport("user32.dll", SetLastError = true)]
        public static extern IntPtr FindWindow(string lpClassName, string lpWindowName);

        [DllImport("user32.dll")]
        [return: MarshalAs(UnmanagedType.Bool)]
        public static extern bool SetForegroundWindow(IntPtr hWnd);
    }
"@ 

$hWnd = [User32]::FindWindow([NullString]::Value, $windowHandle)


if ($hWnd -ne [IntPtr]::Zero) {
    [User32]::SetForegroundWindow($hWnd)
}

  
######### write log #######
Get-Module -name "outlog"|remove-module
$mdpath=(Get-ChildItem -path "C:\testing_AI\modules\"  -r -file |Where-object{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global
#write-host "Do $action!"
outlog $action $results $tcnumber $tcstep $index
}

    export-modulemember -Function FocusWindow