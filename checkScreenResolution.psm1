function checkScreenResolution ([int]$para1,[int]$para2,[string]$para3){
    
    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force;
    #$wshell=New-Object -ComObject wscript.shell
      Add-Type -AssemblyName Microsoft.VisualBasic
      Add-Type -AssemblyName System.Windows.Forms
   
$paracheck=$PSBoundParameters.ContainsKey('para1')
$paracheck2=$PSBoundParameters.ContainsKey('para2')
$paracheck3=$PSBoundParameters.ContainsKey('para3')

if( $paracheck -eq $false -or $para1 -eq 0 ){
$para1=1920
}
if( $paracheck2 -eq $false -or $para2 -eq 0 ){
$para2=1080
}
if( $paracheck3 -eq $false -or $para3.length -eq 0 ){
$para3=""
}
$resx=$para1
$resy=$para2
$non_logflag=$para3

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

$results="NG"
$index="not matching"

$actionss ="screenshot"
Get-Module -name $actionss|remove-module
$mdpath=(Get-ChildItem -path $scriptRoot -r -file |Where-object{$_.name -match "^$actionss\b" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

$checkresxy="$($resx)x$($resy)"
## check  resolution match ## $resx $resy
$monitors = Get-WmiObject -Namespace "root\wmi" -Class WmiMonitorID

foreach ($monitor in $monitors) {
    $monitor_number=$monitor.__GENUS
    $monitorInfo = ($monitor.InstanceName -split '\\')[-1]  # Escape backslashes
    $monitorid = ($monitorInfo -split "\&")[1]
    $monitoruid = ($monitorInfo -split "\&")[-1]  
    Write-Host "Monitor: number $monitor_number ID $monitorid  $monitoruid"

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
        }
    }
    else {
        Write-Host "No modes found for this monitor."
    }
}
$checkifmatch=$collections|Sort-Object|Get-Unique|Where-Object {$_ -match $checkresxy}
if($checkifmatch){
$results="OK"
$index="$checkifmatch suppported"
}
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
  
 Write-Output "$results; $index"
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