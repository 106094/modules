
function timeZone_setting ([string]$para1){

    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force;
    $wshell=New-Object -ComObject wscript.shell
      Add-Type -AssemblyName Microsoft.VisualBasic
      Add-Type -AssemblyName System.Windows.Forms
 
 
$paracheck1=$PSBoundParameters.ContainsKey('para1')

if($paracheck1 -eq $false -or $para1.Length -eq 0){
$para1="Taipei"
}

#Central America Standard Time use keywork "Central America"
#Taipei Standard Time use keywork "Taipei"
#Tokyo Standard Time use keywork "Tokyo"

  $id=$para1

  $time1=get-date -Format "yy/MM/dd HH:mm"
  
  $desid=(Get-TimeZone *).id -match $id

   $timezone=(Get-TimeZone -ListAvailable|?{$_.id -match "$id" }).id
    $sets=  Set-TimeZone -id $timezone -PassThru
    $index1=$sets.tostring()
    
 <##Set-Date -Adjust $timeset if no internet
  $connet=Test-Connection google.com -count 1 -quiet
  $destime=[System.TimeZoneInfo]::ConvertTimeBySystemTimeZoneId((Get-Date), $desid) 
  $timeset = (New-TimeSpan  -start (get-date) -end $destime).TotalHours
  $timeset=[math]::Round($timeset,2)

  if($connet -eq $false -and $timeset -ne 0){
   Set-Date -Adjust $timeset
   }
   ##>
      
   $time2=get-date -Format "yy/MM/dd HH:mm"
   $index=  "change from  $time1 to $time2 ( $index1 ) with time gap:  $timeset Hours"
    
    if( $sets.Id -match $id){$results="OK"}
      if( -not($sets.Id -match $id)){$results="NG"}
  
######### write log #######


if($PSScriptRoot.length -eq 0){
$scriptRoot="C:\testing_AI\modules"
}
else{
$scriptRoot=$PSScriptRoot
}

$action="Set time zone in $id"

$tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
$tcnumber=((get-content $tcpath).split(","))[0]
$tcstep=((get-content $tcpath).split(","))[1]

Get-Module -name "outlog"|remove-module
$mdpath=(gci -path "C:\testing_AI\modules\"  -r -file |?{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

#write-host "Do $action!"
outlog $action $results $tcnumber $tcstep $index


  }

    export-modulemember -Function timeZone_setting