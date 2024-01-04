function idrac_initial {

   Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force;
    #$wshell=New-Object -ComObject wscript.shell
      Add-Type -AssemblyName Microsoft.VisualBasic
       Add-Type -AssemblyName System.Windows.Forms
        Add-Type -AssemblyName System.Windows.Forms,System.Drawing
            
      if($PSScriptRoot.length -eq 0){
      $scriptRoot="C:\testing_AI\modules"
      }else{
      $scriptRoot=$PSScriptRoot
      }

      $idrac_ipmiset="ipmisettings"
      Get-Module -name $idrac_ipmiset|remove-module
      $mdpath=(Get-ChildItem -path $scriptRoot -r -file |Where-Object{$_.name -match $idrac_ipmiset -and $_.name -match "psm1"}).fullname
      Import-Module $mdpath -WarningAction SilentlyContinue -Global
    
      #write-host "Do $action!"
      &$idrac_ipmiset -para2 "nolog"

      $idrac_timeoutset="idrac_settimeout"
      Get-Module -name $idrac_timeoutset|remove-module
      $mdpath=(Get-ChildItem -path $scriptRoot -r -file |Where-Object{$_.name -match $idrac_timeoutset -and $_.name -match "psm1"}).fullname
      Import-Module $mdpath -WarningAction SilentlyContinue -Global
    
      #write-host "Do $action!"
      &$idrac_timeoutset -para1 "nolog"

### write to log ###

  Get-Module -name "outlog"|remove-module
  $mdpath=(Get-ChildItem -path "C:\testing_AI\modules\" -r -file |Where-Object{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
  Import-Module $mdpath -WarningAction SilentlyContinue -Global

  #write-host "Do $action!"
  outlog $action $results  $tcnumber $tcstep $index

  }

  
  export-modulemember -Function idrac_initial