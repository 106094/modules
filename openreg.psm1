
function openreg ([string]$para1,[string]$para2){
    
    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force;
    #$wshell=New-Object -ComObject wscript.shell
      Add-Type -AssemblyName Microsoft.VisualBasic
      Add-Type -AssemblyName System.Windows.Forms
   

    $paracheck=$PSBoundParameters.ContainsKey('para1')

    if( $paracheck -eq $false -or $para1.length -eq 0 ){
    #write-host "no defined, setting 1 min after login"
    $para1="Computer\HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4.0"
    }

    $registryPath=$para1
    $nonlog_flag=$para2

    if($PSScriptRoot.length -eq 0){
    $scriptRoot="C:\testing_AI\modules"
    }
    else{
    $scriptRoot=$PSScriptRoot
    }

    $action="open reg with registryPath"

    $tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
    $tcnumber=((get-content $tcpath).split(","))[0]
    $tcstep=((get-content $tcpath).split(","))[1]
    $results="OK"
    $index="open reg with the path ok"

    $actionss ="screenshot"
    Get-Module -name $actionss|remove-module
    $mdpath=(Get-ChildItem -path $scriptRoot -r -file |Where-object{$_.name -match "^$actionss\b" -and $_.name -match "psm1"}).fullname
    Import-Module $mdpath -WarningAction SilentlyContinue -Global

    function jumpReg ($registryPath)
    {
        New-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Applets\Regedit" `
                        -Name "LastKey" `
                        -Value $registryPath `
                        -PropertyType String `
                        -Force

        start-process regedit -WindowStyle Maximized
    }

    try{
    jumpReg -registryPath $registryPath | Out-Null
    }
    catch{
        $results="NG"
        $index="fail to open reg with the path"
    }

    &$actionss -para3 nonlog -para5 "regpath"

    (get-process -name regedit).CloseMainWindow()

    ######### write log #######

 if($nonlog_flag.Length -eq 0){

    Get-Module -name "outlog"|remove-module
    $mdpath=(Get-ChildItem -path "C:\testing_AI\modules\"  -r -file |Where-object{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
    Import-Module $mdpath -WarningAction SilentlyContinue -Global
    
    #write-host "Do $action!"
    outlog $action $results $tcnumber $tcstep $index
    
 }

  }

    export-modulemember -Function openreg