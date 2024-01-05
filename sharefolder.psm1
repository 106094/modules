
function sharefolder() {

    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force;
    $wshell=New-Object -ComObject wscript.shell
      Add-Type -AssemblyName Microsoft.VisualBasic
      Add-Type -AssemblyName System.Windows.Forms
      
#Remove-LocalUser -name "pctest"
$paswd=ConvertTo-SecureString "pctest" -AsPlainText -force
new-LocalUser -name "pctest" -Password $paswd

Add-LocalGroupMember -Group "Administrators" -Member "pctest"

$username="$env:USERDOMAIN\pctest"
$netname= "C"
$domainname=(get-ItemProperty -path "HKLM:\SYSTEM\CurrentControlSet\Control\Computername\Computername").Computername
$connectname1="\\$domainname\C"
$mainuser=$env:username

### set pctest authority ###

#Get-NetFirewallRule -DisplayGroup ‘Network Discovery’|Set-NetFirewallRule -Profile ‘Private, Domain’ -Enabled true.

$acl = Get-Acl "C:\"
$acl2 = Get-Acl "C:\users\$env:USERname"
#$AccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule($username,'FullControl','ContainerInherit, ObjectInherit', 'None', 'Allow')

$AccessRule  = [System.Security.AccessControl.FileSystemAccessRule]::new($username,"FullControl","ContainerInherit,ObjectInherit","None","Allow" )
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
if( ((get-SmbShare　-name $netname -ea SilentlyContinue).name) -eq $null){
New-SmbShare -name  $netname  -path  "C:\"  -FullAccess $username
}

## 　Adds an allow access
Grant-SmbShareAccess -Name $netname -AccountName $username　-AccessRight Full -Force

if($PSScriptRoot.length -eq 0){
$scriptRoot="C:\testing_AI\modules\"
}
else{
$scriptRoot=$PSScriptRoot
}

$results="-"

$action="DUT file net sharing"

$index="net use w: ""$connectname1"" /u:""pctest"" ""pctest"""+"`n"+"net use w(x): /delete" + `
         "`n"+"review settings: Enable-WindowsOptionalFeature -Online -FeatureName ""SMB1Protocol"" -All (restart)"


$tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
$tcnumber=((get-content $tcpath).split(","))[0]
$tcstep=((get-content $tcpath).split(","))[1]

Get-Module -name "outlog"|remove-module
$mdpath=(Get-ChildItem -path "C:\testing_AI\modules\"  -r -file |Where-object{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

#write-host "Do $action!"
outlog $action $results $tcnumber $tcstep $index


  }

    export-modulemember -Function sharefolder