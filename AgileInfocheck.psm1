function AgileInfocheck ([string]$para1,[string]$para2){
    
       Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force;
              
    $SWB = $para1
    $nonlog_flag=$para2

    
    if($PSScriptRoot.length -eq 0){
        $scriptRoot="C:\testing_AI\modules\"
    }else{
        $scriptRoot=$PSScriptRoot
    }
    
    $actionss="screenshot"
    Get-Module -name $actionss|remove-module
    $mdpath=(Get-ChildItem -path $scriptRoot -r -file |Where-object{$_.name -match "^$actionss\b" -and $_.name -match "psm1"}).fullname
    Import-Module $mdpath -WarningAction SilentlyContinue -Global
    
    $actionse ="selenium_prepare"
    Get-Module -name $actionse|remove-module
    $mdpath=(Get-ChildItem -path $scriptRoot -r -file |Where-object{$_.name -match "^$actionse\b" -and $_.name -match "psm1"}).fullname
    Import-Module $mdpath -WarningAction SilentlyContinue -Global

    $action="Agile Info check"

    $tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
    $tcnumber=((get-content $tcpath).split(","))[0]
    $tcstep=((get-content $tcpath).split(","))[1]

    $picpath=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\"
    if(-not(test-path $picpath)){new-item -ItemType directory -path $picpath |out-null}
  
#general SWB number#
        
   if($SWB.length -eq 0){
  
 $inidrv=(Get-ChildItem "C:\testing_AI\logs\ini*\*" -r -Filter "*DriverVersion.csv"|Sort-Object lastwritetime|select -last 1).FullName
$checktype=(import-csv $inidrv|Where-object{$_.DeviceClass -match "DISPLAY"}).devicename

if($inidrv -and $checktype){
if($checktype -match "NVIDIA"){
$drvtype2="NV_general"
if($checktype -match "ada"){
$drvtype2="NV_A6000ada"
}

 $drivername=(Get-ChildItem ($scriptRoot+"\driver\GFX\$($drvtype2)\N\driver\") -File |Where-object{$_.name -match "NVIDIA" -and $_.name -match "\.exe"}|sort lastwritetime|select -first 1 ).Name
 $SWB=$drivername.split("_") |? {$_.length -eq 5 -and !($_  -match "^WIN\d{2}") }
 write-host "The Display Type is $($drvtype2)"
 write-host "The Display Driver SWB is $($SWB)"

}
if($checktype -match "AMD"){
    $chekdrv=$checktype -match "[a-zA-Z]\d{4}"
    if(!$chekdrv){$checktype -match "\d{4}"}
    $drvtype2="AMD_"+$matches[0] 
 $drivername=(Get-ChildItem ($scriptRoot+"\driver\GFX\$($drvtype2)\N\") -File |Where-object{$_.name -match "AMD" -and $_.name -match "\.exe" }|sort lastwritetime|select -first 1 ).Name
 $SWB=$drivername.split("_") |? {$_.length -eq 5 -and !($_  -match "^WIN\d{2}")}

write-host "The Display Driver is $($drvtype2)"
 write-host "The Display Driver SWB is $($SWB)"
}

}
}

if($SWB -and $SWB.count -eq 1){

#region selenium prepre 

   &$actionse -para1 "edge" -para2 "nonlog"

    Get-ChildItem  "C:\testing_AI\modules\selenium\WebDriver.dll" |Unblock-File 
    Add-Type -Path "C:\testing_AI\modules\selenium\WebDriver.dll"

   try{$driver = New-Object OpenQA.Selenium.Edge.EdgeDriver}
    catch{
    $results="NG"
    $index="fail to install web driver"
    }

    if($results -ne "NG"){

    $driver.Manage().Window.Maximize()
    $driver.Navigate().GoToUrl("https://agile.us.dell.com/Agile/default/login-cms.jsp")
    
    Start-Sleep -Seconds 10
    $agileacc = Get-content  -path C:\testing_AI\settings\loginPwd_Agile.txt
       
    $username = $driver.FindElement([OpenQA.Selenium.By]::Id("j_username"))
    $username.SendKeys($agileacc[0])
    Start-Sleep -Seconds 2
    $pass = $driver.FindElement([OpenQA.Selenium.By]::Id("j_password"))
    $pass.SendKeys($agileacc[1])
    Start-Sleep -Seconds 2
    $loginbt = $driver.FindElement([OpenQA.Selenium.By]::Id("login"))
    $loginbt.Click()
    
    Start-Sleep -Seconds 30

    $driver = $driver.SwitchTo().Window($driver.WindowHandles[-1])

    #$driver.Navigate().GoToUrl("https://agile.us.dell.com/Agile/PLMServlet?module=LoginHandler&opcode=forwardToMainMenu")

    Start-Sleep -Seconds 5

    $QSS =  $driver.FindElement([OpenQA.Selenium.By]::Id("QUICKSEARCH_STRING"))
    $QSS.SendKeys($SWB)
    Start-Sleep -Seconds 2
    
    $sech = $driver.FindElement([OpenQA.Selenium.By]::Id("top_simpleSearchspan"))
    $sech.Click()
    
    Start-Sleep -Seconds 30

    $QST =  $driver.FindElement([OpenQA.Selenium.By]::ClassName("GMBodyMid"))
    
    $searchjs = "var search = document.getElementById('QUICKSEARCH_TABLE');"
    $searchjs += "var itemcount = 0;"
    $searchjs += "for(var i = 0; i<= search.querySelectorAll('td').length-1; i++){"
    $searchjs += "if(search.querySelectorAll('td').item(i).textContent.includes('$SWB') && search.querySelectorAll('td').item(i).textContent.length <= 6){ itemcount = i;}}"
    $searchjs += "search.querySelectorAll('td').item(itemcount).querySelector('a').click();"

    $driver.ExecuteScript($searchjs)
    
    Start-Sleep -Seconds 30

      &$actionss  -para3 nonlog -para5 "page1"
     
      $page3 =  $driver.FindElement([OpenQA.Selenium.By]::Id("id_heading_Page Three"))
       $page3.Click()
         
     &$actionss  -para3 nonlog -para5 "page3"

    $searchtextjs = "var table = document.getElementById('content');"
    $searchtextjs += "var dl =  table.querySelectorAll('dl');"
    $searchtextjs += "var array = [];"
    $searchtextjs += "for(var i = 0 ; i<= dl.length-1 ; i++){"
    $searchtextjs += " array += dl.item(i).textContent;};"
    $searchtextjs += "return array;"


    $content = $driver.ExecuteScript($searchtextjs)
    $content = $content.split("`n")
    
    $findings=@("Fixes and Enhancements","Operating System","Description External")
    $checkinfos=@()
    foreach($finding in $findings){
    
    $findingmat="\s{2,}"+$finding
   
     $checkinfo= ($content -match $findingmat).trim()
     $checkinfos+=@($checkinfo)
     $splittitle=$finding+":"
     $findingindex=$finding

   if($finding -match "Fixes and Enhancements"){
     $checkinfo2= ($checkinfo -split "External\:")[1]
      }
   if($finding -match "Operating System"){
     $checkinfo2= ($checkinfo -split "\(OS\)\:")[1]
      }

    if($finding -match "Description External"){
     $splittitle2=$splittitle.substring($splittitle.length -10,10)
     $checkinfo2= ($checkinfo -split "$splittitle2")[1]
     $findingindex=($finding.replace("*","")).replace(" External","")
     }

    $datenow = get-date -format "yyMMdd_HHmmss"  
    $infopath =$picpath+"\$($datenow)_step$($tcstep)_agileinfo_$($findingindex).txt"  
    #$findingindex
    #$checkinfo2
    #start-sleep -s 5
     set-content -path  $infopath -Value  $checkinfo2 -Force
    
    }
        

     $results="NG"
     $index="Fail to check agile info"
     $checkinfos=($checkinfos|Out-String)
    if( $checkinfos.Length -gt 0){
    $results="OK"
     $index= $checkinfos
    }
   
### close web ###

$driver.Close()
$driver.Quit()
if((get-process -Name msedgedriver -ErrorAction SilentlyContinue)){Stop-Process -Name msedgedriver} 
}


     }

else{
$results="NG"
$index="SWB number read fail"

}

######### write log #######
    
if($nonlog_flag.Length -eq 0){

Get-Module -name "outlog"|remove-module
$mdpath=(Get-ChildItem -path "C:\testing_AI\modules\" -r -file |Where-Object{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

#write-host "Do $action!"
outlog $action $results $tcnumber $tcstep $index
}
   
}



Export-ModuleMember -Function AgileInfocheck