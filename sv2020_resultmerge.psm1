function sv2020_resultmerge ([string]$para1 ){
     
    $nonlog_flag=$para1

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
  $index="results merge ok"
  $logcsv=$picpath+"$($tcstep)_resultCSV_all.csv"
  $resultscsvs=Get-ChildItem $picpath\results*\ -Recurse|Where-Object{$_.name -eq "resultCSV.csv" }
  if(!$resultscsvs){
    $results="NG"
    $index="No SPECVIEW2020 results"
  }
  else{
  $testitems=@("3dsmax-07","catia-06","creo-03","energy-03","maya-06","medical-03","snx-04","solidworks-07")
  if(!(Test-Path $logcsv)){
    new-item $logcsv |Out-Null
    add-content -path $logcsv -value ("folder,"+($testitems -join ","))
  }
  foreach ($resultscsv in $resultscsvs){
  add-content -path $logcsv -value ",,,,,,,"
  $foldername=Split-Path -leaf $resultscsv.directoryname
  $csvraw=get-content $resultscsv.FullName
  $adddata=import-csv $logcsv
  $adddata[-1]."folder"=$foldername
  foreach($raw in $csvraw){
    $testitems|ForEach-Object{
      if($raw -match $_){
      $adddata[-1].$_=($raw.split(","))[1]
    }   
    }
    if($raw -match "viewset"){
      break
    }
  }
  $adddata|export-csv -Path $logcsv -NoTypeInformation
  }
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
    export-modulemember -Function sv2020_resultmerge