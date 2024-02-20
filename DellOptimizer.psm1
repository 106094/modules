function DellOptimizer([string]$para1,[string]$para2,[string]$para3){

    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force;
    $wshell=New-Object -ComObject wscript.shell
    Add-Type -AssemblyName Microsoft.VisualBasic
    Add-Type -AssemblyName System.Windows.Forms
    
    
    if($PSScriptRoot.length -eq 0){
        $scriptRoot="C:\testing_AI\modules"
    }
    else{
        $scriptRoot=$PSScriptRoot
    }
    
    $tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
    $tcnumber=((get-content $tcpath).split(","))[0]
    $tcstep=((get-content $tcpath).split(","))[1]
    
    $actioncp="startmenuapp"
    Get-Module -name $actioncp|remove-module
    $mdpath=(Get-ChildItem -path $scriptRoot -r -file |Where-object{$_.name -match "^$actioncp\b" -and $_.name -match "psm1"}).fullname
    Import-Module $mdpath -WarningAction SilentlyContinue -Global
    
    $actionPCAI="pcai"
    Get-Module -name $actionPCAI|remove-module
    $mdpathPCAI=(Get-ChildItem -path $scriptRoot -r -file |Where-object{$_.name -match "^$actionPCAI\b" -and $_.name -match "psm1"}).fullname
    Import-Module $mdpathPCAI -WarningAction SilentlyContinue -Global
    
    
    $actionss="screenshot"
    Get-Module -name $actionss|remove-module
    $sspath=(Get-ChildItem -path $scriptRoot -r -file |Where-object{$_.name -match "^$actionss\b" -and $_.name -match "psm1"}).fullname
    Import-Module $sspath -WarningAction SilentlyContinue -Global
    
    
    &$actioncp -para1 "Optimizer" -para3 "nonlog"
    
    Start-Sleep -s 30
    
    if( (Get-Package -Name "*Dell Optimizer*").version -match "4.2.0.0" ){
        [System.Windows.Forms.SendKeys]::SendWait("{TAB}");
        Start-Sleep -s 5
        [System.Windows.Forms.SendKeys]::SendWait("{ENTER}");
        Start-Sleep -s 5
        [System.Windows.Forms.SendKeys]::SendWait("{ENTER}");
        Start-Sleep -s 5
        [System.Windows.Forms.SendKeys]::SendWait("{ENTER}");
        Start-Sleep -s 5
        [System.Windows.Forms.SendKeys]::SendWait("{ENTER}");
        Start-Sleep -s 5
        [System.Windows.Forms.SendKeys]::SendWait("{ENTER}");
        Start-Sleep -s 5
        [System.Windows.Forms.SendKeys]::SendWait("{TAB}");
        Start-Sleep -s 2
        [System.Windows.Forms.SendKeys]::SendWait("{TAB}");
        Start-Sleep -s 2
        [System.Windows.Forms.SendKeys]::SendWait("{TAB}");
        Start-Sleep -s 2
        [System.Windows.Forms.SendKeys]::SendWait("{TAB}");
        Start-Sleep -s 2
        [System.Windows.Forms.SendKeys]::SendWait("{TAB}");
        Start-Sleep -s 2
        [System.Windows.Forms.SendKeys]::SendWait("{TAB}");
        Start-Sleep -s 2
        [System.Windows.Forms.SendKeys]::SendWait(" ");
        Start-Sleep -s 5
        [System.Windows.Forms.SendKeys]::SendWait("{TAB 3}");
        Start-Sleep -s 5
        [System.Windows.Forms.SendKeys]::SendWait("{ENTER}");
    }else{
        [System.Windows.Forms.SendKeys]::SendWait("{TAB}");
        Start-Sleep -s 5
        [System.Windows.Forms.SendKeys]::SendWait("{ENTER}");
        Start-Sleep -s 5
        [System.Windows.Forms.SendKeys]::SendWait("{ENTER}");
        Start-Sleep -s 5
        [System.Windows.Forms.SendKeys]::SendWait("{ENTER}");
        Start-Sleep -s 5
        [System.Windows.Forms.SendKeys]::SendWait("{ENTER}");
        Start-Sleep -s 5
        [System.Windows.Forms.SendKeys]::SendWait("{ENTER}");
        Start-Sleep -s 5
        [System.Windows.Forms.SendKeys]::SendWait("{ENTER}");
        Start-Sleep -s 5
        [System.Windows.Forms.SendKeys]::SendWait("{TAB}");
        Start-Sleep -s 2
        [System.Windows.Forms.SendKeys]::SendWait("{TAB}");
        Start-Sleep -s 2
        [System.Windows.Forms.SendKeys]::SendWait("{TAB}");
        Start-Sleep -s 2
        [System.Windows.Forms.SendKeys]::SendWait("{TAB}");
        Start-Sleep -s 2
        [System.Windows.Forms.SendKeys]::SendWait("{TAB}");
        Start-Sleep -s 2
        [System.Windows.Forms.SendKeys]::SendWait("{TAB}");
        Start-Sleep -s 2
        [System.Windows.Forms.SendKeys]::SendWait(" ");
        Start-Sleep -s 5
        [System.Windows.Forms.SendKeys]::SendWait("{TAB 3}");
        Start-Sleep -s 5
        [System.Windows.Forms.SendKeys]::SendWait("{ENTER}");
    }
    
        #Dell Optimizer HomePage
        if($para1 -eq "Analytics"){
            &$actionPCAI -para1 "Analytics" -para5 "nonlog"
        }
        if($para1 -eq "Applications"){
            &$actionPCAI -para1 "Applications" -para5 "nonlog"
        }
        if($para1 -eq "Audio"){
            &$actionPCAI -para1 "Audio" -para5 "nonlog"
        }
        if($para1 -eq "Option"){
            &$actionPCAI -para1 "Option" -para5 "nonlog"
            
            $optionlist = @{
                "Perferences" = 1
                "ActivityFeed" = 2
            }
    
            if( (Get-Package -Name "*Dell Optimizer*").version -notmatch "4.2.0.0" ){
                $optionlist.Add("Beta",3)
                $optionlist.Add("UserGuide",4)
                $optionlist.Add("GiveFeedback",5)
                $optionlist.Add("AboutDellOptimizer",6)
            }else{
                $optionlist.Add("UserGuide",3)
                $optionlist.Add("GiveFeedback",4)
                $optionlist.Add("AboutDellOptimizer",5)
            }
    
            Start-Sleep -s 5
            [System.Windows.Forms.SendKeys]::SendWait("{TAB $($optionlist[$para2])}");
            Start-Sleep -s 5
            [System.Windows.Forms.SendKeys]::SendWait("{ENTER}");
            Start-Sleep -s 5
            &$actionss -para3 "nonlog" -para5 "$($para1)_$($para2)" 
        }
    
    
        ######### write log #######
        if($nonlog_flag.Length -eq 0 -or $timespanmin -gt 30){
            Get-Module -name "outlog"|remove-module
            $mdpath=(Get-ChildItem -path "C:\testing_AI\modules\"  -r -file |Where-object{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
            Import-Module $mdpath -WarningAction SilentlyContinue -Global
            
            #write-host "Do $action!"
            outlog $action $results $tcnumber $tcstep $index
        }
    }
        
    export-modulemember -Function DellOptimizer