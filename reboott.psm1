function reboott ([int]$para1, [int]$para2){

$paracheck1=$PSBoundParameters.ContainsKey('para1')
$paracheck2=$PSBoundParameters.ContainsKey('para2')

if($paracheck1 -eq $false  -or $para1 -eq 0){
$para1=10
}
if($paracheck2 -eq $false  -or $para2 -eq 0){
$para2=60
}

$mins=[int]$para1
$waittime=[int]$para2
echo "wait $waittime before reboot"

function Get-RestartInfo{

[CmdletBinding()]
Param(
    [Parameter(ValueFromPipeline,ValueFromPipelineByPropertyName)]
    [alias("Name","MachineName","Computer")]
    [string[]]
    $ComputerName = 'localhost',

    [ValidateNotNull()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty

    )

    Begin { }

    Process {
        Foreach($Computer in $ComputerName){
            $Connection = Test-Connection $Computer -Quiet -Count 2

            If(!$Connection) {
                Write-Warning "Computer: $Computer appears to be offline!"
            } #end If

            Else {
                Get-WinEvent -ComputerName $computer -FilterHashtable @{logname = 'System'; id = 1074}  |
                    ForEach-Object {
                        $EventData = New-Object PSObject | Select-Object Date, EventID, User, Action, Reason, ReasonCode, Comment, Computer, Message, Process
                        $EventData.Date = $_.TimeCreated
                        $EventData.User = $_.Properties[6].Value
                        $EventData.Process = $_.Properties[0].Value
                        $EventData.Action = $_.Properties[4].Value
                        $EventData.Reason = $_.Properties[2].Value
                        $EventData.ReasonCode = $_.Properties[3].Value
                        $EventData.Comment = $_.Properties[5].Value
                        $EventData.Computer = $Computer
                        $EventData.EventID = $_.id
                        $EventData.Message = $_.Message
                    
                        $EventData | Select-Object Date, Computer, EventID, Action, User, Reason, Message

                    }
                } #end Else
        } #end Foreach Computer Loop
    } #end Process block
} #end of Function

if($PSScriptRoot.length -eq 0){
$scriptRoot="C:\testing_AI\modules"
}
else{
$scriptRoot=$PSScriptRoot
}

$action="reboot - $mins minutes"
$tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
$tcnumber=$((get-content $tcpath).split(","))[0]
$tcstep=((get-content $tcpath).split(","))[1]

## set flag ##
$waitflag="C:\testing_AI\logs\wait.txt"

## the 1st time ###
if(-not(test-path $waitflag)){

new-item -Path $waitflag -Force |out-null

$timestart=[datetime]((Get-ChildItem $waitflag).CreationTime)
$count=((Get-RestartInfo).date -gt $timestart).count
$timenow=(get-date)
$timegap=(New-TimeSpan –Start $timestart –End $timenow).TotalMinutes
#$checkstop=$timegap -gt $mins
$Index = "reboot 1st time "
$results="wait"

$content_log=import-csv "C:\testing_AI\logs\logs_timemap.csv"
Get-Module -name "outlog"|remove-module
$mdpath=(Get-ChildItem -path "C:\testing_AI\modules\" -r -file |?{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

#write-host "Do $action!"
outlog $action $results  $tcnumber $tcstep $index

  Start-Sleep -s  $waittime
  Restart-Computer -Force

}


else{

$timestart=[datetime]((Get-ChildItem $waitflag).CreationTime)
$count=((Get-RestartInfo).date -gt $timestart).count
$countx=$count+1
$timenow=(get-date)
$timegap=(New-TimeSpan –Start $timestart –End $timenow).Minutes
$checkstop=$timegap -gt $mins
$Index= "reboot passed for $timegap minutes  ($countx cycles)"

if($checkstop -eq $true){
remove-item C:\testing_AI\logs\wait.txt -force
$results="OK"
$Index= "reboot passed for $timegap minutes ($countx cycles)"
$content_log=import-csv "C:\testing_AI\logs\logs_timemap.csv"
($content_log |?{$_.Actions -eq $action -and $_.TC -eq $tcnumber -and $_.Step_No -eq $tcstep}).Index=$Index
($content_log |?{$_.Actions -eq $action -and $_.TC -eq $tcnumber -and $_.Step_No -eq $tcstep}).results=$results
$content_log|export-csv  "C:\testing_AI\logs\logs_timemap.csv" -NoTypeInformation
}

if($checkstop -eq $false){

$results="wait"
$Index= "reboot passed for $timegap minutes  ($countx cycles)"
$content_log=import-csv "C:\testing_AI\logs\logs_timemap.csv"
($content_log |?{$_.Actions -eq $action -and $_.TC -eq $tcnumber -and $_.Step_No -eq $tcstep}).Index=$Index
($content_log |?{$_.Actions -eq $action -and $_.TC -eq $tcnumber -and $_.Step_No -eq $tcstep}).results=$results
$content_log|export-csv  "C:\testing_AI\logs\logs_timemap.csv" -NoTypeInformation
  
  Start-Sleep -s  $waittime
  Restart-Computer -Force

}

}



  }

  
    export-modulemember -Function  reboott