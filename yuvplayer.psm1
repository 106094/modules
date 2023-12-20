function yuvplayer ([string]$para1,[int]$para2){
    
    $paracheck1=$PSBoundParameters.ContainsKey('para1')
    $paracheck2=$PSBoundParameters.ContainsKey('para2')

    if($paracheck1 -eq $false -or  $para1 -eq 0 ){
        $para1= ""
    }
    if($paracheck2 -eq $false -or  $para2 -eq 0 ){
        $para2= 300
    }

    $status=$para1
    $waitsecond = $para2

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

    function startyuvsetting(){
        $sendkeylist = @(
            "{F8}",
            "{TAB 2}",
            "{Right}",
            "{TAB 3}",
            "{+}",
            "{TAB 4}",
            "{Enter}",
            "^o",
            "C:\testing_AI\modules\yuvplayer\BigBuckBunny_CIF_24fps.yuv",
            "{Enter}",
            "{F8}",
            "{TAB 2}",
            "{Right}",
            "{TAB 3}",
            "{-}",
            "{TAB 4}",
            "{Enter}",
            "{F8}",
            "{TAB 9}",
            "{+}",
            "{Enter}",
            "{F8}",
            "{TAB 5}",
            1,
            3,
            3,
            "{Enter 2}"
        )

        

        if($status.Length -ne 0){
            $sendkeylist += "{Enter}"
        }

        foreach ($sditem in $sendkeylist){
            start-sleep -s 5
            echo $sditem
            [System.Windows.Forms.SendKeys]::SendWait($sditem)

            #try{
            #    screenshot -para3 "nonlog" -para5 "$sditem"
            #}catch{
            #    screenshot -para3 "nonlog"
            #}
        }
        $screen = [System.Windows.Forms.Screen]::PrimaryScreen
        $bounds = $screen.Bounds
        Set_Window -para1 "yuv" -para2 $bounds.Width -para3 $bounds.Height -para4 0 -para5 0
    }

    Add-Type -AssemblyName System.Windows.Forms

    if($PSScriptRoot.length -eq 0){
        $scriptRoot="C:\testing_AI\modules\"
    }
    else{
        $scriptRoot=$PSScriptRoot
    }


    $tcpath=(Split-Path -Parent $scriptRoot)+"\currentjob\TC.txt"
    $tcnumber=((get-content $tcpath).split(","))[0]
    $tcstep=((get-content $tcpath).split(","))[1]

    

    #-------------------------------------------------------
    
    #-------------------------import module
    $actionss ="screenshot"
    Get-Module -name $actionss|remove-module
    $mdpath=(gci -path $scriptRoot -r -file |?{$_.name -match "^$actionss\b" -and $_.name -match "psm1"}).fullname
    Import-Module $mdpath -WarningAction SilentlyContinue -Global

    $actioncmd ="cmdline"
    Get-Module -name $actioncmd|remove-module
    $mdpath=(gci -path $scriptRoot -r -file |?{$_.name -match "^$actioncmd\b" -and $_.name -match "psm1"}).fullname
    Import-Module $mdpath -WarningAction SilentlyContinue -Global

    $actionsdw ="Set_Window"
    Get-Module -name $actionsdw|remove-module
    $mdpath=(gci -path $scriptRoot -r -file |?{$_.name -match "^$actionsdw\b" -and $_.name -match "psm1"}).fullname
    Import-Module $mdpath -WarningAction SilentlyContinue -Global
    #-------------------------
    $actiontar ="taskschedule_attime_repeat"
    Get-Module -name $actiontar|remove-module
    $mdpath=(gci -path $scriptRoot -r -file |?{$_.name -match "^$actiontar\b" -and $_.name -match "psm1"}).fullname
    Import-Module $mdpath -WarningAction SilentlyContinue -Global

    $actionS4 ="hibernaten"
    Get-Module -name $actionS4|remove-module
    $mdpath=(gci -path $scriptRoot -r -file |?{$_.name -match "^$actionS4\b" -and $_.name -match "psm1"}).fullname
    Import-Module $mdpath -WarningAction SilentlyContinue -Global

    $actiontd ="taskschedule_delete"
    Get-Module -name $actiontd|remove-module
    $mdpath=(gci -path $scriptRoot -r -file |?{$_.name -match "^$actiontd\b" -and $_.name -match "psm1"}).fullname
    Import-Module $mdpath -WarningAction SilentlyContinue -Global
    #-------------------------
    $actionrn ="rebootn"
    Get-Module -name $actionrn|remove-module
    $mdpath=(gci -path $scriptRoot -r -file |?{$_.name -match "^$actionrn\b" -and $_.name -match "psm1"}).fullname
    Import-Module $mdpath -WarningAction SilentlyContinue -Global

    #$actionsma ="startmenuapp"
    #Get-Module -name $actionsma|remove-module
    #$mdpath=(gci -path $scriptRoot -r -file |?{$_.name -match "^$actionsma\b" -and $_.name -match "psm1"}).fullname
    #Import-Module $mdpath -WarningAction SilentlyContinue -Global
    #-------------------------
    $actionatlog ="taskschedule_atlogin"
    Get-Module -name $actionatlog|remove-module
    $mdpath=(gci -path $scriptRoot -r -file |?{$_.name -match "^$actionatlog\b" -and $_.name -match "psm1"}).fullname
    Import-Module $mdpath -WarningAction SilentlyContinue -Global

    $actionS5 ="ipmitool_shutdown"
    Get-Module -name $actionS5|remove-module
    $mdpath=(gci -path $scriptRoot -r -file |?{$_.name -match "^$actionS5\b" -and $_.name -match "psm1"}).fullname
    Import-Module $mdpath -WarningAction SilentlyContinue -Global
    #-------------------------



    if($status -eq "Install"){
        $action="yuvplayer-Install"
        cmdline -para1 "C:\testing_AI\modules\yuvplayer\yuvplayer.exe /s" -para5 "nonlog"

        $flag = $true
        $i = 0
        while($flag){
            $d = Get-Process -ProcessName "*yuv*"
    
            Start-Sleep -s 30

            if($d.MainWindowTitle -eq "YUV Player Deluxe"){
                #slient install success
                echo "slient install success"
                $d.MainWindowTitle
                $flag = $false
            }

            if($i -eq 3){
                #install fail , will run script install
                echo "slient install fail , will run script install"

                cmdline -para1 "C:\Users\AndyLiao22060\Desktop\YUV\yuvplayer.exe" -para5 "nonlog"

                Start-Sleep -s 40

                [System.Windows.Forms.SendKeys]::SendWait("n")
                Start-Sleep -s 2
                [System.Windows.Forms.SendKeys]::SendWait("n")
                Start-Sleep -s 2
                [System.Windows.Forms.SendKeys]::SendWait("n")
                Start-Sleep -s 2
                [System.Windows.Forms.SendKeys]::SendWait("n")
                Start-Sleep -s 2
                [System.Windows.Forms.SendKeys]::SendWait("n")
                Start-Sleep -s 15
                [System.Windows.Forms.SendKeys]::SendWait("f")


                $flag = $false
            }

            $i += 1
        }

    }
    
    if($status -eq ""){
        $action="yuvplayer"

        Stop-Process -Name "*yuv*"

        start-sleep -s 5
        
        [KeySends.KeySend]::KeyDown("LWin")
        [KeySends.KeySend]::KeyUp("LWin")

        start-sleep -s 5

        Set-Clipboard "YUV Player Deluxe"

        [KeySends.KeySend]::KeyDown([System.Windows.Forms.Keys]::ControlKey)
        [KeySends.KeySend]::KeyDown([System.Windows.Forms.Keys]::V)

        [KeySends.KeySend]::KeyUp([System.Windows.Forms.Keys]::ControlKey)
        [KeySends.KeySend]::KeyUp([System.Windows.Forms.Keys]::V)
     

        start-sleep -s 5
        [System.Windows.Forms.SendKeys]::SendWait("{Enter}")
        start-sleep -s 5

        startyuvsetting

        start-sleep -s 720

        screenshot -para3 "nonlog" -para5 "play_yuvvideo_complete"

        Stop-Process -Name "*yuv*" 
    }

    if($status -eq "play"){
        $action="yuvplayer-play"

        Stop-Process -Name "*yuv*"

        start-sleep -s 5
        
        [KeySends.KeySend]::KeyDown("LWin")
        [KeySends.KeySend]::KeyUp("LWin")

        start-sleep -s 5

        Set-Clipboard "YUV Player Deluxe"

        [KeySends.KeySend]::KeyDown([System.Windows.Forms.Keys]::ControlKey)
        [KeySends.KeySend]::KeyDown([System.Windows.Forms.Keys]::V)

        [KeySends.KeySend]::KeyUp([System.Windows.Forms.Keys]::ControlKey)
        [KeySends.KeySend]::KeyUp([System.Windows.Forms.Keys]::V)
     

        start-sleep -s 5
        [System.Windows.Forms.SendKeys]::SendWait("{Enter}")
        start-sleep -s 5

        startyuvsetting

        $sendkeylist = @(
            "{ENTER}",
            " ",
            "{PgUp}",
            "{PgDn}",
            "{Home}",
            "{End}",
            "{F8}",
            "{TAB 8}",
            3,
            "{TAB 4}",
            "{Enter 2}"
        )
    
        foreach ($sditem in $sendkeylist){
            start-sleep -s 5
            echo $sditem
            [System.Windows.Forms.SendKeys]::SendWait($sditem)

            try{
                screenshot -para3 "nonlog" -para5 "$sditem"
            }catch{
                screenshot -para3 "nonlog"
            }
        }    

        start-sleep -s 720

        screenshot -para3 "nonlog" -para5 "play_yuvvideo_complete"

        #Stop-Process -Name "*yuv*"
    }
    #-------------------------------------------------------
    if($status -eq "S4"){
        $action="yuvplayer-S4"

        #Stop-Process -Name "*yuv*"
        if(Get-Process -Name "*yuv*"){
            #[System.Windows.Forms.SendKeys]::SendWait("%{TAB}")
            Add-Type -TypeDefinition @"
    using System;
    using System.Runtime.InteropServices;

    public static class User32 {
        [DllImport("user32.dll", SetLastError = true)]
        public static extern IntPtr FindWindow(string lpClassName, string lpWindowName);

        [DllImport("user32.dll")]
        [return: MarshalAs(UnmanagedType.Bool)]
        public static extern bool SetForegroundWindow(IntPtr hWnd);
    }
"@ 


$hWnd = [User32]::FindWindow([NullString]::Value, "BigBuckBunny_CIF_24fps.yuv - YUV Player Deluxe")


if ($hWnd -ne [IntPtr]::Zero) {
    [User32]::SetForegroundWindow($hWnd)
}
        echo "waitting for $waitsecond s play yuv video"
        start-sleep -s $waitsecond

        screenshot -para3 "nonlog" -para5 "play_yuvvideo_with resume from S4"

        }else{
            start-sleep -s 5
        
        [KeySends.KeySend]::KeyDown("LWin")
        [KeySends.KeySend]::KeyUp("LWin")

        start-sleep -s 5

        Set-Clipboard "YUV Player Deluxe"

        [KeySends.KeySend]::KeyDown([System.Windows.Forms.Keys]::ControlKey)
        [KeySends.KeySend]::KeyDown([System.Windows.Forms.Keys]::V)

        [KeySends.KeySend]::KeyUp([System.Windows.Forms.Keys]::ControlKey)
        [KeySends.KeySend]::KeyUp([System.Windows.Forms.Keys]::V)
     

        start-sleep -s 5
        [System.Windows.Forms.SendKeys]::SendWait("{Enter}")
        start-sleep -s 5

            startyuvsetting


            #-----loop setting-------
            $sendkeylist = @(
                "{F8}",
                "{TAB 9}",
                "{+}",
                "{Enter}"
            )

            foreach ($sditem in $sendkeylist){
                start-sleep -s 5
                echo $sditem
                [System.Windows.Forms.SendKeys]::SendWait($sditem)

                #try{
                #    screenshot -para3 "nonlog" -para5 "$sditem"
                #}catch{
                #    screenshot -para3 "nonlog"
                #}
            }
            #-----loop setting-------
        }
        


        

        #taskschedule_attime_repeat -para1 5 -para4 "nonlog"

        #hibernaten -para4 "nonlog"

        #taskschedule_delete -para1 "nonlog"
    }
    #-------------------------------------------------------
    if($status -eq "reboot"){
        $action="yuvplayer-reboot"

        Stop-Process -Name "*yuv*"

        start-sleep -s 5
        
        [KeySends.KeySend]::KeyDown("LWin")
        [KeySends.KeySend]::KeyUp("LWin")

        start-sleep -s 5

        Set-Clipboard "YUV Player Deluxe"

        [KeySends.KeySend]::KeyDown([System.Windows.Forms.Keys]::ControlKey)
        [KeySends.KeySend]::KeyDown([System.Windows.Forms.Keys]::V)

        [KeySends.KeySend]::KeyUp([System.Windows.Forms.Keys]::ControlKey)
        [KeySends.KeySend]::KeyUp([System.Windows.Forms.Keys]::V)
     

        start-sleep -s 5
        [System.Windows.Forms.SendKeys]::SendWait("{Enter}")
        start-sleep -s 5

        startyuvsetting

        echo "waitting for $waitsecond s after reboot"
        start-sleep -s $waitsecond

        screenshot -para3 "nonlog" -para5 "play_yuvvideo_before reboot"
    }
    #-------------------------------------------------------
    if($status -eq "S5"){
        $action="yuvplayer-S5"

        Stop-Process -Name "*yuv*"

        start-sleep -s 5
        
        [KeySends.KeySend]::KeyDown("LWin")
        [KeySends.KeySend]::KeyUp("LWin")

        start-sleep -s 5

        Set-Clipboard "YUV Player Deluxe"

        [KeySends.KeySend]::KeyDown([System.Windows.Forms.Keys]::ControlKey)
        [KeySends.KeySend]::KeyDown([System.Windows.Forms.Keys]::V)

        [KeySends.KeySend]::KeyUp([System.Windows.Forms.Keys]::ControlKey)
        [KeySends.KeySend]::KeyUp([System.Windows.Forms.Keys]::V)
     

        start-sleep -s 5
        [System.Windows.Forms.SendKeys]::SendWait("{Enter}")
        start-sleep -s 5

        startyuvsetting

        echo "waitting for $waitsecond s after S5"
        start-sleep -s $waitsecond

        screenshot -para3 "nonlog" -para5 "play_yuvvideo_before S5"

        #taskschedule_atlogin -para3 "nonlog"

        #ipmitool_shutdown -para4 "nonlog"

        #taskschedule_delete -para1 "nonlog"

    }
    #-------------------------------------------------------


    $results = "check-screenshot"
    #output log
    Get-Module -name "outlog"|remove-module
    $mdpath=(gci -path "C:\testing_AI\modules\" -r -file |?{$_.name -match "outlog" -and $_.name -match "psm1"}).fullname
    Import-Module $mdpath -WarningAction SilentlyContinue -Global
    #write-host "Do $action!"
    outlog $action $results $tcnumber $tcstep $index
}

Export-ModuleMember -Function yuvplayer