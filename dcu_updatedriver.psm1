

function dcu_updatedriver ([string]$para1 , [string]$para2 , [string]$para3 , [string]$para4){
    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force;
    Add-Type -AssemblyName System.Windows.Forms

    if($PSScriptRoot.length -eq 0){
        $scriptRoot="C:\testing_AI\modules"
    }else{
        $scriptRoot=$PSScriptRoot
    }

    $actionss ="screenshot"
    Get-Module -name $actionss|remove-module
    $mdpath=(Get-ChildItem -path $scriptRoot -r -file | Where-Object {$_.name -match "^$actionss\b" -and $_.name -match "psm1"}).fullname
    Import-Module $mdpath -WarningAction SilentlyContinue -Global

    $actionsa ="startmenuapp"
    Get-Module -name $actionsa|remove-module
    $mdpath=(Get-ChildItem -path $scriptRoot -r -file | Where-Object {$_.name -match "^$actionsa\b" -and $_.name -match "psm1"}).fullname
    Import-Module $mdpath -WarningAction SilentlyContinue -Global

    $tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
    $tcnumber=((get-content $tcpath).split(","))[0]
    $tcstep=((get-content $tcpath).split(","))[1]

    #Change txt
    #necessary item : XmlPath , DUPPath , releaseID(packageID) , vendorVersion
    $XmlPath = $para1
    $DUPPath = $para2
    
    $firstBackslashIndex = $DUPPath.IndexOf('\')
    $diskPath = $DUPPath.Substring(0, $firstBackslashIndex+1)
    $remainingPath = $DUPPath.Substring($firstBackslashIndex+1)

    $XmlContent = Get-Content -Path $XmlPath
    $xmlObject = [xml]$XmlContent

    #Manifest
    $xmlObject.Manifest.baseLocation = $diskPath
    
    #Manifest_SoftwareComponent
    $xmlObject.Manifest.SoftwareComponent.releaseID = $para3
    $xmlObject.Manifest.SoftwareComponent.vendorVersion = $para4
    $xmlObject.Manifest.SoftwareComponent.path = $remainingPath
    $xmlObject.Manifest.SoftwareComponent.packageID = $para3
    $xmlObject.Manifest.SoftwareComponent.size = (Get-ChildItem $DUPPath).Length.ToString()

    #Get DUP hash
    $hash_MD5 = Get-FileHash -Path $DUPPath -Algorithm MD5
    $hash_SHA256 = Get-FileHash -Path $DUPPath -Algorithm SHA256
    $hash_SHA1 = Get-FileHash -Path $DUPPath -Algorithm SHA1
    #Chang Hash code
    $xmlObject.Manifest.SoftwareComponent.Cryptography.Hash[0].'#text' = $hash_MD5.hash
    $xmlObject.Manifest.SoftwareComponent.Cryptography.Hash[1].'#text' = $hash_SHA256
    $xmlObject.Manifest.SoftwareComponent.Cryptography.Hash[2].'#text' = $hash_SHA1

    # Save the modified XML content to a new file
    $xmlObject.Save($XmlPath)

    &$actionsa -para1 "dell command" -para3 "nonlog"

    Start-Sleep -s 20
    [System.Windows.Forms.SendKeys]::Sendwait({"TAB"})
    Start-Sleep -s 5
    [System.Windows.Forms.SendKeys]::Sendwait({"ENTER"})
    Start-Sleep -s 5
    [System.Windows.Forms.SendKeys]::Sendwait({"TAB 9"})
    Start-Sleep -s 5
    [System.Windows.Forms.SendKeys]::Sendwait({"+"})
    Start-Sleep -s 5
    [System.Windows.Forms.SendKeys]::Sendwait({"TAB 3"})
    Start-Sleep -s 5
    [System.Windows.Forms.SendKeys]::Sendwait({"ENTER"})
    Start-Sleep -s 5
    [System.Windows.Forms.SendKeys]::Sendwait($XmlPath)
    Start-Sleep -s 5
    [System.Windows.Forms.SendKeys]::Sendwait({"ENTER"})
    Start-Sleep -s 5
    [System.Windows.Forms.SendKeys]::Sendwait({"TAB"})
    Start-Sleep -s 5
    [System.Windows.Forms.SendKeys]::Sendwait({"ENTER"})
    Start-Sleep -s 5
    [System.Windows.Forms.SendKeys]::Sendwait({"TAB 6"})
    Start-Sleep -s 5
    [System.Windows.Forms.SendKeys]::Sendwait({"-"})
    Start-Sleep -s 5
    [System.Windows.Forms.SendKeys]::Sendwait({"TAB 10"})
    Start-Sleep -s 5
    [System.Windows.Forms.SendKeys]::Sendwait({"ENTER"})
    Start-Sleep -s 5
    [System.Windows.Forms.SendKeys]::Sendwait({"TAB 8"})
    Start-Sleep -s 5
    [System.Windows.Forms.SendKeys]::Sendwait({"ENTER"})

    #4 + 4
    #Get-Process NVMUP + DUP


    #Loading XML
    Start-Sleep -s 60
    &$actionss -para3 "nonlog" -para5 "XMLFileLoad"


    ######### write log #######
    Get-Module -name "outlog"|remove-module
    $mdpath=(Get-ChildItem -path "C:\testing_AI\modules\"  -r -file |Where-Object{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
    Import-Module $mdpath -WarningAction SilentlyContinue -Global

    #write-host "Do $action!"
    outlog $action $results $tcnumber $tcstep $index
}

Export-ModuleMember -Function dcu_updatedriver