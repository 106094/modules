function　add_web_credential ([string]$para1,[string]$para2,[string]$para3,[string]$para4){
      
    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force;
    $wshell=New-Object -ComObject wscript.shell
      Add-Type -AssemblyName Microsoft.VisualBasic
      Add-Type -AssemblyName System.Windows.Forms
      Add-Type -AssemblyName System.Windows.Forms,System.Drawing


$paracheck1=$PSBoundParameters.ContainsKey('para1')
$paracheck2=$PSBoundParameters.ContainsKey('para2')
$paracheck3=$PSBoundParameters.ContainsKey('para3')
$paracheck4=$PSBoundParameters.ContainsKey('para4')

if($paracheck1 -eq $false -or $para1.Length -eq 0){
$para1=""
}
if($paracheck2 -eq $false -or $para2.Length -eq 0){
$para2=""
}
if($paracheck3 -eq $false -or $para3.Length -eq 0){
$para3=""
}
if($paracheck4 -eq $false -or $para4.Length -eq 0){
$para4=""
}

$targetpath=$para1
$usernm=$para2
$passwd=$para3
$nonlog_flag=$para4



if($PSScriptRoot.length -eq 0){
$scriptRoot="C:\testing_AI\modules"
}
else{
$scriptRoot=$PSScriptRoot
}

if($targetpath.length -eq 0 -or $usernm.length -eq 0 -or $passwd.length -eq 0){
$results="NG"
$index="no define settings"
}
else{

$action="Create_SystemImage_by ControlPanel"
$tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
$tcnumber=((get-content $tcpath).split(","))[0]
$tcstep=((get-content $tcpath).split(","))[1]

$width  = (([string]::Join("`n", (wmic path Win32_VideoController get CurrentHorizontalResolution))).split("`n") -match "\d{1,}")[0]
$height  = (([string]::Join("`n", (wmic path Win32_VideoController get CurrentVerticalResolution))).split("`n") -match "\d{1,}")[0]

$picpath=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\"
if(-not(test-path $picpath)){new-item -ItemType directory -path $picpath |out-null}


$secpasswd = ConvertTo-SecureString $passwd -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential ($usernm, $secpasswd)

cmdkey /add:$targetpath /user:$usernm /pass:$passwd
Start-Sleep -s 5
$checkcd= (cmdkey /list) -match $targetpat
if($checkcd){
$results="OK"
$index=$checkcd
}
else{
$results="NG"
$index="fail to setup $targetpat credential"
}
######### write log  #######

if($nonlog_flag.Length -eq 0){
Get-Module -name "outlog"|remove-module
$mdpath=(gci -path "C:\testing_AI\modules\"  -r -file |?{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

#write-host "Do $action!"
outlog $action $results $tcnumber $tcstep $index

  }

  }


  }

  
    export-modulemember -Function add_web_credential