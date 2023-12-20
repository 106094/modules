
function changescale ([int]$para1,[string]$para2,[string]$para3){

    Add-Type -AssemblyName System.Windows.Forms

    #default 
    # Posted by IanXue-MSFT on
    # https://learn.microsoft.com/en-us/answers/questions/197944/batch-file-or-tool-like-powertoy-to-change-the-res.html
    # $scaling = 0 : 100% (default)
    # $scaling = 1 : 125% 
    # $scaling = 2 : 150% 
    # $scaling = 3 : 175% 
    # etc....
  
    $paracheck1=$PSBoundParameters.ContainsKey('para1')

    if($paracheck1 -eq $false -or $para1 -eq 0){
       $para1=125
    }


    $scaleset=$para1
    $recoverflag=$para2
    $nonlog_flag=$para3
     
    if($PSScriptRoot.length -eq 0){
        $scriptRoot="C:\testing_AI\modules"
    }else{
        $scriptRoot=$PSScriptRoot
    }
    
    $action="changescales - $scaleset"
    $tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
    $tcnumber=((get-content $tcpath).split(","))[0]
    $tcstep=((get-content $tcpath).split(","))[1]

    #region import screenshot functino     
    $actionss ="screenshot"
    Get-Module -name $actionss|remove-module
    $mdpath=(gci -path $scriptRoot -r -file |?{$_.name -match "^$actionss\b" -and $_.name -match "psm1"}).fullname
    Import-Module $mdpath -WarningAction SilentlyContinue -Global
    #endregion     
        
    $dpisets=@(96,120,144,168)
    $sclsets=@(100,125,150,175)

    $dpirec=(Get-ItemProperty -Path "HKCU:\Control Panel\Desktop\WindowMetrics" -Name AppliedDPI).AppliedDPI
    $oriscls= $sclsets[$dpisets.indexof($dpirec)]
    $maindisplay=(((Get-WmiObject win32_desktopmonitor)[0].PNPDeviceID).split("\"))[1]

    function scaleset ([int]$scaleset){

    $indexto=$sclsets.indexof($scaleset)
    
    $checkrecommand=(Get-ChildItem -Path "HKCU:\Control Panel\Desktop\" | Select-Object Name).name -like '*PerMonitorSettings*'
    $dpirec=(Get-ItemProperty -Path "HKCU:\Control Panel\Desktop\WindowMetrics" -Name AppliedDPI).AppliedDPI
    $indexfrom=$dpisets.indexof($dpirec)
    $oriscls= $sclsets[$dpisets.indexof($dpirec)]

    if($checkrecommand){ 
     #$dpifrom=(Get-ItemProperty -Path "HKCU:\Control Panel\Desktop\PerMonitorSettings\*" -Name DpiValue).DpiValue
     $dpifrom=(Get-ItemProperty -Path "HKCU:\Control Panel\Desktop\PerMonitorSettings\*$maindisplay*" -Name DpiValue).DpiValue 
    }
    else{
    $dpifrom=0
    }

    if($dpifrom -eq 4294967294){$dpifrom = -2 }    
    if($dpifrom -eq 4294967295){$dpifrom = -1 }


    $indexref=$indexto-$indexfrom+$dpifrom

    if($indexref -eq -1){$indexref=4294967295}
    if($indexref -eq -2){$indexref=4294967294}

    write-host "$oriscls (DPI:$dpirec) change to $scaleset with indexref:$indexref"
    
    start-process explorer "ms-settings:display"

    Start-Sleep -s 5
    [System.Windows.Forms.SendKeys]::SendWait("% ")
    Start-Sleep -s 2
    [System.Windows.Forms.SendKeys]::SendWait("x")

# screenshot before#
&$actionss  -para3 nonlog -para5 "scalesetting_before1"

    Start-Sleep -s 1
    [System.Windows.Forms.SendKeys]::SendWait("+{tab}")
    start-Sleep -s 1
    [System.Windows.Forms.SendKeys]::SendWait("+{tab}")
    Start-Sleep -s 1
    
&$actionss  -para3 nonlog -para5 "scalesetting_before2"

(get-process ApplicationFrameHost|sort starttime|select -Last 1).closemainwindow()


    $source = @'
    [DllImport("user32.dll", EntryPoint = "SystemParametersInfo")]
    public static extern bool SystemParametersInfo(
                      uint uiAction,
                      uint uiParam,
                      uint pvParam,
                      uint fWinIni);
'@
    $apicall = Add-Type -MemberDefinition $source -Name WinAPICall -Namespace SystemParamInfo -PassThru
    $apicall::SystemParametersInfo(0x009F, $indexref , $null, 1) | Out-Null
    
    Start-Sleep -s 10

    Stop-Process -Name explorer

    Start-Sleep -s 30

    start-process explorer "ms-settings:display"

    Start-Sleep -s 5
    [System.Windows.Forms.SendKeys]::SendWait("% ")
    Start-Sleep -s 2
    [System.Windows.Forms.SendKeys]::SendWait("x")
#    Start-Sleep -s 2
#    [System.Windows.Forms.SendKeys]::SendWait("{ENTER}")
#    Start-Sleep -s 5
#    [System.Windows.Forms.SendKeys]::SendWait("{TAB 15}")
#    [System.Windows.Forms.SendKeys]::SendWait("{DOWN 10}")

# screenshot #
&$actionss  -para3 nonlog -para5 "scalesetting_after1"

    Start-Sleep -s 1
    [System.Windows.Forms.SendKeys]::SendWait("+{tab}")
    start-Sleep -s 1
    [System.Windows.Forms.SendKeys]::SendWait("+{tab}")
    Start-Sleep -s 1
    
&$actionss  -para3 nonlog -para5 "scalesetting_after2"

(get-process ApplicationFrameHost|sort starttime|select -Last 1).closemainwindow()
Start-Sleep -s 5

    ### check ###
    $dpiafter=(Get-ItemProperty -Path "HKCU:\Control Panel\Desktop\PerMonitorSettings\*$maindisplay*" -Name DpiValue).DpiValue 
    $sacleafter= $sclsets[$dpisets.IndexOf($dpiafter)]

    if($sacleafter -eq $scaleset){
        $results = "Pass"
    }
    else{
        $results = "NG"
    }

    $results

    }

 #region change 
 $results1=scaleset $scaleset
 #endregion change 
 $results=$results1[-1]

  #region recover 
if($recoverflag.length -gt 0){
 $results2=scaleset $oriscls
 $results=[string]::Join(";",$results1[-1], $results2[-1])
}



#endregion recover  

    $index="check screenshots"

    if($nonlog_flag.Length -eq 0){

    Get-Module -name "outlog"|remove-module
    $mdpath=(gci -path "C:\testing_AI\modules\" -r -file |?{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
    Import-Module $mdpath -WarningAction SilentlyContinue -Global

    #write-host "Do $action!"
    outlog $action $results  $tcnumber $tcstep $index

    }
}



Export-ModuleMember -Function changescale