
Function DiskCheck([string]$para1, [string]$para2){
    
    Add-Type -AssemblyName System.Windows.Forms

    if($PSScriptRoot.length -eq 0){
        $scriptRoot="C:\testing_AI\modules\"
    }
    else{
        $scriptRoot=$PSScriptRoot
    }

    $tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
    $tcnumber=((get-content $tcpath).split(","))[0]
    $tcstep=((get-content $tcpath).split(","))[1]


    $actionss ="screenshot"
    Get-Module -name $actionss|remove-module
    $mdpath=(gci -path $scriptRoot -r -file |?{$_.name -match "^$actionss\b" -and $_.name -match "psm1"}).fullname
    Import-Module $mdpath -WarningAction SilentlyContinue -Global



    if($para1.Length -eq 0){
        $disklist = Get-WmiObject -Class Win32_LogicalDisk | ?{$_.providername -notlike "\\*"}  | Select-Object DeviceID
    }else{
        $disklist = $para1
    }

    
    
    
    $diskjud = Get-WmiObject -Class Win32_LogicalDisk | ?{$_.providername -notlike "\\*"}
    if($diskjud.DeviceID -match $disklist){         
        foreach ($list in $disklist) {
            if($para1.Length -eq 0){
                $filePath = $list.DeviceID  # 請將路徑替換為實際的檔案路徑
                $scname = $list.DeviceID.Substring(0,1) + "-Disk"
            }else{
                $filePath = $list
                $scname = $list.Substring(0,1) + "-Disk"
            }

            # 使用 Start-Process 打開檔案屬性
            Start-Process "explorer.exe" -ArgumentList "/select, $filePath"

            Start-Sleep -s 30

            [System.Windows.Forms.SendKeys]::SendWait("%~")

            Start-Sleep -s 5


            if($para2.Length -ne 0){
                Start-Sleep -s 8

                [System.Windows.Forms.SendKeys]::SendWait("+{TAB}")

                Start-Sleep -s 5

                [System.Windows.Forms.SendKeys]::SendWait("{RIGHT}")

                Start-Sleep -s 5

                [System.Windows.Forms.SendKeys]::SendWait("{TAB}")

                Start-Sleep -s 5

                #$dlllist = get-process -Name "*dllhost*"

                Start-Sleep -s 5

                [System.Windows.Forms.SendKeys]::SendWait("C")

                Start-Sleep -s 8

                [System.Windows.Forms.SendKeys]::SendWait(" ")

        
                do{
                    echo "Watting for diskcheck complete..."
                    #$dllhostfordiskcheck = Get-Process -Name "*dllhost*"
                    Start-Sleep -s 5
                    [System.Windows.Forms.SendKeys]::SendWait("^c")

                }until( (Get-Clipboard) -match "Footer" )

                echo "Diskcheck complete!!"

                Set-Clipboard -Value " "

                screenshot -para3 "nonlog" -para5 ($scname + "-check")

                Start-Sleep -s 5
        
                [System.Windows.Forms.SendKeys]::SendWait(" ")

                Start-Sleep -s 5
            }else{
                screenshot -para3 "nonlog" -para5 $scname
            }

            Start-Sleep -s 5

            Stop-Process -Name "explorer"
        }
        $results = "OK"
    }
    else{
        $results = "NG"
    }


    $action = "checkScreenshot"
    

    ######### write log #######
    Get-Module -name "outlog"|remove-module
    $mdpath=(gci -path "C:\testing_AI\modules\"  -r -file |?{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
    Import-Module $mdpath -WarningAction SilentlyContinue -Global

    #write-host "Do $action!"
    outlog $action $results $tcnumber $tcstep $index
}


# 匯出模組成員
Export-ModuleMember -Function DiskCheck