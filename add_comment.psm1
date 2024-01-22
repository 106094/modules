function add_comment ([string]$para1,[string]$para2 ){
     
     $comments=$para1
     $nonlog_flag=$para2

if($PSScriptRoot.length -eq 0){
$scriptRoot="C:\testing_AI\modules"
}
else{
$scriptRoot=$PSScriptRoot
}

$tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
$tcnumber=((get-content $tcpath).split(","))[0]
$tcstep=((get-content $tcpath).split(","))[1]
$action=((get-content $tcpath).split(","))[2]

$picpath=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\"
if(-not(test-path $picpath)){new-item -ItemType directory -path $picpath |out-null}
$results="OK"
$index="add comment ok"

$logtxt=$picpath+"$($tcstep)_add_comment.txt"

try{
new-item -itemType file -path $logtxt |out-null
add-content -path $logtxt -value $comments -Force
}catch{
    $results="NG"
    $index="add comment failed"
}

######### write log #######
if($nonlog_flag.Length -eq 0){
    Get-Module -name "outlog"|remove-module
    $mdpath=(Get-ChildItem -path "C:\testing_AI\modules\"  -r -file |Where-object{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
    Import-Module $mdpath -WarningAction SilentlyContinue -Global
    
    #write-host "Do $action!"
    outlog $action $results $tcnumber $tcstep $index

}



  }
    export-modulemember -Function add_comment