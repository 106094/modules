function ChangeDisplayMode ([string]$para1){

    $paracheck1=$PSBoundParameters.ContainsKey('para1')

    if($paracheck1 -eq $false -or  $para1 -eq 0 ){
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


    $displaySettings = Get-WmiObject -Namespace root\cimv2 -Class Win32_DesktopMonitor
    $extendedMode = $displaySettings.Count -gt 1

    if ($extendedMode) {
        $results = "OK"
        $action = "Change Display Mode to $para1"


        
        displayswitch.exe  /$para1
        Start-Sleep -s 10
    }else{
        $results = "NG"
    }


    #output log
    Get-Module -name "outlog"|remove-module
    $mdpath=(Get-ChildItem -path "C:\testing_AI\modules\" -r -file |?{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
    Import-Module $mdpath -WarningAction SilentlyContinue -Global
    #write-host "Do $action!"
    outlog $action $results $tcnumber $tcstep $index
}
Export-ModuleMember -Function ChangeDisplayMode
