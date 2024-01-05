######delete Schedule #####

function taskschedule_delete ([string]$para1){


start-process cmd -ArgumentList '/c schtasks /delete /TN "Auto_Run" -f' 

start-sleep -s 10

   $taskExists =Get-ScheduledTask | Where-Object {$_.TaskName -like "Auto_Run" } 
   if(-not($taskExists)){ $results  ="OK"} else{$results  ="NG"}
   
if($PSScriptRoot.length -eq 0){
$scriptRoot="C:\testing_AI\modules"
}
else{
$scriptRoot=$PSScriptRoot
}

$nonlog_flag=$para1

if($nonlog_flag.length -eq 0){

$tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
$tcnumber=((get-content $tcpath).split(","))[0]
$tcstep=((get-content $tcpath).split(","))[1]
$action="taskschedule setup - delete"
$Index="-"

Get-Module -name "outlog"|remove-module
$mdpath=(Get-ChildItem -path "C:\testing_AI\modules\" -r -file |Where-object{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

#write-host "Do $action!"
outlog $action $results $tcnumber $tcstep $index
}

}


  export-modulemember -Function taskschedule_delete