

function dcu_updatedriver (){
    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force;
    Add-Type -AssemblyName System.Windows.Forms

    if($PSScriptRoot.length -eq 0){
        $scriptRoot="C:\testing_AI\modules"
    }else{
        $scriptRoot=$PSScriptRoot
    }

    $tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
    $tcnumber=((get-content $tcpath).split(","))[0]
    $tcstep=((get-content $tcpath).split(","))[1]

    #Change txt
    #necessary item : XmlPath , DUPPath , releaseID(packageID) , vendorVersion
    $XmlPath = "C:\Users\andyliao22060\Downloads\102634\Precision_0AAA.xml"
    $DUPPath = "C:\Users\andyliao22060\Downloads\102634\NVIDIA-Quadro-Pxxxx-RTX-xxxx-RTX-Axxxx-Txxxx-Axxx_V21R9_WIN64_31.0.15.3770_A00.EXE"
    
    $firstBackslashIndex = $DUPPath.IndexOf('\')
    $diskPath = $DUPPath.Substring(0, $firstBackslashIndex+1)
    $remainingPath = $DUPPath.Substring($firstBackslashIndex+1)

    $XmlContent = Get-Content -Path $XmlPath
    $xmlObject = [xml]$XmlContent

    #Manifest
    $xmlObject.Manifest.baseLocation = $diskPath
    
    #Manifest_SoftwareComponent
    $xmlObject.Manifest.SoftwareComponent.releaseID = "V21R9"
    $xmlObject.Manifest.SoftwareComponent.vendorVersion = "31.0.15.3770"
    $xmlObject.Manifest.SoftwareComponent.path = $remainingPath
    $xmlObject.Manifest.SoftwareComponent.packageID = "V21R9"
    $xmlObject.Manifest.SoftwareComponent.size = (Get-ChildItem $DUPPath).Length


    #Get DUP hash
    $hash_MD5 = Get-FileHash -Path $DUPPath -Algorithm MD5
    $hash_SHA256 = Get-FileHash -Path $DUPPath -Algorithm SHA256
    $hash_SHA1 = Get-FileHash -Path $DUPPath -Algorithm SHA1
    #Chang Hash code
    $xmlObject.Manifest.SoftwareComponent.Cryptography.Hash[0].'#text' = $hash_MD5.hash
    $xmlObject.Manifest.SoftwareComponent.Cryptography.Hash[1].'#text' = $hash_SHA256
    $xmlObject.Manifest.SoftwareComponent.Cryptography.Hash[2].'#text' = $hash_SHA1


    # Save the modified XML content to a new file
    $ModifiedXmlPath = "C:\Users\andyliao22060\Downloads\102634\Precision_0AAA_2.xml"
    $xmlObject.Save($ModifiedXmlPath)
    #$modifiedXmlString = $xmlObject.OuterXml
    #$modifiedXmlString | Out-File -FilePath "C:\Users\andyliao22060\Downloads\102634\Precision_0AAA_2.xml" -Encoding UTF8 -Append -NoNewline



    ######### write log #######
    Get-Module -name "outlog"|remove-module
    $mdpath=(gci -path "C:\testing_AI\modules\"  -r -file |?{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
    Import-Module $mdpath -WarningAction SilentlyContinue -Global

    #write-host "Do $action!"
    outlog $action $results $tcnumber $tcstep $index
}

Export-ModuleMember -Function dcu_updatedriver