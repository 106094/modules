
Function browserInstall([string]$para1,[string]$para2){

if($PSScriptRoot.length -eq 0){
$scriptRoot="C:\testing_AI\modules\"
}
else{
$scriptRoot=$PSScriptRoot
}

$tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
$tcnumber=((get-content $tcpath).split(","))[0]
$tcstep=((get-content $tcpath).split(","))[1]

$results="NG"
$index="fail to install"

    if($para1 -eq "chrome"){
        Add-Type -AssemblyName System.Windows.Forms
        #$latestVersion = Invoke-WebRequest -Uri "https://omahaproxy.appspot.com/all.json" | ConvertFrom-Json | Where-Object {$_.os -eq "win" -and $_.channel -eq "stable"} | Select-Object -ExpandProperty versions | Sort-Object -Property build -Descending | Select-Object -First 1
        $chromeURL = "https://dl.google.com/chrome/install/chrome_installer.exe"
        $chromeFile = "$($env:USERPROFILE)\Downloads\chrome_installer.exe"
        Invoke-WebRequest -Uri $chromeURL -OutFile $chromeFile
        &$chromeFile /silent /install

        #$Processid = Start-Process $chromeFile -PassThru
        
        do{
            echo "Wait for Install"
            start-sleep -s 10
        }until(!(Get-Process -name chrome_installer -ErrorAction SilentlyContinue))


        echo "Install Complete"
       # start-sleep -s 10
       # Get-Process chrome -ErrorAction SilentlyContinue | Stop-Process -Force     
     

  # check install       
  $browserinfo = Get-Package -Name "*Google*" 
    #$browserpath = (Get-Item (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\chrome.exe').'(Default)').VersionInfo.FileName
    $version= $browserinfo.Version

if($browserinfo){
$results="OK"
$index="$para1 version is $version"
}


    }
    if($para1 -eq "edge"){
        Invoke-WebRequest -Uri "https://c2rsetup.officeapps.live.com/c2r/downloadEdge.aspx?platform=Default&source=EdgeStablePage&Channel=Stable&language=en&brand=M100" -OutFile "$env:USERPROFILE\Downloads\EdgeSetup.exe"
        $Processid =  Start-Process -FilePath "$env:USERPROFILE\Downloads\EdgeSetup.exe" -PassThru

        do{
            echo "Wait for Install"
            start-sleep -s 10
        }until(!(Get-Process -Id $Processid.Id -ErrorAction SilentlyContinue))

        echo "Install Complete"
        start-sleep -s 10
        Get-Process edge -ErrorAction SilentlyContinue | Stop-Process -Force 

        
  # check install       
$browserpath = (Get-Item (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\msedge.exe').'(Default)').VersionInfo.FileName
$version=(Get-Item $browserpath).VersionInfo.FileVersion
if($version.length -ne 0){
$results="OK"
$index="$para1 version is $version"
}


    }
    if($para1 -eq "firefox"){
        Invoke-WebRequest -Uri "https://download.mozilla.org/?product=firefox-latest&os=win64&lang=en-US" -OutFile "$env:USERPROFILE\Downloads\FirefoxSetup.exe"
        $Processid =  Start-Process -FilePath "$env:USERPROFILE\Downloads\FirefoxSetup.exe" -ArgumentList "/S" -PassThru

        do{
            echo "Wait for Install"
            start-sleep -s 10
        }until(!(Get-Process -Id $Processid.Id -ErrorAction SilentlyContinue))

        echo "Install Complete"

  # check install  

$browserpath = (Get-Item (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\firefox.exe').'(Default)').VersionInfo.FileName
$version=(Get-Item $browserpath).VersionInfo.FileVersion
$results="OK"
$index="$para1 version is $version"
   }


    ######### write log #######
    if($para2.length -eq 0){
        Get-Module -name "outlog"|remove-module
        $mdpath=(Get-ChildItem -path "C:\testing_AI\modules\"  -r -file |Where-object{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
        Import-Module $mdpath -WarningAction SilentlyContinue -Global

        #write-host "Do $action!"
        outlog $action $results $tcnumber $tcstep $index
    }
}


# 匯出模絁E�E�E員
Export-ModuleMember -Function browserInstall