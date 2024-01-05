
function　kb_update ([string]$para1,[string]$para2){
      
    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force;
    $wshell=New-Object -ComObject wscript.shell
      Add-Type -AssemblyName Microsoft.VisualBasic
      Add-Type -AssemblyName System.Windows.Forms
      Add-Type -AssemblyName System.Windows.Forms,System.Drawing
                      
$paracheck=$PSBoundParameters.ContainsKey('para1')
$paracheck2=$PSBoundParameters.ContainsKey('para2')

if( $paracheck -eq $false -or $para1.length -eq 0 ){
#write-host "no defined, setting 1 min after login"
$para1=""
}

if( $paracheck2 -eq $false -or $para2.length -eq 0 ){
#write-host "no defined, setting 1 min after login"
$para2=""
}


if($PSScriptRoot.length -eq 0){
$scriptRoot="C:\testing_AI\modules"
}
else{
$scriptRoot=$PSScriptRoot
}

$KBname=$para1
$nonlog_flag=$para2

#$width  = (([string]::Join("`n", (wmic path Win32_VideoController get CurrentHorizontalResolution))).split("`n") -match "\d{1,}")[0]
#$height  = (([string]::Join("`n", (wmic path Win32_VideoController get CurrentVerticalResolution))).split("`n") -match "\d{1,}")[0]

$action="KB_update"
$tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
$tcnumber=((get-content $tcpath).split(","))[0]
$tcstep=((get-content $tcpath).split(","))[1]

$picpath=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\"
if(-not(test-path $picpath)){new-item -ItemType directory -path $picpath |out-null}
$timenow=get-date -format "yyMMdd_HHmmss"
$kbupdateinfo=$picpath+"$($timenow)_step$($tcstep)_KBlist_before.txt"

$actionss ="screenshot"
Get-Module -name $actionss|remove-module
$mdpath=(Get-ChildItem -path $scriptRoot -r -file |Where-object{$_.name -match "^$actionss\b" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global


$timenow=get-date -format "yyMMdd_HHmmss"
$kbupdateinfo=$picpath+"$($timenow)_step$($tcstep)_KBlist_before.txt"

Get-HotFix|out-string|set-content $kbupdateinfo


## kb_update ##

if($KBname.Length -eq 0){
$kbfiles=(Get-ChildItem $picpath -r -filter "*.msu").FullName
}
else{
$kbfiles=(Get-ChildItem $picpath -r -filter "*.msu"|Where-object{$_.name -match $KBname}).FullName
}


foreach($kbfile in $kbfiles){

$kbcmd="START /WAIT WUSA $kbfile /QUIET /NORESTART"

 $id0=(Get-Process cmd).Id
set-location "C:/dash/tools/$($pl)/"
  
start-process cmd -WindowStyle Maximized
start-sleep -s 3
$id3=(Get-Process cmd).Id|Where-object{$_ -notin $id0}

[Microsoft.VisualBasic.interaction]::AppActivate($id3)|out-null
start-sleep -s 3

Set-Clipboard -value $kbcmd
Start-Sleep -Seconds 5

[Clicker]::LeftClickAtPoint(50, 1)
Start-Sleep -Seconds 2
$wshell.SendKeys("~") 
Start-Sleep -Seconds 2
$wshell.SendKeys("^v")
Start-Sleep -Seconds 2
$wshell.SendKeys("~")
Start-Sleep -Seconds 2

do{
start-sleep -s 5
$wusacount=((get-process -name WUSA -ea SilentlyContinue).Id).count
}until($wusacount -eq 0)

        $timenow=get-date -format "yyMMdd_HHmmss"    
        $kbname=(split-path -Leaf $kbfile).replace(".msu","") -match "KB\d{1,}"
        $kbname2=$matches[0]

        ##screenshot##
        &$actionss  -para3 nonlog -para5 "$($kbname2)_install_complete"

                
        taskkill /PID $id3 /F 

}



Get-HotFix|out-string|set-content $kbupdateinfo2
$kbcontent=get-content $kbupdateinfo2

$results="NG"
$index="$kbname2 update failed"

$timenow=get-date -format "yyMMdd_HHmmss"
$kbupdateinfo2=$picpath+"$($timenow)_step$($tcstep)_KBlist_after_fail.txt"
$updateevent=$index
if($kbcontent -match $kbname2 ){
$results="OK"
$index="check $kbupdateinfo2"
$kbupdateinfo2=$picpath+"$($timenow)_step$($tcstep)_KBlist_after_pass.txt"
$updateevent=(get-content "C:\Windows\SoftwareDistribution\ReportingEvents.log" -match $kbname2)|Out-String
}

set-content -path $kbupdateinfo2 -Value $updateevent -Force

######### write log  #######

if($nonlog_flag.Length -eq 0){
Get-Module -name "outlog"|remove-module
$mdpath=(Get-ChildItem -path "C:\testing_AI\modules\"  -r -file |Where-object{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

#write-host "Do $action!"
outlog $action $results $tcnumber $tcstep $index

  }

  }

  
    export-modulemember -Function kb_update