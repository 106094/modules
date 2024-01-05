

function getcursor_coor ([int]$para1,[int]$para2,[string]$para3){

    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force;
    $wshell=New-Object -ComObject wscript.shell
      Add-Type -AssemblyName Microsoft.VisualBasic
      Add-Type -AssemblyName System.Windows.Forms
      Add-Type -AssemblyName System.Windows.Forms,System.Drawing
    #import mouse_event
    Add-Type -MemberDefinition '[DllImport("user32.dll")] public static extern void mouse_event(int flags, int dx, int dy, int cButtons, int info);' -Name U32 -Namespace W;
   # 6 is 0x02 | 0x04, LMBDown | LMBUp from the documentation
   ## https://msdn.microsoft.com/en-us/library/windows/desktop/ms646260(v=vs.85).aspx

$paracheck1=$PSBoundParameters.ContainsKey('para1')
$paracheck2=$PSBoundParameters.ContainsKey('para2')
$paracheck3=$PSBoundParameters.ContainsKey('para3')

if($paracheck1 -eq $false -or $para1 -eq 0){
$para1=0
}
if($paracheck2 -eq $false -or $para2 -eq 0){
$para2= 0
}
if($paracheck3 -eq $false -or $para3.length -eq 0){
$para3=""
}

$shift_x=$para1
$shift_y=$para2
$nonlog=$para3

$coor_x=[System.Windows.Forms.Cursor]::Position.X+$shift_x
$coor_y=[System.Windows.Forms.Cursor]::Position.Y+$shift_y


if($PSScriptRoot.length -eq 0){
$scriptRoot="C:\testing_AI\modules"
}
else{
$scriptRoot=$PSScriptRoot
}
$tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
$tcnumber=((get-content $tcpath).split(","))[0]
$tcstep=((get-content $tcpath).split(","))[1]

$picpath=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\"
if(-not(test-path $picpath)){new-item -ItemType directory -path $picpath |out-null}
$coorlog=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\coor.txt"

#$width  = (([string]::Join("`n", (wmic path Win32_VideoController get CurrentHorizontalResolution))).split("`n") -match "\d{1,}")[0]
#$height  = (([string]::Join("`n", (wmic path Win32_VideoController get CurrentVerticalResolution))).split("`n") -match "\d{1,}")[0]


$actionmd="screenshot"
Get-Module -name $actionmd|remove-module
$mdpath=(Get-ChildItem -path $scriptRoot -r -file |?{$_.name -match "^$actionmd\b" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

$screen = [System.Windows.Forms.Screen]::PrimaryScreen
$bounds = $screen.Bounds
$width  = $bounds.Width
$height = $bounds.Height


Set-Content $coorlog -Value "$coor_x,$coor_y" -Force

## screen shot ##

&$actionmd  -para3 nonlog -para5 "cursorcheck"


if(test-path $coorlog){
$results="OK"
$index="X:$coor_x Y:$coor_y"
}
else{
$results="NG"
$index="save log fail"
}

######### write log #######

if($nonlog.Length -eq 0){
#Write-Host "errorcode is $errorcodeis, $action, $results"

Get-Module -name "outlog"|remove-module
$mdpath=(Get-ChildItem -path "C:\testing_AI\modules\"  -r -file |?{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

#write-host "Do $action!"
outlog $action $results $tcnumber $tcstep $index

}

  }

    export-modulemember -Function getcursor_coor


   
