function rebootn ([int]$para1, [int]$para2,[string]$para3){
    
    #check parameter
    $paracheck1=$PSBoundParameters.ContainsKey('para1')
    $paracheck2=$PSBoundParameters.ContainsKey('para2')

    #ini parameter
    if($paracheck1 -eq $false -or $para1 -eq 0){
        $para1=[int]1
    }
    if($paracheck2 -eq $false -or $para2 -eq 0){
        $para2=[int]60
    }

    $countn=[int]$para1
    $waittime=[int]$para2
    $nonlog_flag=$para

    #Run script path
    if($PSScriptRoot.length -eq 0){
        $scriptRoot="C:\testing_AI\modules"
    }
    else{
        $scriptRoot=$PSScriptRoot
    }
    
    #current run tc data
    $tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
    $tcnumber=$((get-content $tcpath).split(","))[0]
    $tcstep=((get-content $tcpath).split(","))[1]
    $logfile=(Split-Path -Parent $scriptRoot)+"\logs\logs_timemap.csv"
          
    do{
        Start-Sleep -s 5
        $checklogfile=Get-ChildItem $logfile
    }until($checklogfile)

    Start-Sleep -s  $waittime

#region check oobe
$checkoobe1=get-process -name *|?{$_.name -match "WWAHost"}
$checkoobe2=get-process -name *|?{$_.name -match "WebExperienceHostApp"}

if($checkoobe1 -or $checkoobe2){

$actionss="screenshot"
Get-Module -name $actionss|remove-module
$mdpath=(Get-ChildItem -path $scriptRoot -r -file |?{$_.name -match "^$actionss\b" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

&$actionss  -para3 nonlog -para5 "oobe"
stop-process -name WWAHost -Force -ErrorAction SilentlyContinue
stop-process -name WebExperienceHostApp -Force -ErrorAction SilentlyContinue
&$actionss  -para3 nonlog -para5 "oobe_close"

}
#endregion

    $nowtime=get-date -Format "yyyy/M/d HH:mm:ss"

    $picpath=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\"

    if(-not(test-path $picpath)){new-item -ItemType directory -path $picpath |out-null}

    $datenow=get-date -format "yyMMdd_HHmmss"

    $checklogexist=Get-ChildItem $picpath |?{$_.name -match "step$($tcstep)_reboot.log"} | Sort-Object LastWriteTime -Descending | Select-Object -Last 1
    #$checklogexist= $checklogexist | Sort-Object LastWriteTime -Descending | Select-Object -Last 1

    if($checklogexist){
        $rebootlog=$checklogexist.FullName
    }
    else{

     ## for the 1st time #

        $rebootlog= $picpath+"$($datenow)_step$($tcstep)_reboot.log"
        new-item $rebootlog -Force|out-null
        add-content $rebootlog -Value "start, $nowtime"  -Force

  <#
  if( $noupdate_flag.Length -gt 0){
       &$actiondns -para1 "127.0.0.1" -para2 "nonlog"
              
        if(test-path "C:\Windows\SoftwareDistribution\ReportingEvents.log"){
        $timenow=get-date -format "yyMMdd_HHmmss"
        if(!(test-path "C:\testing_AI\logs\ReportingEvents\")){
        new-item -ItemType directory "C:\testing_AI\logs\ReportingEvents\"|Out-Null
        }
        $bkreportingeventlog="C:\testing_AI\logs\ReportingEvents\"+"ReportingEvents_$($timenow).log"
        Copy-Item "C:\Windows\SoftwareDistribution\ReportingEvents.log" -Destination $bkreportingeventlog -Force
        }
        remove-item C:\Windows\SoftwareDistribution\* -Recurse -Force -ErrorAction SilentlyContinue

       }
 #>

    }

    #time set
    $timestart =  (Get-ChildItem -File $logfile).lastwritetime
     
    if( $nonlog_flag.Length -eq 0){
        $evetafter=Get-EventLog System -After  $timestart| Where-Object {$_.EventID -eq 1074} 
    }

    $countrb=$evetafter.index.count
    if($countrb -gt 0){$evetafter}
    write-host "reboot count: $countrb after last log"

## finished #

    if($countrb -ge $countn){
    
        #reboot done
        
        $results="OK"
        $index="reboot $countn cycles done"

        add-content $rebootlog -Value "end, $nowtime " -Force

        start-process cmd -ArgumentList '/c schtasks /delete /TN "Auto_Run" -f' 
        start-sleep -s 10

        $action="rebootx$($countn)"
        $tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
        $tcnumber=$((get-content $tcpath).split(","))[0]
        $tcstep=((get-content $tcpath).split(","))[1]
        
        #write log
        if( $nonlog_flag.Length -eq 0){
            Get-Module -name "outlog"|remove-module
            $mdpath=(Get-ChildItem -path "C:\testing_AI\modules\" -r -file |?{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
            Import-Module $mdpath -WarningAction SilentlyContinue -Global

            #write-host "Do $action!"
            outlog $action $results  $tcnumber $tcstep $index


        }
    }

## notyet finish

    else{

        #start reboot cycle , until countn = countrb

        $timeset=[double]1
        $TimeSpan = New-TimeSpan -Minutes $timeset
        $taskaction = New-ScheduledTaskAction -Execute "C:\testing_AI\AutoRun.bat"
        $trigger = New-JobTrigger -AtLogOn -RandomDelay $TimeSpan #00:05:00
        $Stset = New-ScheduledTaskSettingsSet -Priority 0 -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
        $user=[System.Security.Principal.WindowsIdentity]::GetCurrent().Name

        $STPrin= New-ScheduledTaskPrincipal   -User $user  -RunLevel Highest

        Register-ScheduledTask -Action $taskaction -Trigger $trigger -Settings $Stset -Force -TaskName "Auto_Run" -Principal $STPrin

        start-sleep -s 10
  
        $round=$countrb+1

        write-host "wait $waittime before reboot cycle: $round"
        Add-Content $rebootlog -value "reboot cycle: $round, $nowtime"


        Restart-Computer -Force

    }

}

  

  
    export-modulemember -Function  rebootn