
function driver_uninstall ([string]$para1,[string]$para2){
      
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

$tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
$tcnumber=((get-content $tcpath).split(","))[0]
$tcstep=((get-content $tcpath).split(","))[1]
$action=((get-content $tcpath).split(","))[2]

$picpath=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\"
if(-not(test-path $picpath)){new-item -ItemType directory -path $picpath |out-null}

$unresults=@()

$packages = Get-Package |?{$_.name -like "*$pkgename*"}

if($packages.count -ne 0){

do{

$packages = Get-Package |?{$_.name -like "*$pkgename*"}

foreach($package in $packages){
$packagename=$package.Name
start-sleep -s 30
<#
  #region method 1
   $argList = foreach ($i in (0..($package.Meta.Attributes.Keys.Count - 1))) {
        if ($package.Meta.Attributes.Keys[$i] -eq 'UninstallString') {
            $package.Meta.Attributes.Values[$i]
        }  
    }
       # return $Command
    Invoke-Expression "& $Command "

    #endregion
 #>

#region method 2

#Get Uninstall String from Registry
$us = Get-childItem -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" -ErrorAction SilentlyContinue | Get-ItemProperty | Where-Object {$_.DisplayName -like $packagename} | select DisplayName, UninstallString

if($us.DisplayName.count -ne 0){

# Splitting the Uninstall String into executable and argument list
$unused, $filePath, $argList = $us.UninstallString -split '"', 3

# Any of the following command can start the process 

$argList += ' -silent', '-deviceinitiated'
  
Start-Process -FilePath "C:\Windows\SysWOW64\RunDll32.EXE" -ArgumentList $argList -Wait  
 
 $counttime=0

 do{
 start-sleep -s 10
 $checkuninstall=(Get-Package |?{$_.name -eq $packagename}).count
 $counttime++
 }

until ($checkuninstall -eq 0 -or $counttime -gt 10)
$unresult="$packagename uninstall done"

if($counttime -gt 10){$index="$packagename uninstall fail over 100sec"}

$unresults=$unresults+@($unresult)
}

}

}until($packages.count -eq 0)

$results="OK"
$timenow=get-date -format "yyMMdd_HHmmss"
$uninstalllog=$picpath+"$($timenow)_step$($tcstep)_$($pkgename)_uninstall_pass.txt"

if($unresults -match "fail"){
$results="NG"
$uninstalllog=$picpath+"$($timenow)_step$($tcstep)_$($pkgename)_uninstall_fail.txt"
}

new-item $uninstalllog -Force|out-null
$unresults=$unresults|Out-String
add-content -path $uninstalllog -value $unresults

}


else{

$timenow=get-date -format "yyMMdd_HHmmss"
$uninstalllog=$picpath+"$($timenow)_step$($tcstep)_$($pkgename)_uninstall_nofound.txt"

$results="NG"
add-content -path $uninstalllog -value "$($pkgename) no found from get-package"
}

$index="check logs"

######### write log #######

if($nonlog_flag.Length -eq 0){

Get-Module -name "outlog"|remove-module
$mdpath=(Get-ChildItem -path "C:\testing_AI\modules\"  -r -file |?{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

#write-host "Do $action!"
outlog $action $results $tcnumber $tcstep $index
}

   }

    export-modulemember -Function driver_uninstall