
function driver_uninstall_ControlPanel ([string]$para1,[string]$para2){
    
    start-sleep -s 30
    #import
    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force;
    $wshell=New-Object -ComObject wscript.shell
    $shell=New-Object -ComObject shell.application
    Add-Type -AssemblyName Microsoft.VisualBasic
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Windows.Forms,System.Drawing
    
    #ini parameter
    $pkgename=$para1
    $nonlog_flag=$para2     

    if($pkgename -eq "^display\b" -or $pkgename -match "^Gfx\b" -or $pkgename -eq "^graphics\b"){

        $pkgename=""
        #$drvname=(Get-WmiObject Win32_VideoController | Select-Object name|Where-object{$_.name -match "NVIDIA"} ).name
        #$drvname2=(Get-WmiObject Win32_VideoController | Select-Object name|Where-object{$_.name -match "AMD"} ).name
 
 $inidrv=(Get-ChildItem "C:\testing_AI\logs\ini*" -r -Filter "*DriverVersion.csv"|Sort-Object lastwritetime|select -last 1).FullName

if($inidrv){
$drvname=(import-csv $inidrv|Where-object{$_.DeviceClass -match "DISPLAY"}).devicename
if($drvname -match "NVIDIA"){
$pkgename="NVIDIA"
}
if($drvname -match "AMD"){
$pkgename="AMD"
}
  write-host "Driver: $($pkgename)"

}
    
    }

    if($PSScriptRoot.length -eq 0){
        $scriptRoot="C:\testing_AI\modules"
    }
    else{
        $scriptRoot=$PSScriptRoot
    }

    #import moudle
    $actionss="screenshot"
    Get-Module -name $actionss|remove-module
    $mdpath=(Get-ChildItem -path $scriptRoot -r -file |Where-object{$_.name -match "^$actionss\b" -and $_.name -match "psm1"}).fullname
    Import-Module $mdpath -WarningAction SilentlyContinue -Global

    #import moudle
    $actionts="taskschedule_atlogin"
    Get-Module -name $actionts|remove-module
    $mdpath=(Get-ChildItem -path $scriptRoot -r -file |Where-object{$_.name -match "^$actionts\b" -and $_.name -match "psm1"}).fullname
    Import-Module $mdpath -WarningAction SilentlyContinue -Global

    
    #import moudle
    $actiontsd="taskschedule_delete"
    Get-Module -name $actiontsd|remove-module
    $mdpath=(Get-ChildItem -path $scriptRoot -r -file |Where-object{$_.name -match "^$actiontsd\b" -and $_.name -match "psm1"}).fullname
    Import-Module $mdpath -WarningAction SilentlyContinue -Global


    #catch current tc
    $tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
    $tcnumber=((get-content $tcpath).split(","))[0]
    $tcstep=((get-content $tcpath).split(","))[1]
    $action=((get-content $tcpath).split(","))[2]

    $picpath=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\"
    if(-not(test-path $picpath)){new-item -ItemType directory -path $picpath |out-null}
    $installrecord=$picpath+"step$($tcstep)_uninstall_log.txt"
     if(-not(test-path $installrecord)){
     new-item -path $installrecord |out-null
      $timenow=get-date -format "yyMMdd_HHmmss"
      add-content -path $installrecord -value "start record:  $timenow "
     
     }

    $index=@()
           
    $controlpn="Control Panel\Programs\Programs and Features"
   
    if($pkgename.length -ne 0){   
                                          
        $packages_original = Get-Package |Where-object{$_.name -like "*$pkgename*" -and $_.version -ne $null}

      if($packages_original){

        $packages=$packages_original.name
        
       if($pkgename -eq "NVIDIA" ){

        $rankings = @(
        "NVIDIA Nsight Visual Studio Edition",
        "NVIDIA Graphics Driver",
        "NVIDIA Nsight Systems",
        "NVIDIA RTX Desktop Manager",
        "NVIDIA PhysX System Software",
        "NVIDIA Nsight Compute",
        "NVIDIA HD Audio Driver",
        "NVIDIA - Display"
        )

        # Sort the list based on the custom ranking
        $packages=@()
        $packages=foreach ($ranking in $rankings){
         ($packages_original.name)|Where-object{
         if($_ -match $ranking){$_}
         }         
         }
         

          }
      
       if($pkgename -eq "AMD" ){

        $rankings = @("AMD Software")

        # Sort the list based on the custom ranking

        $packages = foreach ($ranking in $rankings){
         $packages_original.name -match $ranking
         
         }
  
          }             
   
        if($packages.count -ne 0){
        
        ## start uninstall ##
        
            foreach ($package in $packages){
             
             write-host "start to uninstall $package"

                $timenow=get-date -format "yyMMdd_HHmmss"
                $index=$index+("$package uninstall start - $($timenow)")
                
                ## screenshot 1st time

                #Start-Process control -Verb Open -WindowStyle Maximized
                appwiz.cpl

                start-sleep -s 5
                $wshell.SendKeys("% ")
                $wshell.SendKeys("x")
                start-sleep -s 2

                &$actionss  -para3 nonlog -para5 "_uninstall_$($package)_before"

                $shell.Windows() |Where-object{$_.name -eq "File Explorer"}| ForEach-Object { $_.Quit() }
                start-sleep -s 5

                #Start-Process control -Verb Open -WindowStyle Maximized
                appwiz.cpl

                start-sleep -s 5
                            
                #$ctlpath="$controlpn\$package" 
                $ctlpath="$package" 
                
                ###enter delete path
                $wshell.SendKeys("^l")
                Set-Clipboard $ctlpath
                Start-Sleep -s 5
                $wshell.SendKeys("^v")
                Start-Sleep -s 1
                
                $timestart1=get-date
                
                $wshell.SendKeys("~")
                Start-Sleep -s 10

                  &$actionss  -para3 nonlog -para5 "uninstall_$($package)_start"

                if($pkgename -match "NVIDIA"){

                  
                    $wshell.SendKeys("y")
                    Start-Sleep -s 2
                    $wshell.SendKeys("u")
                    $process_uninstall=(get-process * |Where-object{$_.starttime -gt $timestart1 }).ProcessName
                    $process_uninstall2=$process_uninstall|out-string
                    write-host "uninstall programs of $($pkgename): $($ctlpath)"
                    if($process_uninstall.count -eq 0){
                        write-host "$($process_uninstall29)"
                    }
                    else{
                        write-host "na"
                    }
                }

                if($pkgename -match "AMD"){

                ## do something after start uninsatll AMD driver
                    $timestart1=get-date
                    $wshell.SendKeys("~")
                    Start-Sleep -Seconds 120
                    $wshell.SendKeys("~")
                    $process_uninstall=(get-process * |Where-object{$_.starttime -gt $timestart1 }).ProcessName
                    $process_uninstall2=$process_uninstall|out-string
                    write-host "uninstall programs of $($pkgename): "
                    if($process_uninstall.count -eq 0){
                        write-host "$process_uninstall2"
                    }
                    else{
                        write-host "na"
                    }
                    
                    $flag = 1
                }


                ## wait uninstall processing
                Start-Sleep -s 60

                if($flag.Length -eq 0){
                    do{
                    start-sleep -s 2
                    $packages = (Get-Package |Where-object{$_.name -eq $package}).name
                    }until($packages.count -eq 0)
                }
                                    
                $timenow=get-date -format "yyMMdd_HHmmss"
                $index=$index+("$package uninstall done  - $($timenow)")

                #add-content -path $installrecord -Value $index|Out-String

                 &$actionss  -para3 nonlog -para5 "_uninstall_$($package)_done"

                Start-Sleep -s 5

                if($pkgename -match "NVIDIA"){
                $wshell.SendKeys("l")
                }

                $shell.Windows() |Where-object{$_.name -eq "File Explorer"}| ForEach-Object { $_.Quit() }
                start-sleep -s 5

                ## screenshot after

                #Start-Process control -Verb Open -WindowStyle Maximized
                appwiz.cpl

                start-sleep -s 5

                &$actionss  -para3 nonlog -para5 "uninstall_$($package)_after"

                $shell.Windows() |Where-object{$_.name -eq "File Explorer"}| ForEach-Object { $_.Quit() }


                &$actionts -para3 nonlog

                #---reboot

                
                $timenow=get-date -format "yyMMdd_HHmmss"
                $index=$index+("reboot  - $($timenow)")
                add-content -path $installrecord -Value $index|Out-String
                start-sleep -s 5

                Restart-Computer -Force

            }

           

        }
        
        }

        write-host "uninstall complete, no related programs were found"

         $timenow=get-date -format "yyMMdd_HHmmss"
         add-content -path $installrecord -value "$($timenow) , no related programs were found (uninstall complete)"
       
        ### uninstall complete

        start-sleep -s 60

        $timenow=get-date -format "yyMMdd_HHmmss"
        add-content -path $installrecord -value "end record:  $timenow "
        $ren=$timenow+"_"+(Split-Path -leaf $installrecord)
        Rename-Item -Path $installrecord -NewName $ren
        $results="check index"
        $index="check $ren"
        &$actiontsd -para1 nonlog
        
        }

    else{
        $results="NG"
        $index="No define uninstall target name"
    }

######### write log #######

if($nonlog_flag.Length -eq 0){

Get-Module -name "outlog"|remove-module
$mdpath=(Get-ChildItem -path "C:\testing_AI\modules\"  -r -file |Where-object{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

#write-host "Do $action!"
outlog $action $results $tcnumber $tcstep $index
}

   }

    export-modulemember -Function driver_uninstall_ControlPanel