
function pyinstall([string]$para1,[string]$para2){
    
    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force;
    $wshell=New-Object -ComObject wscript.shell
      Add-Type -AssemblyName Microsoft.VisualBasic
      Add-Type -AssemblyName System.Windows.Forms
        Add-Type -AssemblyName Microsoft.VisualBasic
        
      $ping = New-Object System.Net.NetworkInformation.Ping
 
 if($PSScriptRoot.length -eq 0){
$scriptRoot="C:\testing_AI\modules"
}
else{
$scriptRoot=$PSScriptRoot
}

$actioncmd="cmdline"
Get-Module -name $actioncmd|remove-module
$mdpath=(Get-ChildItem -path $scriptRoot -r -file |?{$_.name -match "^$actioncmd\b" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

$pyver=$para1
$nonlogflag=$para2
 
$action="pyinstall"
$tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
$tcnumber=((get-content $tcpath).split(","))[0]
$tcstep=((get-content $tcpath).split(","))[1]

$picpath=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\"
if(-not(test-path $picpath)){new-item -ItemType directory -path $picpath |out-null} 

#$checklink=($ping.Send("www.google.com", 1000)).Status
$checklink= Invoke-WebRequest -Uri "www.msn.com"


#!($checklink.Status -eq "success")
if(!($checklink)){
$results="-"
$index="no internet, bypassed"
}

else{

$timenow=get-date -Format "yyMMdd_HHmmss"
$pyinstalllog=$picpath+"$($timenow)_step$($tcstep)_pyinstall.log"
new-item $pyinstalllog -Force|Out-Null

#region py  install ##
$Command1="py --version" 

try{
$checkpyv = & invoke-Expression $Command1 | Out-String
}
catch{
 Write-Host "need install py"
  if(-not(test-path C:\temp)){
  new-item -Path C:\ -ItemType directory -Name "temp" |out-null
  }
}


if(!($checkpyv -match "Python") ){

 ### check internet connecting ###

$Command2="ping ""www.python.org"" -n 5"
$connectstatus=& invoke-Expression $Command2 | Out-String

if( $connectstatus -match "could not find host"){
  
$results="NG"
$index="Internet not connected, please check"

  }

else{
          
write-host "python install start --- $(get-date)"

 [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
 
 if($pyver.length -ne 0){
 
 write-host "install py-$pyver"

remove-item c:/temp/python*.exe -Force |out-null
$verlink= "https://www.python.org/ftp/python/$pyver/python-$pyver.exe"
$outfile="c:/temp/python-$pyver.exe"
 
$pypage2=Invoke-WebRequest -Uri $verlink  -OutFile $outfile -UseBasicParsing

&$outfile /quiet InstallAllUsers=0 PrependPath=1 Include_test=0
 
 }
 
 if($pyver.length -eq 0){

  write-host "install py-latest"

$pypage2=Invoke-WebRequest -Uri "https://www.python.org/" -UseBasicParsing
$link1=$pypage2.Links.Href| Select-String "release" | Select-String "download"
$pypage3=Invoke-WebRequest -Uri "https://www.python.org/$link1" -UseBasicParsing
$dl0=$pypage3.Links.Href| Select-String "amd64"| Select-String "exe"|sort|select -First 1
$dl=$dl0.tostring().trim()
$pyfn=($dl.split("/"))[-1]

Get-ChildItem c:/temp/python*.exe -ea SilentlyContinue|Remove-Item -Force |out-null

Invoke-WebRequest -Uri $dl -OutFile "C:\temp\$pyfn" -UseBasicParsing

do{
$size1= (Get-ChildItem c:/temp/python*.exe).length
start-sleep -s 5
$size2= (Get-ChildItem c:/temp/python*.exe).length
$dlcheck=$size2-$size1
$dlcheck
}until ($size2 -gt 0 -and $dlcheck -eq 0)

&"c:\temp\$pyfn" /quiet InstallAllUsers=0 PrependPath=1 Include_test=0

}


do{
start-sleep -s 5
$pyrun=((get-process -name python*).Id).count
} until ($pyrun -eq 0)

#double check

$pypath1=split-path ((get-command python).Source)
$pypath2=split-path ((get-command py).Source)
$pypath3=(Get-ChildItem "$env:USERPROFILE\AppData\Local\Programs\Python\Python*").FullName
$pypath4=((Get-ChildItem -path $pypath3 -r -filter "pip.exe").Directory).FullName
if($pypath1 -and $pypath1 -notin ($Env:PATH -split ";")){$Env:PATH += ";"+$pypath1}
if($pypath2 -and $pypath2 -notin ($Env:PATH -split ";")){$Env:PATH += ";"+$pypath2}
if($pypath3 -and $pypath3 -notin ($Env:PATH -split ";")){$Env:PATH += ";"+$pypath3}
if($pypath4 -and $pypath43 -notin ($Env:PATH -split ";")){$Env:PATH += ";"+$pypath4}

$n=0
do{
start-sleep -s 10
$n++
$checkpyv = &"$pypath3\python.exe" --version | Out-String
if($checkpyv){$checkpyv=$checkpyv.ToString().trim()}
}until ($checkpyv -match "Python"  -or $n -gt 30)

if($checkpyv -match "Python"){
$checkpyv
$results="OK"
$index=$checkpyv
write-host "python install end --- $(get-date)"
add-content -path $pyinstalllog -value $checkpyv
}

if($n -gt 30){
$results="NG"
$index="install python timeout"
}

}

}

else{
$results="no need"
$index=$checkpyv.trim()|Out-String
}

#endregion

#region pip  install ##
if(!( $connectstatus -match "could not find host")){
write-host "pip install start --- $(get-date)"
$usgpath=(Get-ChildItem "C:\testing_AI\modules\py\csg*\csg_utils*.whl"|sort lastwritetime|select -last 1).FullName
$piplistpath=(Get-ChildItem "C:\testing_AI\modules\py\csg*\piplist.bat"|sort lastwritetime|select -last 1).FullName
$Command2="pip install --upgrade pip"
$Command3="pip install $usgpath" 
$Command4=$piplistpath


$pipinstall+="pip install start --- $(get-date)"
$pipinstall+=& invoke-Expression "$Command2" -ErrorAction SilentlyContinue | Out-String
$pipinstall+=& invoke-Expression "$Command3" -ErrorAction SilentlyContinue | Out-String
$pipinstall+=& invoke-Expression "$Command4" -ErrorAction SilentlyContinue | Out-String
$pipinstall+="pip install done --- $(get-date)"

add-content $pyinstalllog -Value $pipinstall

write-host "pip install done --- $(get-date)"
}
#endregion

}
######### write log #######
if($nonlogflag.Length -eq 0){
Get-Module -name "outlog"|remove-module
$mdpath=(Get-ChildItem -path "C:\testing_AI\modules\"  -r -file |?{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

#write-host "Do $action!"
outlog $action $results $tcnumber $tcstep $index
}

  }

 export-modulemember -Function pyinstall