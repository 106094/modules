function ChangeDisplayMode ([string]$para1,[string]$para2){

    $paracheck1=$PSBoundParameters.ContainsKey('para1')

    if($paracheck1 -eq $false -or  $para1.length -eq 0 ){
        $para1= "internal"
    }

     if($PSScriptRoot.length -eq 0){
        $scriptRoot="C:\testing_AI\modules\"
    }
    else{
        $scriptRoot=$PSScriptRoot
    }

    $nonlog_flag=$para2

    $action = "Change Display Mode to $para1"
    $tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
    $tcnumber=((get-content $tcpath).split(","))[0]
    $tcstep=((get-content $tcpath).split(","))[1]  
    $picpath=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\"
    if(-not(test-path $picpath)){new-item -ItemType directory -path $picpath |out-null}  
    $moninfo=$picpath+"$($timenow)_step$($tcstep)_monitorinfo.csv"

    $results = "OK"
    $index = "check screenshots"
    
    $mtool="C:\testing_AI\modules\MultiMonitorTool\MultiMonitorTool.exe"
    &$mtool /scomma $moninfo
    do{
    Start-Sleep -s 5
    }until(test-path  $moninfo)
    Start-Sleep -s 5
    
    $moninfodata=(import-csv $moninfo).name
    $numberOfMonitors = $moninfodata.Count
    $extendedMode = $numberOfMonitors -gt 1

    if ($extendedMode) {
    
    $actionss ="screenshot_multiscreen"        
    Get-Module -name $actionss |remove-module
    $mdpath=(Get-ChildItem -path $scriptRoot -r -file |Where-object{$_.name -match "^$actionss\b" -and $_.name -match "psm1"}).fullname
    Import-Module $mdpath -WarningAction SilentlyContinue -Global

        &$actionss  -para3 nonlog -para5 "change_display_mode_to_$($para1)_before"
        try {
        displayswitch.exe  /$para1
        Start-Sleep -s 10
        }
        catch{
            $results = "NG"
            $index="fail to change display mode"
        }

        &$actionss  -para3 nonlog -para5 "change_display_mode_to_$($para1)_after"

    }else{
        $results = "NG"
        $index="only one monitor"
    }


    #output log
    if($nonlog_flag.Length -eq 0){        
    Get-Module -name "outlog"|remove-module
    $mdpath=(Get-ChildItem -path "C:\testing_AI\modules\" -r -file |Where-object{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
    Import-Module $mdpath -WarningAction SilentlyContinue -Global
    #write-host "Do $action!"
    outlog $action $results $tcnumber $tcstep $index
    }
}
Export-ModuleMember -Function ChangeDisplayMode
