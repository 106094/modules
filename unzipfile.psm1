

function unzipfile ([string]$para1,[string]$para2,[string]$para3,[string]$para4){
    
    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force;
    $wshell=New-Object -ComObject wscript.shell
    $shell=New-Object -ComObject shell.application
     Add-Type -AssemblyName Microsoft.VisualBasic
     Add-Type -AssemblyName System.Windows.Forms
   
$paracheck=$PSBoundParameters.ContainsKey('para1')
$paracheck2=$PSBoundParameters.ContainsKey('para2')
$paracheck3=$PSBoundParameters.ContainsKey('para3')
$paracheck4=$PSBoundParameters.ContainsKey('para4')

if( $paracheck -eq $false -or $para1.length -eq 0 ){
#write-host "no defined, setting 1 min after login"
$para1=""
}
if( $paracheck2 -eq $false -or $para2.length -eq 0 ){
$para2=""
}
if( $paracheck3 -eq $false -or $para3.length -eq 0 ){
$para3=""
}
if( $paracheck4 -eq $false -or $para4.length -eq 0 ){
$para4=""
}

if($PSScriptRoot.length -eq 0){
$scriptRoot="C:\testing_AI\modules"
}
else{
$scriptRoot=$PSScriptRoot
}

$zipname=$para1
$zipfolder=$para2
$unzipfolder=$para3
$nonlog_flag=$para4

$action="unzip files - $zipname"

$tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
$tcnumber=((get-content $tcpath).split(","))[0]
$tcstep=((get-content $tcpath).split(","))[1]

$logpath=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\"
if(-not(test-path $logpath)){new-item -ItemType directory -path $logpath -Force|Out-Null}
if($zipfolder.length -eq 0){$zipfolder=$logpath}

$zipfiles= Get-ChildItem $zipfolder -Recurse |Where-Object {$_.name -like "$zipname*" -and $_.Extension -match "zip"}

 
if (($zipfiles.FullName).count -eq 0){
$results="NG"
$index="fail to find zip files"
}

else{

$results="OK"
$index=@()

foreach($zipfile in $zipfiles){
$filename= $zipfile.Name
$filenamefull=$zipfile.fullname
$filenamefullnew=($filenamefull.replace("[","*")).replace("]","*")

if($unzipfolder.length -eq 0){
$unzippath= $zipfolder+$zipfile.basename+"\"
}
else{
$unzippath= $zipfolder+$unzipfolder+"\"
}

if(-not(test-path $unzippath)){new-item -ItemType directory -path $unzippath -Force|Out-Null}

write-host "unzip $filename  to $unzippath"
  
  # Path to the zip file you want to extract
#$zipFilePath = "C:\Path\to\your\archive.zip"

# Destination directory for extraction
#$destinationPath = "C:\Path\to\extraction\directory"

# Expand the archive asynchronously

do{
 try{

Start-Job -ScriptBlock {
    param(
        [string]$filenamefullnew,
        [string]$unzippath
    )

    #$shell.NameSpace($unzippath).copyhere($shell.NameSpace($filenamefull).Items(),16)
    
    Expand-Archive $filenamefullnew -DestinationPath $unzippath -Force
    $lev2zip=Get-ChildItem -path $unzippath  -include *.zip -Recurse
   
      if($lev2zip.count -gt 0){
       foreach($zip2 in $lev2zip){        
        $zip2fo=$zip2.basename
        $zip2des="$($unzippath)\$($zip2fo)"
        Expand-Archive $zip2.FullName  -DestinationPath $zip2des -Force

          $lev3zip=Get-ChildItem -path $zip2des  -include *.zip -exclude $zip2.Name -Recurse
          if($lev3zip.count -gt 0){
          foreach($zip3 in $lev3zip){
            $zip3fo=$zip3.basename
            Expand-Archive $zip3.FullName  -DestinationPath  "$($zip2des)\$($zip3fo)" -Force
        }
       }
      }
    }
  
}  -name "Zippityzip" -ArgumentList $filenamefullnew,$unzippath

Wait-job -name "Zippityzip"

# Check if the extraction is complete
#$job = Get-Job
#$job | Wait-Job
#Receive-Job -Job  $job

 }
 catch{
   Write-Host "Failed to unzip: $_.Exception.Message"
 $results="NG" ; $index=$index+@("fail to unzip $filename") 
 }

 $unfilecount=(Get-ChildItem $unzippath -Recurse -file).count
 
 }until($results -eq "NG" -or $unfilecount -gt 0 )


   $index=$index+@("unzip folder: $($unzippath)")
  }

}

$index=$index|Out-String

######### write log #######

if($nonlog_flag.Length -eq 0){
Get-Module -name "outlog"|remove-module
$mdpath=(Get-ChildItem -path "C:\testing_AI\modules\"  -r -file |?{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

#write-host "Do $action!"
outlog $action $results $tcnumber $tcstep $index
}

  }

    export-modulemember -Function unzipfile