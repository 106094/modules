
function screenshot_handy([int]$para1){

    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force;
    $wshell=New-Object -ComObject wscript.shell
       Add-Type -AssemblyName System.Windows.Forms,System.Drawing,Microsoft.VisualBasic
     
if($para1 -eq 0){
$para1=3
}

Start-Sleep -s $para1

[void] [Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
[Reflection.Assembly]::LoadWithPartialName("System.Drawing")
$screens = [system.windows.forms.screen]::AllScreens
$moct=0

foreach($screen in $screens){

  $bounds=$Screen.Bounds
  
   $bmp = New-Object Drawing.Bitmap $bounds.width, $bounds.height
   $graphics = [Drawing.Graphics]::FromImage($bmp)

   $graphics.CopyFromScreen($bounds.Location, [Drawing.Point]::Empty, $bounds.size)
   $dnow=get-date -format "yyMMdd_HHmmss"
   
   if($screens.count -gt 1){
   if($Screen.Primary -eq $true){$picfile="$env:userprofile\desktop\"+$($dnow)+"_screenshot#Pri#"+$moct+".jpg"}
   else{$picfile="$env:userprofile\desktop\"+$($dnow)+"_screenshot#"+$moct+".jpg"}
    }
    else{
    $picfile="$env:userprofile\desktop\"+$($dnow)+"_screenshot.jpg"
    }
   Start-Sleep -s 2
   $bmp.Save($picfile)

   $graphics.Dispose()
   $bmp.Dispose()
   Start-Sleep -s 2

   $moct++
   $Indexa=$Indexa+@($picfile)
   
}

}

    export-modulemember -Function screenshot_handy
