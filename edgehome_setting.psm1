

function edgehome_setting ([string]$para1){
 
  Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force;
    $wshell=New-Object -ComObject wscript.shell
      Add-Type -AssemblyName Microsoft.VisualBasic
      Add-Type -AssemblyName System.Windows.Forms
      
$paracheck1=$PSBoundParameters.ContainsKey('para1')

if($paracheck1 -eq $false -or $para1.Length -eq 0){

[System.Windows.Forms.MessageBox]::Show($this,"No initial Web address provided (para1). Testing is stopped.")   
exit

}

$url=$para1

### edge initialization ####

$winv= ([System.Environment]::OSVersion.Version).Build

Start-Process msedge.exe
start-sleep -s 30

 $id=(Get-Process msedge |?{($_.MainWindowTitle).length -gt 0}).Id

[Microsoft.VisualBasic.interaction]::AppActivate($id)|out-null


<##

if ($winv -ge 22000 -and $wshell.AppActivate('New tab - Profile 1') -eq $true ){

[Microsoft.VisualBasic.interaction]::AppActivate($id)|out-null
start-sleep -s 3
[System.Windows.Forms.SendKeys]::SendWait("{tab}")
start-sleep -s 1
[System.Windows.Forms.SendKeys]::SendWait("{tab}")
start-sleep -s 1
[System.Windows.Forms.SendKeys]::SendWait("{tab}")
start-sleep -s 1
[System.Windows.Forms.SendKeys]::SendWait("{tab}")
start-sleep -s 1
[System.Windows.Forms.SendKeys]::SendWait("~")
start-sleep -s 5
[System.Windows.Forms.SendKeys]::SendWait("{tab}")
start-sleep -s 1
[System.Windows.Forms.SendKeys]::SendWait("{tab}")
start-sleep -s 1
[System.Windows.Forms.SendKeys]::SendWait("{tab}")
start-sleep -s 1
[System.Windows.Forms.SendKeys]::SendWait("~")
start-sleep -s 5
}

##>

 (get-process -name msedge).CloseMainWindow()

 if( ((Get-Process msedge).id).count -gt 0){Stop-Process -name msedge -ErrorAction SilentlyContinue -Force}
 start-sleep -s 5

 $winv= ([System.Environment]::OSVersion.Version).Build
 if($winv -ge 22000){ $keyw="When Edge starts"}
 else{ $keyw="On startup"}

### start to setting##
Start-Process msedge.exe 
 start-sleep -s 10
 $id=(Get-Process msedge |?{($_.MainWindowTitle).length -gt 0}).Id

[Microsoft.VisualBasic.interaction]::AppActivate($id)|out-null
 start-sleep -s 2
[System.Windows.Forms.SendKeys]::SendWait("{esc}")
 start-sleep -s 2
[System.Windows.Forms.SendKeys]::SendWait("{esc}")
  start-sleep -s 2
[System.Windows.Forms.SendKeys]::SendWait("^l")
  start-sleep -s 2
[System.Windows.Forms.SendKeys]::SendWait("edge://settings/onstartup")
  start-sleep -s 2
[System.Windows.Forms.SendKeys]::SendWait("~")
  start-sleep -s 5
   
  Set-Clipboard -Value "when edge starts"
   start-sleep -s 5
  
[Microsoft.VisualBasic.interaction]::AppActivate($id)|out-null
   start-sleep -s 2
[System.Windows.Forms.SendKeys]::SendWait("^f")
  start-sleep -s 2
[System.Windows.Forms.SendKeys]::SendWait("^v")
  start-sleep -s 2
[System.Windows.Forms.SendKeys]::SendWait("~")
  start-sleep -s 2
[System.Windows.Forms.SendKeys]::SendWait("{esc}")
 start-sleep -s 2
[System.Windows.Forms.SendKeys]::SendWait("^a")
  start-sleep -s 2
[System.Windows.Forms.SendKeys]::SendWait("^c")
  start-sleep -s 5
$content=Get-Clipboard

if(-not ($content -like "*$url*")){

  Set-Clipboard -Value $keyw
   start-sleep -s 5
[Microsoft.VisualBasic.interaction]::AppActivate($id)|out-null
   start-sleep -s 2
[System.Windows.Forms.SendKeys]::SendWait("^f")
  start-sleep -s 2
[System.Windows.Forms.SendKeys]::SendWait("^v")
  start-sleep -s 2
[System.Windows.Forms.SendKeys]::SendWait("~")
  start-sleep -s 2
[System.Windows.Forms.SendKeys]::SendWait("{esc}")
  start-sleep -s 2
[System.Windows.Forms.SendKeys]::SendWait("{tab}")
start-sleep -s 2
[System.Windows.Forms.SendKeys]::SendWait("{DOWN}")
  start-sleep -s 2
[System.Windows.Forms.SendKeys]::SendWait("{DOWN}")
  start-sleep -s 2
[System.Windows.Forms.SendKeys]::SendWait("{tab}")
start-sleep -s 2
[System.Windows.Forms.SendKeys]::SendWait("~")
start-sleep -s 2
[System.Windows.Forms.SendKeys]::SendWait($url)
start-sleep -s 2
[System.Windows.Forms.SendKeys]::SendWait("~")
start-sleep -s 3
}


 (get-process -name msedge).CloseMainWindow() 


 ###### check ###

 start-sleep -s 3

Start-Process msedge.exe

start-sleep -s 3
$id=(Get-Process msedge |?{($_.MainWindowTitle).length -gt 0}).Id
[Microsoft.VisualBasic.interaction]::AppActivate($id)|out-null
 start-sleep -s 1
[System.Windows.Forms.SendKeys]::SendWait("{esc}")
start-sleep -s 2
[System.Windows.Forms.SendKeys]::SendWait("^l")
  start-sleep -s 2
[System.Windows.Forms.SendKeys]::SendWait("^a")
  start-sleep -s 2
[System.Windows.Forms.SendKeys]::SendWait("^c")
  start-sleep -s 5
$content2=Get-Clipboard
if( $content2 -like "*$url*"){
$results="OK"
}
else{
$results="NG"
}


 (get-process -name msedge).CloseMainWindow() 



######### write log #######


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
$index= $url

Get-Module -name "outlog"|remove-module
$mdpath=(gci -path "C:\testing_AI\modules\"  -r -file |?{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

#write-host "Do $action!"
outlog $action $results $tcnumber $tcstep $index

   }

    export-modulemember -Function edgehome_setting