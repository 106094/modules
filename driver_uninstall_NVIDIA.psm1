
function driver_uninstall_NVIDIA ([string]$para1,[string]$para2){
      
    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force;
    $wshell=New-Object -ComObject wscript.shell
     $shell=New-Object -ComObject shell.application
      Add-Type -AssemblyName Microsoft.VisualBasic
       Add-Type -AssemblyName System.Windows.Forms
        Add-Type -AssemblyName System.Windows.Forms,System.Drawing
    
    $pkgename=$para1
    $nonlog_flag=$para2     


if($PSScriptRoot.length -eq 0){
$scriptRoot="C:\testing_AI\modules"
}
else{
$scriptRoot=$PSScriptRoot
}


$actionss="screenshot"
Get-Module -name $actionss|remove-module
$mdpath=(Get-ChildItem -path $scriptRoot -r -file |?{$_.name -match "^$actionss\b" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global


$tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
$tcnumber=((get-content $tcpath).split(","))[0]
$tcstep=((get-content $tcpath).split(","))[1]
$action=((get-content $tcpath).split(","))[2]

$picpath=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\"
if(-not(test-path $picpath)){new-item -ItemType directory -path $picpath |out-null}

$timenow=get-date -format "yyMMdd_HHmmss"
$programlistpath=$picpath+"$($timenow)_step$($tcstep)_programslist_before.txt"

$index=@()

if($pkgename.length -ne 0){

$packages = (Get-Package |?{$_.name -like "*$pkgename*"}).name
$controlpn="Control Panel\Programs\Programs and Features"

if($packages.count -ne 0){

## start uninstall ##

$packages = (Get-Package |?{$_.name -like "*$pkgename*"}).name
$packages|Out-File $programlistpath 

foreach ($package in $packages){

## screenshot 1st time

Start-Process control -Verb Open -WindowStyle Maximized
start-sleep -s 5
$wshell.SendKeys("% ")
$wshell.SendKeys("x")
start-sleep -s 2
$wshell.SendKeys("^l")
Set-Clipboard $controlpn
Start-Sleep -s 5
$wshell.SendKeys("^v")
Start-Sleep -s 1
$wshell.SendKeys("~")
Start-Sleep -s 10

  &$actionss  -para3 nonlog -para5 "before_uninstall_$($package)_check"

$shell.Windows() |?{$_.name -eq "File Explorer"}| ForEach-Object { $_.Quit() }
start-sleep -s 5

Start-Process control -Verb Open -WindowStyle Maximized
start-sleep -s 5

$ctlpath="$controlpn\$package" 

write-host "uninstall $package"

$wshell.SendKeys("^l")
Set-Clipboard $ctlpath
Start-Sleep -s 5
$wshell.SendKeys("^v")
Start-Sleep -s 1
$wshell.SendKeys("~")
Start-Sleep -s 10

  &$actionss  -para3 nonlog -para5 "start_uninstall_$($package)"

$wshell.SendKeys("u")

do{
$packages = (Get-Package |?{$_.name -eq $package}).name
}until($packages.count -eq 0)


$index=$index+@("$package uninstall done")

 &$actionss  -para3 nonlog -para5 "after_uninstall_$($package)"

Start-Sleep -s 5
$wshell.SendKeys("l")

$shell.Windows() |?{$_.name -eq "File Explorer"}| ForEach-Object { $_.Quit() }
start-sleep -s 5


## screenshot after

Start-Process control -Verb Open -WindowStyle Maximized
start-sleep -s 5

$wshell.SendKeys("^l")
Set-Clipboard $controlpn
Start-Sleep -s 5
$wshell.SendKeys("^v")
Start-Sleep -s 1
$wshell.SendKeys("~")
Start-Sleep -s 10

 &$actionss  -para3 nonlog -para5 "after_uninstall_$($package)_check"

$shell.Windows() |?{$_.name -eq "File Explorer"}| ForEach-Object { $_.Quit() }

}



$timenow=get-date -format "yyMMdd_HHmmss"
$programlistpath2=$picpath+"$($timenow)_step$($tcstep)_programslist_after.txt"
$programlistpath3=$picpath+"$($timenow)_step$($tcstep)_programslist_uninstall.txt"

$packages2 = (Get-Package |?{$_.name -like "*$pkgename*"}).name
$packages2 |Out-File $programlistpath2 

$packages|?{$_ -notin $packages2} |Out-File $programlistpath3

}

else{
$index="$pkgename no found"
}

$results="check index"
$index=[string]::join("`n",$index)
}
else{
$results="NG"
$index="No define uninstall target name"
}

######### write log #######

if($nonlog_flag.Length -eq 0){

Get-Module -name "outlog"|remove-module
$mdpath=(Get-ChildItem -path "C:\testing_AI\modules\"  -r -file |?{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

#write-host "Do $action!"
outlog $action $results $tcnumber $tcstep $index
}

   }

    export-modulemember -Function driver_uninstall_NVIDIA