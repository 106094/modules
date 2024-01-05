function rtc_gap{

if($PSScriptRoot.length -eq 0){
$scriptRoot="C:\testing_AI\modules"
}
else{
$scriptRoot=$PSScriptRoot
}

$url =  "https://nist.time.gov/"
$logs=$null
$ie = New-Object -comobject InternetExplorer.Application 

#$ie.visible = $true 
$ie.visible =$false
$ie.silent = $true 
$ie.Navigate( $url )

do { Start-Sleep -s 2 } until($ie.ReadyState -eq 4)
$iedom = $ie.Document

Start-Sleep -s 5
try{
$gapinfo0=((($iedom.IHTMLDocument3_getElementById('main-time-area').textContent).split("`n")|Where-object{$_.trim().length -gt 0}).replace("`t","")).replace("  ","") 
}
catch{
$gapinfo0=((($iedom.getElementById('main-time-area').textContent).split("`n")|Where-object{$_.trim().length -gt 0}).replace("`t","")).replace("  ","") 
}

$gapinfo1=$gapinfo0|Select-String "off"
$gapinfo1 -match '.\d+\.\d+'
$gapinfo2=$matches[0]
$resultp="[Pass]"
if([double]$gapinfo2 -ge 2){$resultp="[Fail]"}
$gapinfo3=$gapinfo2+$resultp

$ie.Quit()                                                               #----| 
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($ie) 
Remove-Variable ie    


$action="Check RTC gap"

$tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
$tcnumber=((get-content $tcpath).split(","))[0]
$tcstep=((get-content $tcpath).split(","))[1]
$results=$gapinfo3  
$index=$gapinfo0  -join "`n"     
 

Get-Module -name "outlog"|remove-module
$mdpath=(Get-ChildItem -path "C:\testing_AI\modules\" -r -file |Where-object{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

#write-host "Do $action!"
outlog $action $results  $tcnumber $tcstep $index



  }

    export-modulemember -Function rtc_gap