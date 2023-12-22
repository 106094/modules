

function check_IRST (){
    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force;
    Add-Type -AssemblyName System.Windows.Forms

    if($PSScriptRoot.length -eq 0){
        $scriptRoot="C:\testing_AI\modules"
    }else{
        $scriptRoot=$PSScriptRoot
    }

    $actionss="screenshot"
    Get-Module -name $actionss |remove-module
    $mdpath=(gci -path $scriptRoot -r -file |?{$_.name -match "^$actionss\b" -and $_.name -match "psm1"}).fullname
    Import-Module $mdpath -WarningAction SilentlyContinue -Global

    $tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
    $tcnumber=((get-content $tcpath).split(","))[0]
    $tcstep=((get-content $tcpath).split(","))[1]

    # Search IRST Path
    $fileToSearch = "IAStorUI.exe"

    try{
    $filePath = Get-Item -Path (Get-ChildItem -Recurse -Filter $fileToSearch -Path "C:\Program Files\Intel\Intel(R) Virtual RAID on CPU" -ErrorAction SilentlyContinue).FullName
    $filePath = Get-Item -Path (Get-ChildItem -Recurse -Filter $fileToSearch -Path "C:\Program Files (x86)\Intel\Intel(R) Virtual RAID on CPU" -ErrorAction SilentlyContinue).FullName
    }catch{
        if($filePath){
            $_.Exception.Message
            $results = "OK"
        }else{
            $results = "NG"
            $index = "Not exist Intel(R) Virtual RAID on CPU"
        }      
    }
    # Open IRST
    &$filepath.FullName

    Start-Sleep -s 60

    if(Get-Process -Name "IAStorUI"){
        [System.Windows.Forms.SendKeys]::Sendwait("{TAB}")
        $tablist = @("manage","disk","createRAID","notification","appsettings","scheduler","systemReport","about") 
        
        $i = 1
        foreach($tab in $tablist){
            Start-Sleep -s 5
            [System.Windows.Forms.SendKeys]::Sendwait("{Down}")   
            screenshot -para3 "nonlog" -para5 "step$($tcstep)_IRST_$i"  
            $i += 1    
        }
    }else{
        $results = "NG"
        $index = "IRST Open Failed" 
    }

    $action = "check screenshot"
    
    ######### write log #######
    Get-Module -name "outlog"|remove-module
    $mdpath=(gci -path "C:\testing_AI\modules\"  -r -file |?{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
    Import-Module $mdpath -WarningAction SilentlyContinue -Global

    #write-host "Do $action!"
    outlog $action $results $tcnumber $tcstep $index

}

Export-ModuleMember -Function check_IRST