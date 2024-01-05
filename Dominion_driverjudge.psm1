function Dominion_driverjudge (){
    if($PSScriptRoot.length -eq 0){
        $scriptRoot="C:\testing_AI\modules"
    }
    else{
        $scriptRoot=$PSScriptRoot
    }

    $actioncp="copyingfiles"
    Get-Module -name $actioncp|remove-module
    $mdpath=(Get-ChildItem -path $scriptRoot -r -file |Where-object{$_.name -match "^$actioncp\b" -and $_.name -match "psm1"}).fullname
    Import-Module $mdpath -WarningAction SilentlyContinue -Global
    
    $tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
    $tcnumber=((get-content $tcpath).split(","))[0]
    $tcstep=((get-content $tcpath).split(","))[1]


    $inidrv=(Get-ChildItem "C:\testing_AI\logs\ini*\*" -r -Filter "*DriverVersion.csv"|Sort-Object lastwritetime|select -last 1).FullName
    $checktype=(import-csv $inidrv|Where-object{$_.DeviceClass -match "DISPLAY"}).devicename
    
    if($inidrv -and $checktype){
        if($checktype -match "NVIDIA"){
            $drvtype2="NV_general"
            if($checktype -match "ada"){
                $drvtype2="NV_A6000ada"
            }
            write-host "The Display Driver is $($drvtype2)"
        }

        if($checktype -match "AMD"){
            $chekdrv=$checktype -match "[a-zA-Z]\d{4}"
            if(!$chekdrv){$checktype -match "\d{4}"}
            $drvtype2="AMD_"+$matches[0]
            write-host "The Display Driver is $($drvtype2)"
        }

        ## check if folder exist

        $drvfd="$scriptRoot\driver\GFX\$($drvtype2)"

        ## if no exist, copy it from server
        if(!(test-path $drvfd )){
            &$actioncp -para1 "\\192.168.2.249\srvprj\Inventec\Dell\Matagorda\07.Tool\_AutoTool\driver\GFX" -para2 "$scriptRoot\driver" -para3 nolog
        }


        ## copy for Dominion gfx driver
        $duppath = "C:\testing_AI\modules\driver\GFX\$drvtype2\N\driver\*.zip"

        if($checktype -match "AMD"){
            $duppath = "C:\testing_AI\modules\driver\GFX\$drvtype2\N\*.zip"
        }
        
        &$actioncp -para1 $duppath -para2 "C:\testing_AI\logs\TC-102152\" -para3 nolog
        


        if(Test-Path -Path $duppath){
            $results="OK"
            $index="driverReady"
            echo "Gfx Driver zip is ready to PCAI script."
        }else{
            $results="NG"
            $index="Not have driver mup"
            echo "Not have driver mup."
        }
    }
    else{
        $results="NG"
        $index="cannot find initial driver infomation"
    }

    

    ######### write log #######
    Get-Module -name "outlog"|remove-module
    $mdpath=(Get-ChildItem -path "C:\testing_AI\modules\"  -r -file |Where-object{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
    Import-Module $mdpath -WarningAction SilentlyContinue -Global

    #write-host "Do $action!"
    outlog $action $results $tcnumber $tcstep $index


}

export-modulemember -Function Dominion_driverjudge