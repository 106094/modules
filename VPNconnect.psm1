

function VPNconnect([string]$para1){

    if($PSScriptRoot.length -eq 0){
        $scriptRoot="C:\testing_AI\modules"
    }
    else{
        $scriptRoot=$PSScriptRoot
    }

    if($para1.Length -eq 0){

    

        $testVpn = Get-VpnConnection -ErrorAction SilentlyContinue

        if($testVpn){
            $vpnName = $testVpn[0].Name
            $vpnServerAddress = $testVpn[0].ServerAddress

            $username = "vpn"  # 使用者名稱
            $password = "vpn" | ConvertTo-SecureString -AsPlainText -Force  # 密碼

            # 將密碼轉換為明文字串
            $passwordString = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($password))

            #Start-Process -NoNewWindow -FilePath "rasdial.exe" -ArgumentList "$vpnName $username $passwordString"

            $command = "rasdial.exe $vpnName $username $passwordString"
            $connectinfo = Invoke-Expression -Command $command

            Start-Sleep -Seconds 30

            $connectionStatus = (Get-VpnConnection -Name $vpnName).ConnectionStatus

            if ($connectionStatus -eq "Connected") {
                Write-Host "VPN Connect Successfully"
                $results="OK"
            }else{
                Write-Host "VPN Connect failed , delete this VPN"
                $results="NG"
                Remove-VpnConnection -Name $vpnName -Force
            }
        }
        else{
    
        $VPNlist = Invoke-WebRequest -Uri "http://www.vpngate.net/api/iphone/" -UseBasicParsing | ConvertTo-Csv

        #$pattern = "public-vpn-\d+,\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}"
        $pattern = "public-vpn-\d+,\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3},\d+,\d+,\d+,[A-Za-z]+,[A-Za-z]+"

        $matches = [regex]::Matches($VPNlist, $pattern)

        $JPlist = @()
        foreach ($match in $matches) {
        $match.Value
            $JPlist += $match.Value.Split(",")[0]
        }

    

        $i = 0
        do{
            $outs = "Public VPN TestConnect List -" + ($i + 1) + "/" +  ($JPlist.Count)
            Write-Output $outs
            #VPN Connect
            $vpnName = "VPNtest-Japan"
            $vpnServerAddress = $JPlist[$i].ToString() + ".opengw.net"

        
         
            Add-VpnConnection -Name $vpnName -ServerAddress $vpnServerAddress -PassThru

            $username = "vpn"  # 使用者名稱
            $password = "vpn" | ConvertTo-SecureString -AsPlainText -Force  # 密碼

            # 將密碼轉換為明文字串
            $passwordString = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($password))

            # 使用 rasdial 命令進行 VPN 連線
            #$connectinfo = Start-Process -NoNewWindow -FilePath "rasdial.exe" -ArgumentList "$vpnName $username $passwordString"

            $command = "rasdial.exe $vpnName $username $passwordString"
            $connectinfo = Invoke-Expression -Command $command


             # 等待連線建立
            Start-Sleep -Seconds 30

            $connectionStatus = (Get-VpnConnection -Name $vpnName).ConnectionStatus

            if ($connectionStatus -eq "Connected") {
                Write-Host "VPN Connect Successfully"
                $results="OK"
                break
            }else{
                Write-Host "VPN Connect failed , delete this VPN"
                $results="NG"
                Remove-VpnConnection -Name $vpnName -Force
            }

            $i++
        }until($i -ge $JPlist.Count)

        }


        $tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
        $tcnumber=((get-content $tcpath).split(","))[0]
        $tcstep=((get-content $tcpath).split(","))[1]

        $action="VPNconnect"
    
        $index="Last test VPN's DDNS Name : $vpnServerAddress"
    
        ######### write log #######
        Get-Module -name "outlog"|remove-module
        $mdpath=(Get-ChildItem -path "C:\testing_AI\modules\"  -r -file |?{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
        Import-Module $mdpath -WarningAction SilentlyContinue -Global

        #write-host "Do $action!"
        outlog $action $results $tcnumber $tcstep $index
    }
    else{
        

        $vpnName = "VPNtest-Japan"
        $vpnServerAddress = (Get-VpnConnection -Name $vpnName).ServerAddress

        rasdial.exe $vpnName /disconnect

        

        Remove-VpnConnection -Name $vpnName -Force


        $testvpn = Get-VpnConnection -Name $vpnName -ErrorAction SilentlyContinue

        if($testvpn){
            $results = "NG"
        }else{
            $results = "OK"
        }

        $tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
        $tcnumber=((get-content $tcpath).split(","))[0]
        $tcstep=((get-content $tcpath).split(","))[1]

        $action="VPNconnect"
    
        $index="Last test VPN's DDNS Name : "
    
        ######### write log #######
        Get-Module -name "outlog"|remove-module
        $mdpath=(Get-ChildItem -path "C:\testing_AI\modules\"  -r -file |?{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
        Import-Module $mdpath -WarningAction SilentlyContinue -Global

        #write-host "Do $action!"
        outlog $action $results $tcnumber $tcstep $index
    }    
    $output = ""
    
    $output += "This is Public VPN Info:`n"
    $output += "    Vpn Name:$($vpnName)`n"
    $output += "    VpnServerAddress:$($vpnServerAddress)`n"
    $output += "    Username:$($username)`n"
    $output += "    Password:$($passwordString)`n"
    
    $output += "Run rasdial.exe with powershell to connect VPN`n"
    $output += "The following is the command message:`n"
    $output += "rasdial.exe $vpnName $username $passwordString`n"
    $output += "Add-VpnConnection -Name $vpnName -ServerAddress $vpnServerAddress -PassThru`n"

    foreach($item in $connectinfo){
        $output += "$($item)`n"
    }

    $output += "$($action)_$($index)"
    $datenow=get-date -format "yyMMdd_HHmmss"
    $output | Out-File -FilePath "C:\testing_AI\logs\$tcnumber\$($datenow)_step$($tcstep)_VPNconnectInfo.txt" -Encoding unicode

}



export-modulemember -Function VPNconnect