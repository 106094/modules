

function appfocus ([string]$para1){

$paracheck1=$PSBoundParameters.ContainsKey('para1')


if($paracheck1 -eq $false -or $para1.Length -eq 0){
exit
}

$processname=$para1


  $Signature = @"
[DllImport("user32.dll")]public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);
"@

$ShowWindowAsync = Add-Type -MemberDefinition $Signature -Name "Win32ShowWindowAsync" -Namespace Win32Functions -PassThru

# Minimize the PowerShell console



$idcontrol=(get-process -name $processname).Id

$ShowWindowAsync::ShowWindowAsync((Get-Process -Id $idcontrol).MainWindowHandle, 2)

# Restore the PowerShell console

$ShowWindowAsync::ShowWindowAsync((Get-Process -Id $idcontrol).MainWindowHandle, 4)

  }

    export-modulemember -Function appfocus