

function dcvt_runandcheck (){
        
  Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force;
   $shell=New-Object -ComObject shell.application
    $wshell=New-Object -ComObject wscript.shell
      Add-Type -AssemblyName Microsoft.VisualBasic
      Add-Type -AssemblyName System.Windows.Forms
     

function ConvertFrom-HTMLTable {
    <#
    .SYNOPSIS
    Function for converting ComObject HTML object to common PowerShell object.

    .DESCRIPTION
    Function for converting ComObject HTML object to common PowerShell object.
    ComObject can be retrieved by (Invoke-WebRequest).parsedHtml or IHTMLDocument2_write methods.

    In case table is missing column names and number of columns is:
    - 2
        - Value in the first column will be used as object property 'Name'. Value in the second column will be therefore 'Value' of such property.
    - more than 2
        - Column names will be numbers starting from 1.

    .PARAMETER table
    ComObject representing HTML table.

    .PARAMETER tableName
    (optional) Name of the table.
    Will be added as TableName property to new PowerShell object.

    .EXAMPLE
    $pageContent = Invoke-WebRequest -Method GET -Headers $Headers -Uri "https://docs.microsoft.com/en-us/mem/configmgr/core/plan-design/hierarchy/log-files"
    $table = $pageContent.ParsedHtml.getElementsByTagName('table')[0]
    $tableContent = @(ConvertFrom-HTMLTable $table)

    Will receive web page content >> filter out first table on that page >> convert it to PSObject

    .EXAMPLE
    $Source = Get-Content "C:\Users\Public\Documents\MDMDiagnostics\MDMDiagReport.html" -Raw
    $HTML = New-Object -Com "HTMLFile"
    $HTML.IHTMLDocument2_write($Source)
    $HTML.body.getElementsByTagName('table') | % {
        ConvertFrom-HTMLTable $_
    }

    Will get web page content from stored html file >> filter out all html tables from that page >> convert them to PSObjects
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [System.__ComObject] $table,

        [string] $tableName
    )

    $twoColumnsWithoutName = 0

    if ($tableName) { $tableNameTxt = "'$tableName'" }

    $columnName = $table.getElementsByTagName("th") | % { $_.innerText -replace "^\s*|\s*$" }

    if (!$columnName) {
        $numberOfColumns = @($table.getElementsByTagName("tr")[0].getElementsByTagName("td")).count
        if ($numberOfColumns -eq 2) {
            ++$twoColumnsWithoutName
            Write-Verbose "Table $tableNameTxt has two columns without column names. Resultant object will use first column as objects property 'Name' and second as 'Value'"
        } elseif ($numberOfColumns) {
            Write-Warning "Table $tableNameTxt doesn't contain column names, numbers will be used instead"
            $columnName = 1..$numberOfColumns
        } else {
            throw "Table $tableNameTxt doesn't contain column names and summarization of columns failed"
        }
    }

    if ($twoColumnsWithoutName) {
        # table has two columns without names
        $property = [ordered]@{ }

        $table.getElementsByTagName("tr") | % {
            # read table per row and return object
            $columnValue = $_.getElementsByTagName("td") | % { $_.innerText -replace "^\s*|\s*$" }
            if ($columnValue) {
                # use first column value as object property 'Name' and second as a 'Value'
                $property.($columnValue[0]) = $columnValue[1]
            } else {
                # row doesn't contain <td>
            }
        }
        if ($tableName) {
            $property.TableName = $tableName
        }

        New-Object -TypeName PSObject -Property $property
    } else {
        # table doesn't have two columns or they are named
        $table.getElementsByTagName("tr") | % {
            # read table per row and return object
            $columnValue = $_.getElementsByTagName("td") | % { $_.innerText -replace "^\s*|\s*$" }
            if ($columnValue) {
                $property = [ordered]@{ }
                $i = 0
                $columnName | % {
                    $property.$_ = $columnValue[$i]
                    ++$i
                }
                if ($tableName) {
                    $property.TableName = $tableName
                }

                New-Object -TypeName PSObject -Property $property
            } else {
                # row doesn't contain <td>, its probably row with column names
            }
        }
    }
}
    
    #### Run ##
    
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
$logpath=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\"

if(-not(test-path $logpath)){new-item -ItemType directory -path $logpath |out-null}

 $id0=(Get-Process cmd).Id
set-location "$scriptRoot\dcvt"
$runcommand="DCVT.exe"

start-process cmd
start-sleep -s 3
 $id3=(Get-Process cmd).Id|Where-object{$_ -notin $id0}
 start-sleep -s 1
 [Microsoft.VisualBasic.interaction]::AppActivate($id3)|out-null
 Set-Clipboard $runcommand
 start-sleep -s 5
[System.Windows.Forms.SendKeys]::SendWait("^v")
 start-sleep -s 2
[System.Windows.Forms.SendKeys]::SendWait("~")
 start-sleep -s 5
  
  $resultpathold=(Get-ChildItem "$scriptRoot\dcvt\results\DCVT*.zip" -ErrorAction SilentlyContinue|sort creationtime |select -Last 1).fullname

  do{
    start-sleep -s 5  
  
  $resultpath=(Get-ChildItem "$scriptRoot\dcvt\results\DCVT*.zip" -ErrorAction SilentlyContinue|sort creationtime |select -Last 1).fullname
  
  $resultpathbase=(Get-ChildItem "$scriptRoot\dcvt\results\DCVT*.zip" -ErrorAction SilentlyContinue|sort creationtime |select -Last 1).basename

   }until($resultpath.length -gt 0  -and  $resultpath -ne $resultpathold )

     start-sleep -s 5

   taskkill /F /PID $id3

   $resultpathnew=($resultpathbase.replace("[","(") -replace "]",")").replace(" ","")

## unzip and check ##

$zip= $resultpath
$dest= "$($logpath)$($resultpathnew)\"

if(-not(test-path $dest)){new-item -ItemType directory -path $dest |out-null}
 
  $shell.NameSpace($dest).copyhere($shell.NameSpace($zip).Items(),16)

  $htmlpath=(Get-ChildItem "$dest\AssessmentResults.html" -ErrorAction SilentlyContinue).fullname 

 $html = New-Object -Com "HTMLFile"

  $content= get-content $htmlpath

try {
    # This works in PowerShell with Office installed
    $html.IHTMLDocument2_write($content)
}
catch {
    # This works when Office is not installed    
    $src = [System.Text.Encoding]::Unicode.GetBytes($content)
    $html.write($src)
}


$allTablesAsObject =  $html.all.tags("table") | ?{$_.id -eq "ResultsSummaryTable"} | Foreach-Object { ConvertFrom-HTMLTable $_ }
# output just 'Log name' property

$results="OK"
foreach($value in $allTablesAsObject){
 
 if($value."Pass Rate" -ne "100%"){
 $results="NG"
 
 }
 }

 $index= $htmlpath

######### write log #######


Get-Module -name "outlog"|remove-module
$mdpath=(Get-ChildItem -path "C:\testing_AI\modules\"  -r -file |Where-object{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

#write-host "Do $action!"
outlog $action $results $tcnumber $tcstep $index




   }

    export-modulemember -Function dcvt_runandcheck