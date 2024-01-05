
function youtube ([string]$para1, [double]$para2,[string]$para3,[string]$para4,[string]$para5){
    
    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force;
    $wshell=New-Object -ComObject wscript.shell
      Add-Type -AssemblyName Microsoft.VisualBasic
      Add-Type -AssemblyName System.Windows.Forms

$paracheck1=$PSBoundParameters.ContainsKey('para1')
$paracheck2=$PSBoundParameters.ContainsKey('para2')
$paracheck3=$PSBoundParameters.ContainsKey('para3')
$paracheck4=$PSBoundParameters.ContainsKey('para4')
$paracheck5=$PSBoundParameters.ContainsKey('para5')

if($paracheck1 -eq $false -or $para1.Length -eq 0){
    $brstype = "edge"
    $URL = "https://www.youtube.com/watch?v=3xPkwNu2o8g"
}else{

 if($para1 -match "\|"){
    $tmp = $para1.Split("|")
    $brstype = $tmp[0]
    $URL = $tmp[1]
    }
    else{
    if($para1-match "https\:"){
     $brstype = "edge"
     $URL = $para1
    }
     else{
       $brstype = $para1
       $URL = "https://www.youtube.com/watch?v=3xPkwNu2o8g"
       }
    }
}

if($paracheck2 -eq $false -or $para2 -eq 0 ){
$para2=[double]1
}
if($paracheck3 -eq $false -or $para3.length -eq 0 ){
$para3="normal"
}
if($paracheck4 -eq $false -or $para4.length -eq 0 ){
$para4=""
}
if($paracheck5 -eq $false -or $para5.length -eq 0 ){
$para5=""
}
  $source = @"
using System;
using System.Threading.Tasks;
using System.Runtime.InteropServices;
using System.Windows.Forms;
namespace KeySends
{
    public class KeySend
    {
        [DllImport("user32.dll")]
        public static extern void keybd_event(byte bVk, byte bScan, int dwFlags, int dwExtraInfo);
        private const int KEYEVENTF_EXTENDEDKEY = 1;
        private const int KEYEVENTF_KEYUP = 2;
        public static void KeyDown(Keys vKey)
        {
            keybd_event((byte)vKey, 0, KEYEVENTF_EXTENDEDKEY, 0);
        }
        public static void KeyUp(Keys vKey)
        {
            keybd_event((byte)vKey, 0, KEYEVENTF_EXTENDEDKEY | KEYEVENTF_KEYUP, 0);
        }
    }
}
"@
Add-Type -TypeDefinition $source -ReferencedAssemblies "System.Windows.Forms"

if($PSScriptRoot.length -eq 0){
$scriptRoot="C:\testing_AI\modules\"
}
else{
$scriptRoot=$PSScriptRoot
}

$actionss="screenshot"
Get-Module -name $actionss|remove-module
$mdpath=(Get-ChildItem -path $scriptRoot -r -file |Where-object{$_.name -match "^$actionss\b" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global


function scrshot([string]$index,[string]$brs) {

Start-Sleep -s 2
$timenow=get-date -format "yyMMdd_HHmmss"
$picfile=$picpath+"$timenow-$($tcnumber)-$($tcstep)-$($action)-$($index)-$($brs).jpg"

### show taskbar###

    #[KeySends.KeySend]::KeyDown("LWin")
    #[KeySends.KeySend]::KeyDown("B")
    #[KeySends.KeySend]::KeyUp("LWin")
    #[KeySends.KeySend]::KeyUp("B")
    #Start-Sleep -s 1
    #[KeySends.KeySend]::KeyDown("LWin")
    #[KeySends.KeySend]::KeyUp("LWin")
    #Start-Sleep -s 1
    #[KeySends.KeySend]::KeyDown("LWin")
    #[KeySends.KeySend]::KeyUp("LWin")
    # Start-Sleep -s 2

$screen = [System.Windows.Forms.Screen]::PrimaryScreen
$bounds = $screen.Bounds
$bitmap = New-Object System.Drawing.Bitmap($bounds.Width, $bounds.Height)
$graphics = [System.Drawing.Graphics]::FromImage($bitmap)
$graphics.CopyFromScreen($bounds.X, $bounds.Y, 0, 0, $bounds.Size)

$bitmap.Save($picfile)
Start-Sleep -s 2

$graphics.Dispose()
$bitmap.Dispose()
Start-Sleep -s 2
}
   
#$website=$para1
$timeset=[double]$para2*60
$playtype_screen=$para3
$playtype_pause=$para4
$playtype_next=$para5

$items = @($playtype_screen,"play",$playtype_pause,$playtype_next) | Where-Object { $_ -ne $null -and $_ -ne "" }
$playtypes= [string]::Join("_",$items)
     

$action ="selenium_prepare"

Get-Module -name $action|remove-module
$mdpath=(Get-ChildItem -path $scriptRoot -r -file |Where-object{$_.name -match "^$action\b" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

if($brstype -eq "chrome"){
    &$action  chrome nonlog
}
if($brstype -eq "firefox"){
    &$action  firefox nonlog
}
if($brstype -eq "edge"){
    &$action  edge nonlog
}

$action="Youtube_$playtypes"

$tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
$tcnumber=((get-content $tcpath).split(","))[0]
$tcstep=((get-content $tcpath).split(","))[1]

$picpath=(Split-Path -Parent $scriptRoot)+"\logs\$($tcnumber)\"
if(-not(test-path $picpath)){new-item -ItemType directory -path $picpath |out-null}

$width  = (([string]::Join("`n", (wmic path Win32_VideoController get CurrentHorizontalResolution))).split("`n") -match "\d{1,}")[0]
$height  = (([string]::Join("`n", (wmic path Win32_VideoController get CurrentVerticalResolution))).split("`n") -match "\d{1,}")[0]

Get-ChildItem  "C:\testing_AI\modules\selenium\WebDriver.dll" |Unblock-File 
Add-Type -Path "C:\testing_AI\modules\selenium\WebDriver.dll"


## Open browser to youtube and login googleAccount

if($brstype -eq "chrome"){
    #$driver = New-Object OpenQA.Selenium.Chrome.ChromeDriver
    $optionsType = [OpenQA.Selenium.Chrome.ChromeOptions]
    $options = New-Object $optionsType
    $options.AddArgument("--disable-notifications") ## block the notification popup message
    $driverType = [OpenQA.Selenium.Chrome.ChromeDriver]
}
if($brstype -eq "firefox"){
    #$driver = New-Object OpenQA.Selenium.Firefox.FirefoxDriver
    $optionsType = [OpenQA.Selenium.Firefox.FirefoxOptions]
    $options = New-Object $optionsType
    $options.AddArgument("--disable-notifications") ## block the notification popup message
    $driverType = [OpenQA.Selenium.Firefox.FirefoxDriver]

}
if($brstype -eq "edge"){
    #$driver = New-Object OpenQA.Selenium.Edge.EdgeDriver
    $optionsType = [OpenQA.Selenium.Edge.EdgeOptions]
    $options = New-Object $optionsType
    $options.AddArgument("--disable-notifications") ## block the notification popup message
    $driverType = [OpenQA.Selenium.Edge.EdgeDriver]
}

#$driver = New-Object OpenQA.Selenium.Chrome.ChromeDriver


try{$driver = New-Object $driverType -ArgumentList ($options)}
catch{
    $results="NG"
    $index="fail to install web driver"
}

 if($results -ne "NG"){
[OpenQA.Selenium.Interactions.Actions]$actions = New-Object OpenQA.Selenium.Interactions.Actions ($driver)

$driver.Manage().Window.Maximize()
#$driver.Navigate().GoToUrl("https://accounts.google.com/v3/signin/identifier?dsh=S-301696514%3A1680833653094597&continue=https%3A%2F%2Fwww.youtube.com%2Fsignin%3Faction_handle_signin%3Dtrue%26app%3Ddesktop%26hl%3Den%26next%3Dhttps%253A%252F%252Fwww.youtube.com%252F&ec=65620&hl=en&ifkv=AQMjQ7TlRZg5JlS7La1S9SUNTWiqkgwhXBrko5qPZRjKHnjgVTB5O52wymSB14kEQ_wmD1cmFM4q&passive=true&service=youtube&uilel=3&flowName=GlifWebSignIn&flowEntry=ServiceLogin")
                            
$login = Get-Content "C:\testing_AI\settings\google_account.txt"
$Account = $login[0]
$Password = $login[1]

function skipadds{
### if add skip ##
$adContainer = $driver.FindElement([OpenQA.Selenium.By]::ClassName("video-ads"))
$isPlayingAds = $adContainer.Displayed
if($isPlayingAds){
do{
start-sleep -s 5
$skipbt=$driver.FindElement([OpenQA.Selenium.By]::ClassName("ytp-ad-skip-button"))
if($skipbt -ne $null){$skipbt.Click()}
start-sleep -s 5
$adContainer = $driver.FindElement([OpenQA.Selenium.By]::ClassName("video-ads"))
$isPlayingAds = $adContainer.Displayed
}until($isPlayingAds -eq $false)
}
}
##

<###
Set-Clipboard $Account
start-sleep -s 10
[System.Windows.Forms.SendKeys]::SendWait("^V")
[System.Windows.Forms.SendKeys]::SendWait("{ENTER}")

Set-Clipboard $Password
start-sleep -s 5
[System.Windows.Forms.SendKeys]::SendWait("^V")
[System.Windows.Forms.SendKeys]::SendWait("{ENTER}")
###>


## login google account if chrome or firefox ##

if($brstype -match "firefox" -or $brstype -match "chrome" ){
$driver.Navigate().GoToUrl($URL)

start-sleep -s 10

$loginbt=($driver.FindElement([OpenQA.Selenium.By]::ClassName("yt-spec-button-shape-next--icon-leading")))
#$href = $loginbt.GetAttribute("href")
$loginbt.click()
start-sleep -s 5

$inputid=($driver.FindElement([OpenQA.Selenium.By]::Id("identifierId")))
        #$href = $loginbt.GetAttribute("href")
        $inputid.SendKeys($Account)
        start-sleep -s 5

        $inputidnext=($driver.FindElement([OpenQA.Selenium.By]::Id("identifierNext")))
        $inputidnext.Click()
        #start-sleep -s 2
        #[System.Windows.Forms.SendKeys]::SendWait("{tab 3}")
        #start-sleep -s 2
        #[System.Windows.Forms.SendKeys]::SendWait("~")
        start-sleep -s 10

                
        $inputpasswd=$driver.FindElement([OpenQA.Selenium.By]::Id("password"))
        $inputpasswd.click()
        start-sleep -s 2
         $inputpasswd2=($driver.FindElement([OpenQA.Selenium.By]::Name("Passwd")))
         $inputpasswd2.SendKeys($Password)
        start-sleep -s 2

        $Passidnext=($driver.FindElement([OpenQA.Selenium.By]::Id("passwordNext")))
        $Passidnext.Click()
        start-sleep -s 60
              
         [System.Windows.Forms.SendKeys]::SendWait("{escape}") ## if popup cannot sync message
          start-sleep -s 2
              
}


        # 定義skip youtube廣告的程式碼
        #function Skip-YouTubeAd {
            ### if add skip ##---------------
        #    start-sleep -s 5
        #    $skipbt=$driver.FindElement([OpenQA.Selenium.By]::ClassName("ytp-ad-skip-button"))
        #    if($skipbt -ne $null){$skipbt.Click()}
        #    start-sleep -s 5
        #    $skipbt=$driver.FindElement([OpenQA.Selenium.By]::ClassName("ytp-ad-skip-button"))
        #    if($skipbt -ne $null){$skipbt.Click()}
            ##        
        #}


        #echo "Skip-ScriptRunning"
        # 創建背景作業
        #$job = Start-Job -ScriptBlock {        
        #    while ($true) {
        #        Skip-YouTubeAd
        #        Start-Sleep -Seconds 10
        #    }
        #}

## play / pause 

$driver.Navigate().GoToUrl($URL)
start-sleep -s 10

### if add skip ##
skipadds


#scrshot -index "normal" -brs $brstype
&$actionss -para2 showtaskbar -para3 nonlog -para5 "$($brstype)-normal"

$playbt=($driver.FindElement([OpenQA.Selenium.By]::ClassName("ytp-play-button")))
$playbt.click()

### Repeat ###

$mainpicture = $driver.FindElement([OpenQA.Selenium.By]::ClassName("ytd-player"))

# Perform right click action
$actions.ContextClick($mainpicture).Perform()
start-sleep -Milliseconds 50
#$actions.SendKeys($element, [OpenQA.Selenium.Keys]::ArrowDown).Perform()
start-sleep -s 1
$actions.SendKeys($element, [OpenQA.Selenium.Keys]::Enter).Perform()

### if add skip ##
skipadds

### Stats for Nerds ###
start-sleep -s 1
$mainpicture = $driver.FindElement([OpenQA.Selenium.By]::ClassName("ytd-player"))
# Perform right click action
$actions.ContextClick($mainpicture).Perform()
for ($i = 1; $i -le 8; $i++) {
    start-sleep -Milliseconds 50
    $actions.SendKeys($element, [OpenQA.Selenium.Keys]::ArrowDown).Perform()
}
   start-sleep -s 1
    $actions.SendKeys($element, [OpenQA.Selenium.Keys]::Enter).Perform()
    
 ### if add skip ##
  skipadds
  
  #scrshot -index "Stats_for_Nerds" -brs $brstype
  &$actionss -para3 nonlog -para5 "$($brstype)-Stats_for_Nerds"


### full screen ##
if($playtype_screen -match "full"){
start-sleep -s 5
$dbclickto=$driver.FindElement([OpenQA.Selenium.By]::Id("movie_player"))
$dbclickto.SendKeys("f")
#$actions.doubleClick($dbclickto).perform()
}

### if add skip ##
skipadds

$checkplay=($driver.FindElement([OpenQA.Selenium.By]::ClassName("ytp-play-button"))).ComputedAccessibleLabel
$checkplay

if($checkplay -match "Pause"){
$action21="play";$action22="play2";$action31="pause";$action32="pause2"
}
else{
$action31="play";$action32="play2";$action21="pause";$action22="pause2"
}

#scrshot -index $action21 -brs $brstype
&$actionss -para2 showtaskbar -para3 nonlog -para5 "$($brstype)-$($action21)"

if($action21 -match "play"){
Start-Sleep -s $timeset  ### play wait time
}

### if add skip ##
skipadds

#scrshot -index $action22 -brs $brstype
&$actionss -para2 showtaskbar -para3 nonlog -para5 "$($brstype)-$($action22)"

$playbt=($driver.FindElement([OpenQA.Selenium.By]::ClassName("ytp-play-button")))
$playbt.click()

### if add skip ##
skipadds

$checkplay2=($driver.FindElement([OpenQA.Selenium.By]::ClassName("ytp-play-button"))).ComputedAccessibleLabel
$checkplay2

if($checkplay2 -eq $checkplay){$playbt.click()} ### incase


### if add skip ##
skipadds


#scrshot -index $action31 -brs $brstype
&$actionss -para2 showtaskbar -para3 nonlog -para5 "$($brstype)-$($action31)"

if($action31 -match "play"){
Start-Sleep -s $timeset  ### play wait time
}

### if add skip ##
skipadds

#scrshot -index $action32 -brs $brstype
&$actionss -para2 showtaskbar -para3 nonlog -para5 "$($brstype)-$($action32)"

if($playtype_pause.length -eq 0){
Get-ChildItem -path $picpath -file -filter "*pause*"|Remove-Item
}

### play next ##

if($playtype_next -match "next"){

### click play if pause #
$videoElement = $driver.FindElement([OpenQA.Selenium.By]::TagName("video"))
$isPaused = $videoElement.GetAttribute("paused")
if ($isPaused -eq "true") {
$playbt=($driver.FindElement([OpenQA.Selenium.By]::ClassName("ytp-play-button")))
$playbt.click()
start-sleep -s 2
}

$nextbt=($driver.FindElement([OpenQA.Selenium.By]::ClassName("ytp-next-button")))
$nextbt.Click()

start-sleep -s 2

### if add skip ##
skipadds

#scrshot -index "nextplay" -brs $brstype
start-sleep -s 10

&$actionss -para2 showtaskbar -para3 nonlog -para5 "$($brstype)-nextplay"

}


### click play if pause #
$videoElement = $driver.FindElement([OpenQA.Selenium.By]::TagName("video"))
$isPaused = $videoElement.GetAttribute("paused")
if ($isPaused -eq "true") {
$playbt=($driver.FindElement([OpenQA.Selenium.By]::ClassName("ytp-play-button")))
$playbt.click()
start-sleep -s 2
}

### if add skip ##
skipadds



$closenerd = $driver.FindElement([OpenQA.Selenium.By]::ClassName("ytp-sfn-close"))
$closenerd.Click()

### close web ###

$driver.Close()
$driver.Quit()
if((get-process -Name msedgedriver -ErrorAction SilentlyContinue)){Stop-Process -Name msedgedriver}

$results="OK"
$index="check screen shots"

}

######### write log #######

Get-Module -name "outlog"|remove-module
$mdpath=(Get-ChildItem -path "C:\testing_AI\modules\"  -r -file |Where-object{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
Import-Module $mdpath -WarningAction SilentlyContinue -Global

#write-host "Do $action!"
outlog $action $results $tcnumber $tcstep $index


  }

    export-modulemember -Function youtube