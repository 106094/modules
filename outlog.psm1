function outlog ([string] $para1,[string] $para2, [string] $para3, [string] $para4, [string] $para5 ){

   $action = [string] $para1
   $results = [string] $para2
   $tcnumber = [string] $para3
   $tcstep = [string] $para4
   $index = [string] $para5

if($PSScriptRoot.length -eq 0){
$scriptRoot="C:\testing_AI\modules\"
}
else{
$scriptRoot=$PSScriptRoot
}


$logspath=(Split-Path -Parent $scriptRoot)+"\logs\logs_timemap.csv" 
$checknewlog=get-content $logspath|Select-Object -First 1

$time=get-date -Format "yyyy/M/d HH:mm:ss"
$timenowfm=get-date -format "yyMMdd_HHmmss"

$settings=import-csv C:\testing_AI\settings\flowsettings.csv
$current_settins=$settings|Where-object{$_.TC -eq $tcnumber -and $_.Step_No -eq $tcstep}
$prgname=$current_settins.programs

if($index.Length -gt 100){
if($checknewlog -match "program"){
$indextxt=(Split-Path $scriptRoot)+"\logs\$tcnumber\$($timenowfm)_step$($tcstep)_$($prgname)_index.txt"
}
else{
$indextxt=(Split-Path $scriptRoot)+"\logs\$tcnumber\$($timenowfm)_step$($tcstep)_index.txt"
}
Set-Content -path $indextxt -value $index -Force
$index="check $($indextxt)"
}

if($checknewlog -match "TC_step"){

$settings=import-csv C:\testing_AI\settings\flowsettings.csv
$current_settins=$settings|Where-object{$_.TC -eq $tcnumber -and $_.Step_No -eq $tcstep}
$prgname=$current_settins.programs
$tcstep0=$current_settins.TC_step
$mustfg=$current_settins.must
$para1=$current_settins.para1
$para2=$current_settins.para2
$para3=$current_settins.para3
$para4=$current_settins.para4
$para5=$current_settins.para5

$logs=$logs+@( 
   [pscustomobject]@{
       
       Time=$time       
       TC=$tcnumber
       TC_step=$tcstep0
       Step_No=$tcstep
       Actions=$action
       Results=$results     
       Index=$index
       program=$prgname
       must=$mustfg
       para1=$para1
       para2=$para2
       para3=$para3
       para4=$para4
       para5=$para5

       }
       )
       

}

else{
$logs=$logs+@( 
   [pscustomobject]@{
       
      Time=$time       
      TC=$tcnumber
      Step_No=$tcstep
      Actions=$action
      Results=$results     
      Index=$index
      program=$prgname
      must=$mustfg
      para1=$para1
      para2=$para2
      para3=$para3
      para4=$para4
      para5=$para5

       }
       )
}


  $logs   | export-csv -path  $logspath -Encoding OEM -NoTypeInformation -Append

  try {stop-Transcript}catch{write-host "."}

  }

    export-modulemember -Function  outlog