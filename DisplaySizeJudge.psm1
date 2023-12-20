function DisplaySizeJudge([int]$para1,[int]$para2){
    $paracheck1=$PSBoundParameters.ContainsKey('para1')
    $paracheck2=$PSBoundParameters.ContainsKey('para2')
    
    if($paracheck1 -eq $false -or  $para1 -eq 0){
        $para1= [int]1920
    }
    
    if($paracheck2 -eq $false -or  $para2 -eq 0){
        $para2= [int]1080
    }

    $width = [int]$para1
    $height = [int]$para2
    

    if($PSScriptRoot.length -eq 0){
        $scriptRoot="C:\testing_AI\modules\"
    }
    else{
        $scriptRoot=$PSScriptRoot
    }


    $tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
    $tcnumber=((get-content $tcpath).split(","))[0]
    $tcstep=((get-content $tcpath).split(","))[1]

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

    $screen = [System.Windows.Forms.Screen]::PrimaryScreen
    $bounds = $screen.Bounds

    $currentDPI = (Get-ItemProperty -Path "HKCU:\Control Panel\Desktop\WindowMetrics" -Name AppliedDPI).AppliedDPI

    $dpisets=@(96,120,144,168)
    $sclsets=@(100,125,150,175)

    $index = $dpisets.IndexOf($currentDPI)
    $calcu = $sclsets[$index] /100

    $bounds.Width = $curwidth * $calcu
    $bounds.Height = $curheight * $calcu

    if($bounds.Width -ge $width -and $bounds.Height -ge $height){
        $results = "OK"
        $index="monitor size check complete"
    }else{
        $results = "NG"
        $index="monitor size less than $width*$height"
    }



    
    #output log
    Get-Module -name "outlog"|remove-module
    $mdpath=(gci -path "C:\testing_AI\modules\" -r -file |?{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
    Import-Module $mdpath -WarningAction SilentlyContinue -Global
    #write-host "Do $action!"
    outlog $action $results $tcnumber $tcstep $index

}

Export-ModuleMember -Function DisplaySizeJudge