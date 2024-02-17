function checkScreenResolution ([int]$para1,[int]$para2,[string]$para3,[string]$para4){
    
    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force;
    #$wshell=New-Object -ComObject wscript.shell
      Add-Type -AssemblyName Microsoft.VisualBasic
      Add-Type -AssemblyName System.Windows.Forms
   
$paracheck=$PSBoundParameters.ContainsKey('para1')
$paracheck2=$PSBoundParameters.ContainsKey('para2')
$paracheck3=$PSBoundParameters.ContainsKey('para3')
$paracheck4=$PSBoundParameters.ContainsKey('para4')

if( $paracheck -eq $false -or $para1 -eq 0 ){
$para1=1920
}
if( $paracheck2 -eq $false -or $para2 -eq 0 ){
$para2=1080
}
if( $paracheck3 -eq $false -or $para3.length -eq 0 ){
$para3=""
}if( $paracheck4 -eq $false -or $para4.length -eq 0 ){
$para4=""
}

$resx=$para1
$resy=$para2
$checkall=$para3
$non_logflag=$para4

if($PSScriptRoot.length -eq 0){
$scriptRoot="C:\testing_AI\modules"
}
else{
$scriptRoot=$PSScriptRoot
}

$action="check ScreenResolution supports $($resx) x $($resy)"

$tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
$tcnumber=((get-content $tcpath).split(","))[0]
$tcstep=((get-content $tcpath).split(","))[1]
$picpath=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\"
if(-not(test-path $picpath)){new-item -ItemType directory -path $picpath |out-null}
$checkresxy="$($resx)x$($resy)"

$actionss ="screenshot"
Get-Module -name $actionss|remove-module
$mdpath=(Get-ChildItem -path $scriptRoot -r -file |Where-object{$_.name -match "^$actionss\b" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global


## check  resolution match ## $resx $resy
$monitors = Get-WmiObject -Namespace "root\wmi" -Class WmiMonitorID

foreach ($monitor in $monitors) {
    $monitor_number=$monitor.__GENUS
    $monitorInfo = ($monitor.InstanceName -split '\\')[-1]  # Escape backslashes
    $monitorid = ($monitorInfo -split "\&")[1]
    $monitoruid = ($monitorInfo -split "\&")[-1]  
    Write-Host "Monitor: number $monitor_number ID $monitorid uid  $monitoruid"

    # Use LIKE operator for pattern matching
    $query = "SELECT * FROM WmiMonitorListedSupportedSourceModes WHERE InstanceName LIKE '%$monitorInfo%'"
    $modes = Get-WmiObject -Namespace "root\wmi" -Query $query
    if ($modes) {
        foreach ($mode in $modes) {
            foreach ($supportedMode in $mode.MonitorSourceModes) {
                $horizontal = $supportedMode.HorizontalActivePixels
                $vertical = $supportedMode.VerticalActivePixels
                Write-Host "Resolution: ${horizontal}x${vertical}"
                $collections= $collections+@("${horizontal}x${vertical}")
            }

            $checkifmatch=$collections|Sort-Object|Get-Unique|Where-Object {$_ -match $checkresxy}
                if(!$checkifmatch){
                $results+=@("NG")
                $index+=@("Monitor $($monitoruid) $checkifmatch not matching")
                }
                else{
                $results+=@("OK")
                $index+=@("Monitor $($monitoruid) $checkresxy suppported ")
                
                }
        }
    }
    else {
        $results="-"        
        $index="No modes found for this monitor."

    }
}

$index=$index|Out-String
if($checkall.Length -gt 0 -and $results -match "NG"){
 $results="NG"
}
if($checkall.Length -eq 0 -and $results -match "OK"){
 $results="OK"
}


 Write-Output "$results ; $index"

<#
$horlist=wmic /namespace:\\ROOT\WMI path WmiMonitorListedSupportedSourceModes get MonitorSourceModes /format:list |Where-object{$_ -match "HorizontalActivePixels"}
$verlist=wmic /namespace:\\ROOT\WMI path WmiMonitorListedSupportedSourceModes get MonitorSourceModes /format:list |Where-object{$_ -match "VerticalActivePixels"}

$rnk=0
foreach($verlist1 in $verlist){
$verlist1 -match "\d{3,}"
$maxy1=$Matches[0]
if([int]$maxy1 -eq [int]$resy){
  $maxy=[int]$maxy1
  $horlist[$rnk] -match "\d{3,}"
  $maxx1=$Matches[0]
  
  if([int]$maxx1 -eq [int]$resx){
   $maxx=[int]$maxx1
    $maxy2=$maxy
    $index= "resolution mathes: $($maxx) x $($maxy2)"
    break
   }
  
  }
   $rnk++
}

if($maxy -eq $resy -and $maxx -eq $resx){
$results="OK"
}
#>

  

######### write log #######
if($non_logflag.Length -eq 0){
Get-Module -name "outlog"|remove-module
$mdpath=(Get-ChildItem -path "C:\testing_AI\modules\"  -r -file |Where-object{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

#write-host "Do $action!"
outlog $action $results $tcnumber $tcstep $index
}

  }

    export-modulemember -Function checkScreenResolution