function SPECviewperf_CompleteCheck ([string]$para1) {

  Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force
   $wshell = New-Object -com WScript.Shell
    Add-Type -AssemblyName Microsoft.VisualBasic
       Add-Type -AssemblyName System.Windows.Forms
  
  if($PSScriptRoot.length -eq 0){
  $scriptRoot="C:\testing_AI\modules"
  }
  else{
  $scriptRoot=$PSScriptRoot
  }
  
  if($para1 -match "13"){$benchtype="SPECviewperf13"}
  if($para1 -match "2020"){$benchtype="SPECviewperf2020"}
  
  $action="$benchtype job completed check"
  $tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
  $tcnumber=((get-content $tcpath).split(","))[0]
  $tcstep=((get-content $tcpath).split(","))[1]
  $picpath=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\"
  
  
  $taskExists = Get-ScheduledTask | Where-Object {$_.TaskName -like "Auto_Run" }
  if(!$taskExists){
  
   $results="-"
   $index=   "$benchtyp no execute"
   
  }
  
  else{
  
   $doneflag=$null
  
   if($benchtype -eq "SPECviewperf13"){
   $startruntime=(Get-ChildItem C:\SPEC\SPECgpc\SPECviewperf13\vp13bench\gwpgRunBenchmark.js).LastWriteTime
   $resultfd=Get-ChildItem -Path C:\SPEC\SPECgpc\SPECviewperf13\results_*  -Directory|Where-object{$_.CreationTime -gt $startruntime}
   
  $setindex="C:\SPEC\SPECgpc\SPECviewperf13\vp13bench\index.html"
  $setindexb="C:\SPEC\SPECgpc\SPECviewperf13\vp13bench\index_0.html"
  $mgntjs="C:\SPEC\SPECgpc\SPECviewperf13\vp13bench\gwpgManageBenchmark.js"
  $mgntjsb="C:\SPEC\SPECgpc\SPECviewperf13\vp13bench\gwpgManageBenchmark_0.js"
  $mgntrbjs="C:\SPEC\SPECgpc\SPECviewperf13\vp13bench\gwpgRunBenchmark.js"
  $mgntrbjsb="C:\SPEC\SPECgpc\SPECviewperf13\vp13bench\gwpgRunBenchmark_0.js"
  
   }
   if($benchtype -eq "SPECviewperf2020"){
   
  
  $setindex="C:\SPEC\SPECgpc\SPECviewperf2020\vpbench\index.html"
  $setindexb="C:\SPEC\SPECgpc\SPECviewperf2020\vpbench\index_0.html"
  $mgntjs="C:\SPEC\SPECgpc\SPECviewperf2020\vpbench\gwpgManageBenchmark.js"
  $mgntjsb="C:\SPEC\SPECgpc\SPECviewperf2020\vpbench\gwpgManageBenchmark_0.js"
  $mgntrbjs="C:\SPEC\SPECgpc\SPECviewperf2020\vpbench\gwpgRunBenchmark.js"
  $mgntrbjsb="C:\SPEC\SPECgpc\SPECviewperf2020\vpbench\gwpgRunBenchmark_0.js"
  
    $logfile=(Split-Path -Parent $scriptRoot)+"\logs\logs_timemap.csv"
    $lastlogtime=(Get-ChildItem $logfile).lastwritetime
    #$startruntime=(Get-ChildItem C:\SPEC\SPECgpc\SPECviewperf2020\vpbench\gwpgRunBenchmark.js).LastWriteTime
    
    $testitems=((import-csv $logfile|Where-Object{$_.tc -match $tcnumber -and $_.program -match "benchmark2" -and $_.para1 -match "2020"})|Select-Object -Last 1).para2
    if($testitems.length -eq 0){
    $testitemall=@("3dsmax-07","catia-06","creo-03","energy-03","maya-06","medical-03","snx-04","solidworks-07")
    }
    else{
     $testitemall=$testitems -split "+"
    }
  
    $resultfd=Get-ChildItem -Path C:\SPEC\SPECgpc\SPECviewperf2020\results_*  -Directory|Where-object{$_.lastwritetime -gt $lastlogtime} 
    #checkif resest running
    $checkretesting=get-process -name nw -ErrorAction SilentlyContinue

   if( $resultfd.count -eq 0 -or $checkretesting){
   exit
   }
  
   else{ 
    #check 1 results
    $resultfd1=Get-ChildItem -Path C:\SPEC\SPECgpc\SPECviewperf2020\results_*  -Directory|Where-object{$_.lastwritetime -gt $lastlogtime}|Sort-Object lastwritetime|Select-Object -First 1
    $resultfd1csv=(Get-ChildItem ($resultfd1.fullname) -r |Where-object {$_.name -eq "resultcsv.csv"}).FullName
    $csvraw=get-content -path $resultfd1csv
    
  foreach($raw in $csvraw){
      $testitemall|ForEach-Object{
        if($raw -match $_){
        $testeditem+=@(($raw.split(","))[0])
      }   
      }
      if($raw -match "viewset"){
        break
      }
    }
  
  $testitemall|ForEach-Object{
  if($_ -notin $testeditem){
  $retestitem+=@($_)
  }
  }
  
  $resultfd=$resultfd1
  

  #need retest

  if($retestitem.Count -gt 0){
     
  $retestitempara=[string]::join("+",$retestitem)

  write-host "need retest with $retestitempara"

  #retest go
  if($resultfd.count -eq 1){
   start-sleep -s 30
  
   (get-process -name msedge -ea SilentlyContinue).CloseMainWindow()
  
   start-process cmd -ArgumentList '/c schtasks /delete /TN "Auto_Run" -f' 
  
   Copy-Item -Path $resultfd.FullName -Destination $picpath -Recurse -Force
   
  move-item $setindexb $setindex -Force
  move-item $mgntjsb $mgntjs -Force
  move-item $mgntrbjsb $mgntrbjs -Force

  $action2020="benchmark2"
  Get-Module -name $action2020|remove-module
  $mdpath=(Get-ChildItem -path $scriptRoot -r -file |Where-object{$_.name -match "^$action2020\b" -and $_.name -match "psm1"}).fullname
  Import-Module $mdpath -WarningAction SilentlyContinue -Global
  
  &$action2020 -para1 "SPECviewperf2020" -para2 $retestitempara -para4 "nonlog"        
  
  }

  if($resultfd.count -eq 2){
  $resultfd2=Get-ChildItem -Path C:\SPEC\SPECgpc\SPECviewperf2020\results_*  -Directory|Where-object{$_.CreationTime -gt $lastlogtime}|Sort-Object creationtime|Select-Object -last 1
  $resultfd=$resultfd2
  }
  }
     
   
   }
   }
  
   start-sleep -s 30
  
   (get-process -name msedge -ea SilentlyContinue).CloseMainWindow()
  
   start-process cmd -ArgumentList '/c schtasks /delete /TN "Auto_Run" -f' 


   Copy-Item -Path $resultfd.FullName -Destination $picpath -Recurse -Force
   

  move-item $setindexb $setindex -Force
  move-item $mgntjsb $mgntjs -Force
  move-item $mgntrbjsb $mgntrbjs -Force
  
   $results="OK"
   $index= "check logs"

 }

  ### write log ##
  
  Get-Module -name "outlog"|remove-module
  $mdpath=(Get-ChildItem -path "C:\testing_AI\modules\" -r -file |Where-object{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
  Import-Module $mdpath -WarningAction SilentlyContinue -Global
  
  #write-host "Do $action!"
  outlog $action $results  $tcnumber $tcstep $index
  
   }
  
  
    
      export-modulemember -Function SPECviewperf_CompleteCheck