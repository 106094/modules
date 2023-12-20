
function sharefolder_everyone() {

    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force;
    $wshell=New-Object -ComObject wscript.shell
      Add-Type -AssemblyName Microsoft.VisualBasic
      Add-Type -AssemblyName System.Windows.Forms
 
$actionss ="screenshot"
Get-Module -name $actionss|remove-module
$mdpath=(gci -path $scriptRoot -r -file |?{$_.name -match "^$actionss\b" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global
       
      

if($PSScriptRoot.length -eq 0){
$scriptRoot="C:\testing_AI\modules\"
}
else{
$scriptRoot=$PSScriptRoot
}



<#
#Remove-LocalUser -name "user001"
$paswd=ConvertTo-SecureString "allion001" -AsPlainText -force
new-LocalUser -name "user001" -Password $paswd

Add-LocalGroupMember -Group "Administrators" -Member "user001"

$username="$env:USERDOMAIN\user001"
$netname= "C"
$domainname=(get-ItemProperty -path "HKLM:\SYSTEM\CurrentControlSet\Control\Computername\Computername").Computername
$connectname1="\\$domainname\C"
$mainuser=$env:username

### set user001 authority ###>

#Get-NetFirewallRule -DisplayGroup ‘Network Discovery’|Set-NetFirewallRule -Profile ‘Private, Domain’ -Enabled true.
$netname= "C"

if( ((get-SmbShare　-name $netname -ea SilentlyContinue).name) -eq $null){

$acl = Get-Acl "C:\"
$acl2 = Get-Acl "C:\users\$env:USERname"

$AccessRule  = [System.Security.AccessControl.FileSystemAccessRule]::new('Everyone',"FullControl","ContainerInherit,ObjectInherit","None","Allow" )
$acl.AddAccessRule($AccessRule)
$acl2.AddAccessRule($AccessRule)

# Flush the inherited permissions, and protect your new rules from overwriting by inheritance
$acl.SetAccessRuleProtection($True, $False)
$acl2.SetAccessRuleProtection($True, $False)

# Output what the new access rules actually look like:
#$acl.Access | ft

$acl | Set-Acl "C:\" 
$acl2 | Set-Acl "C:\users\$env:USERname"

## set net share folder ###

New-SmbShare -name  $netname  -path  "C:\"  -FullAccess 'Everyone'


## 　Adds an allow access
Grant-SmbShareAccess -Name $netname -AccountName 'Everyone'　-AccessRight Full -Force

### setting turn off passwd protection ##
#explorer.exe shell:::{8E908FC9-BECC-40f6-915B-F4CA0E70D03D}

control /name Microsoft.NetworkAndSharingCenter
Start-Sleep -s 30
 $id=((Get-Process *)|?{$_.MainWindowTitle -match "Network"}).Id

 [Microsoft.VisualBasic.interaction]::AppActivate($id)|out-null

[System.Windows.Forms.SendKeys]::SendWait("+{tab}")
Start-Sleep -s 1
[System.Windows.Forms.SendKeys]::SendWait("+{tab}")
Start-Sleep -s 1
[System.Windows.Forms.SendKeys]::SendWait("+{tab}")
Start-Sleep -s 1
[System.Windows.Forms.SendKeys]::SendWait("+{tab}")
Start-Sleep -s 1
[System.Windows.Forms.SendKeys]::SendWait(" ")
Start-Sleep -s 3

$winv= ([System.Environment]::OSVersion.Version).Build
if($winv -ge 22000){
Start-Sleep -s 3

[System.Windows.Forms.SendKeys]::SendWait("{tab}")
Start-Sleep -s 1
[System.Windows.Forms.SendKeys]::SendWait("{tab}")
Start-Sleep -s 1
[System.Windows.Forms.SendKeys]::SendWait(" ")
Start-Sleep -s 1
[System.Windows.Forms.SendKeys]::SendWait("{tab}")
Start-Sleep -s 1
[System.Windows.Forms.SendKeys]::SendWait(" ")
Start-Sleep -s 1
[System.Windows.Forms.SendKeys]::SendWait("{tab}")
Start-Sleep -s 1
[System.Windows.Forms.SendKeys]::SendWait("{tab}")
Start-Sleep -s 1
[System.Windows.Forms.SendKeys]::SendWait(" ")
Start-Sleep -s 1

&$actionss -para3 "nonlog" -para5 "netsharing_password_disable"

[System.Windows.Forms.SendKeys]::SendWait("%{F4}")

}
else{

[System.Windows.Forms.SendKeys]::SendWait("+{tab}")
Start-Sleep -s 1
[System.Windows.Forms.SendKeys]::SendWait(" ")
Start-Sleep -s 1
[System.Windows.Forms.SendKeys]::SendWait("{tab}")
Start-Sleep -s 1
[System.Windows.Forms.SendKeys]::SendWait("{tab}")
Start-Sleep -s 1
[System.Windows.Forms.SendKeys]::SendWait("{tab}")
Start-Sleep -s 1
[System.Windows.Forms.SendKeys]::SendWait("{tab}")
Start-Sleep -s 1
[System.Windows.Forms.SendKeys]::SendWait("{Down}")
Start-Sleep -s 1
[System.Windows.Forms.SendKeys]::SendWait("{tab}")
Start-Sleep -s 1

&$actionss -para3 "nonlog" -para5 "netsharing_password_disable"

[System.Windows.Forms.SendKeys]::SendWait(" ")
}


Start-Sleep -s 3
 (get-process -id $id).CloseMainWindow() 


#Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters' -Name 'RestrictNullSessAccess' -Value '0' -Force
#Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Lsa' -Name 'everyoneincludesanonymous' -Value '1'  -Force


### setting turn on passwd protection ##

#Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters' -Name 'RestrictNullSessAccess' -Value '1' -Force
#Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Lsa' -Name 'everyoneincludesanonymous' -Value '0'  -Force

$results="-"

$index="net use w: ""$connectname1"""+"`n"+"net use w(x): /delete" + `
         "`n"+"review settings: Enable-WindowsOptionalFeature -Online -FeatureName ""SMB1Protocol"" -All (restart)"
}

else{
$results="na"
$index="sharefolder already exist"
}

$action="DUT file net sharing"
$tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
$tcnumber=((get-content $tcpath).split(","))[0]
$tcstep=((get-content $tcpath).split(","))[1]

Get-Module -name "outlog"|remove-module
$mdpath=(gci -path "C:\testing_AI\modules\"  -r -file |?{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

#write-host "Do $action!"
outlog $action $results $tcnumber $tcstep $index


  }

    export-modulemember -Function sharefolder_everyone