Clear-Host

$ProgressPreference = "SilentlyContinue"

$CurrentUser = $ENV:USERNAME

if ($CurrentUser -NotLike "cofco"){

    Write-Host "You're currently running this Script without the Local Administrator account. Unfortunately the cmdlets used to install the Media Feature Pack have no way to invoke the credential parameter." -ForegroundColor Yellow ; Write-Host

    Write-Host "Please exit this Script and run it via an elevated PowerShell session." -ForegroundColor Yellow

    Start-Sleep 30 ; Exit

}

$GetMPack1 = Get-WindowsCapability -Online | Where-Object {$_.Name -Like "*MediaFeaturePack*"}

if ($GetMPack1.State -eq "NotPresent"){

    Write-Host "Media Feature Pack is not present. Attempting installation. This proccess can take 10-15 minutes, please be patient." -ForegroundColor Yellow ; Write-Host

    Write-Host "1st try." -ForegroundColor Green ; Write-Host

    try{

        Add-WindowsCapability -Online -Name "Media.MediaFeaturePack~~~~0.0.1.0" -ErrorAction Stop

    }catch{

        $Error1 = $_.Exception.Message

    }

    if ($Null -ne $Error1){

        try{

            Write-Host "An error occured. Retrying installation." -ForegroundColor Red ; Write-Host

            Write-Host "2nd try." -ForegroundColor Yellow ; Write-Host

            Add-WindowsCapability -Online -Name "Media.MediaFeaturePack~~~~0.0.1.0" -ErrorAction Stop

        }catch{

            $Error2 = $_.Exception.Message

        }

    }else{

        $GetMPack2 = Get-WindowsCapability -Online | Where-Object {$_.Name -Like "*MediaFeaturePack*"}

        if ($GetMPack2.State -ne "Installed"){

            Write-Host "No error was thrown but the Media Feature Pack is still not installed. Retrying installation." -ForegroundColor Red ; Write-Host

            Write-Host "3rd try." -ForegroundColor Red ; Write-Host

            try{

                Add-WindowsCapability -Online -Name "Media.MediaFeaturePack~~~~0.0.1.0" -ErrorAction Stop
        
            }catch{
        
                $Error3 = $_.Exception.Message
        
            }

        }else{

            Write-Host "Media Feature Pack installed. Please restart your computer in order for the changes to apply." -ForegroundColor Green

        }

    }

}else{

    Write-Host "Media Feature Pack is already installed. You may need to restart your computer in order for the changes to apply." -ForegroundColor Yellow

    Start-Sleep 30 ; Exit

}
