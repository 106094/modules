function DMaction ([string]$para1, [string]$para2){
    devmgmt.msc
    Add-Type -AssemblyName System.Windows.Forms

    $paracheck1=$PSBoundParameters.ContainsKey('para1')
    $paracheck1=$PSBoundParameters.ContainsKey('para2')

    #SATASettings
    if($paracheck1 -eq $false -or $para1.Length -eq 0){
        $para1="Scan"
    }

    $action = $para1
    $deviceName = $para2

    if($PSScriptRoot.length -eq 0){
        $scriptRoot="C:\testing_AI\modules"
    }else{
        $scriptRoot=$PSScriptRoot
    }

    $actionss="screenshot"
    Get-Module -name $actionss |remove-module
    $mdpath=(gci -path $scriptRoot -r -file |?{$_.name -match "^$actionss\b" -and $_.name -match "psm1"}).fullname
    Import-Module $mdpath -WarningAction SilentlyContinue -Global


    $DMcount = ((Get-WmiObject Win32_PnPEntity).PNPClass | Sort-Object -Unique).count 
    
    $a = (Get-WmiObject Win32_PnPEntity) | Where-Object { $_.Name -eq $deviceName}
    $a.PNPClass


    screenshot -para3 nolog -para5 "beforeAction"
    #Region Action -----------------------------------------------

    if($action -eq "Scan"){
        Start-Sleep -s 5

        [System.Windows.Forms.SendKeys]::SendWait("{tab}")
        Start-Sleep -s 2
        [System.Windows.Forms.SendKeys]::SendWait("%a")
        Start-Sleep -s 2
        [System.Windows.Forms.SendKeys]::SendWait("a")
        Start-Sleep -s 2
        [System.Windows.Forms.SendKeys]::SendWait("{Enter}")
    }


    if($action -eq "DriverDetails"){
       
    }
    if($action -eq "UpdateDriver"){
       
    }
    if($action -eq "Rollback"){
       
    }
    if($action -eq "DisableDevice"){
       
    }
    if($action -eq "UninstallDevice"){
       
    }


    #EndRegion-----------------------------------------------
    screenshot -para3 nolog -para5 "AfterAction"
}


Export-ModuleMember -Function DMaction