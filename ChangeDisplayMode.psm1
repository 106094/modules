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


    $tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
    $tcnumber=((get-content $tcpath).split(","))[0]
    $tcstep=((get-content $tcpath).split(","))[1]
    $action = "Change Display Mode to $para1"
        
    $actionss ="screenshot"
    $results = "OK"
    $index = "check screenshots"

    Get-Module -name $actionss|remove-module
    $mdpath=(Get-ChildItem -path $scriptRoot -r -file |Where-object{$_.name -match "^$actionss\b" -and $_.name -match "psm1"}).fullname
    Import-Module $mdpath -WarningAction SilentlyContinue -Global

    $displaySettings = Get-WmiObject -Namespace root\cimv2 -Class Win32_DesktopMonitor
    $extendedMode = $displaySettings.Count -gt 1

    if ($extendedMode) {
        
        try {
        displayswitch.exe  /$para1
        Start-Sleep -s 10
        }
        catch{
            $results = "NG"
        }

    }else{
        $results = "NG"
        $index="only one monitor"
    }


    #output log
    Get-Module -name "outlog"|remove-module
    $mdpath=(Get-ChildItem -path "C:\testing_AI\modules\" -r -file |Where-object{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
    Import-Module $mdpath -WarningAction SilentlyContinue -Global
    #write-host "Do $action!"
    outlog $action $results $tcnumber $tcstep $index
}
Export-ModuleMember -Function ChangeDisplayMode
