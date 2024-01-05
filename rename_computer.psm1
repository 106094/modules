

function rename_computer([string]$para1) {

    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force;
    $wshell=New-Object -ComObject wscript.shell
      Add-Type -AssemblyName Microsoft.VisualBasic
      Add-Type -AssemblyName System.Windows.Forms
      
$paracheck=$PSBoundParameters.ContainsKey('para1')

if( $paracheck -eq $false -or $para1.length -eq 0){
$para1=($env:USERNAME)
}

$newname=$para1.Replace(" ","_") 

## for cycling team special request ##

if($newname -match "cycling\d{0,2}"){
$newname=$Matches[0]
}
 
 <## win10 not accept "_" with Rename-Computer
  $newname=($para1.Replace(" ","-")).Replace("_","-") 
  $index_rename=Rename-Computer -NewName $newname -Force -PassThru -WarningVariable arr
   $index=$index_rename.tostring()
  if($index -match "true"){$results="OK, $($arr)"}  
  if($index -notmatch "true"){$results="NG, $($arr)"}   
   ##>

  # cmd /c "wmic computersystem where name='%computername%' call rename name='$newname'"
  $newname="$env:USERNAME"
  $computer = Get-WmiObject -Class Win32_ComputerSystem
  $newaname=$computer.rename($newname)

  $index=$newaname.ReturnValue
  if($index -eq 0){$results="OK,change device name to $newname"}  
  
  else{$results="NG,fail to change device name to $newname"}   
  
     
if($PSScriptRoot.length -eq 0){
$scriptRoot="C:\testing_AI\modules\"
}
else{
$scriptRoot=$PSScriptRoot
}


$action="rename computer"

$tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
$tcnumber=((get-content $tcpath).split(","))[0]
$tcstep=((get-content $tcpath).split(","))[1]

Get-Module -name "outlog"|remove-module
$mdpath=(Get-ChildItem -path "C:\testing_AI\modules\"  -r -file |Where-object{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

#write-host "Do $action!"
outlog $action $results $tcnumber $tcstep $index


  }

    export-modulemember -Function rename_computer