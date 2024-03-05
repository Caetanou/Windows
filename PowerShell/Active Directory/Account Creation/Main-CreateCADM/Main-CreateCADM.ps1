<#

Knowledge Article: KBXXXXXXX

This Script is used to automatically create CADM accounts based on the EmployeeID of the requested user.

Please do not attempt to modify this Script.

Any issues, please contact HugoCaetano@cofcointernational.com.

Thank you.

#>

Set-Location "\\EUFS01\SDESK\New Scripts\Account Creation\Main-CreateCADM" # Working directory.

. "\\EUFS01\SDESK\New Scripts\Functions\Write-OnPremLog\Write-OnPremLog.ps1" #Write-OnPremLog Function.

Clear-Host

do {

    $SRID = Read-Host "Request or Task Number (SCTASK, RITM, REQ)"

    Write-Host

    $EMPID = Read-Host -Prompt "EmployeeID"

    }while ($SRID -eq "" -and $EMPID -eq ""){

}

Write-Host

$MSOLModule = Get-Module | Where-Object {$_.Name -eq "MSOnline"}

if($Null -eq $MSOLModule){

    try{

        Connect-MSOLService -ErrorAction Stop

        Write-Host "Welcome to Microsoft Online!" -ForegroundColor Green

    }catch{

        Write-OnPremLog -Request $SRID -ErrorMessage $_.Exception.Message

        Write-Host
            
        Write-Host $_.Exception.Message -ForegroundColor Red ; Write-Host

        Write-Host "NOTE - The Script will end in 30 seconds to prevent unwanted modifications, if you want to force close it press 'CTRL + C'." -ForegroundColor Red ; Start-Sleep 30 ; Exit

    }

}else{

    Write-Host "You're already connected to Microsoft Online!" -ForegroundColor Green

}

Write-Host

if($SRID -like "SCTASK*" -or $SRID -like "RITM*" -or $SRID -like "REQ*" -or $SRID -like "ManualRun*"){

    $OnPremQuery = Get-ADUser -Filter {employeeID -eq $EMPID} -Properties UserPrincipalName, DisplayName, Mail, employeeType, extensionAttribute2, GivenName, SN, Title

    if ($Null -ne $OnPremQuery){

        $AzureQuery = Get-MSOLUser -UserPrincipalName $CADM_UPN -ErrorAction SilentlyContinue

        if($Null -eq $AzureQuery){

            if($OnPremQuery.employeeType -eq "EMP" -or $OnPremQuery.extensionAttribute2 -eq "EMP"){

                $Title = "Internal"

            }else{

                $Title = "External"

            }

            $CADM_UPN = 'CADM_'+$OnPremQuery.UserPrincipalName

            $CADM_DisplayName = 'CADM '+$OnPremQuery.DisplayName

            $PasswordGen = -Join ("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ@+-!?~^Â´`*,.\|123456789".ToCharArray() | Get-Random -Count 16 | ForEach-Object {[char]$_})

            try {

                if($OnPremQuery.Title -ne "IT Support Analyst"){

                    $CADMUser = New-MSOLUser `
                    -UserPrincipalName $CADM_UPN `
                    -DisplayName $CADM_DisplayName `
                    -AlternateEmailAddresses $OnPremQuery.Mail `
                    -Title $Title `
                    -FirstName $OnPremQuery.GivenName `
                    -LastName $OnPremQuery.SN `
                    -Password $PasswordGen -ErrorAction Stop 

                }else{

                    $CADMUser = New-MSOLUser `
                    -UserPrincipalName $CADM_UPN `
                    -DisplayName $CADM_DisplayName `
                    -AlternateEmailAddresses $OnPremQuery.Mail `
                    -Title $Title `
                    -Department "Global Service Desk" `
                    -FirstName $OnPremQuery.GivenName `
                    -LastName $OnPremQuery.SN `
                    -Password $PasswordGen -ErrorAction Stop

                }

            }catch{

                Write-OnPremLog -Request $SRID -ErrorMessage $_.Exception.Message

                Write-Host
                
                Write-Host $_.Exception.Message -ForegroundColor Red ; Write-Host

                Write-Host "NOTE - The Script will end in 30 seconds to prevent unwanted modifications, if you want to force close it press 'CTRL + C'." -ForegroundColor Red ; Start-Sleep 30 ; Exit

            }
            
            Write-Host

            Write-Host "$($CADMUser.UserPrincipalName) has been created." -ForegroundColor Green ; Write-Host
            
            Write-Host "CADM Account Username - $($CADMUser.UserPrincipalName)" -ForegroundColor Cyan ; Write-Host

            Write-Host "CADM Account Display Name - $($CADMUser.DisplayName)" -ForegroundColor Cyan ; Write-Host

            Write-Host "CADM Account Password - $($CADMUser.Password)" -ForegroundColor Cyan ; Write-Host

            Write-Host 'WARNING: The credentials were exported to this PowerShell session only! Do NOT close this window before sending the credentials to the requested user.' -ForegroundColor Yellow ; Write-Host

            Write-Host 'The shell will remain open for 5 minutes.' -ForegroundColor Yellow ; Start-Sleep 300 ; Exit


        }elseif($AzureQuery.BlockCredential -eq $False){

            Write-Host "$($AzureQuery.UserPrincipalName) already exists and is active." -ForegroundColor Yellow ; Write-Host

            Write-Host "NOTE - The Script will end in 30 seconds, if you want to force close it press 'CTRL + C'." -ForegroundColor Yellow ; Start-Sleep 30 ; Exit

        }else{

            Write-Host "$($AzureQuery.UserPrincipalName) already exists but is inactive. Do you want to re-enable the account?" -ForegroundColor Yellow ; Write-Host
        
            $ReEnable = Read-Host "(Y/N)"

            if($ReEnable -eq "Yes" -or $ReEnable -eq "Y"){

                $PasswordGen = -Join ("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ@+-!?~^Â´`*,.\|123456789".ToCharArray() | Get-Random -Count 16 | ForEach-Object {[char]$_})

                try{

                    Set-MSOLUser -UserPrincipalName $($AzureQuery.UserPrincipalName) -DisplayName $CADM_DisplayName -BlockCredential $False -ErrorAction Stop

                    $PasswordReset = Set-MSOLUserPassword -UserPrincipalName $($AzureQuery.UserPrincipalName) -NewPassword $PasswordGen -ForceChangePassword $True -ErrorAction Stop

                    Write-Host

                    Write-Host "$($AzureQuery.UserPrincipalName) has been re-enabled." -ForegroundColor Green ; Write-Host
            
                    Write-Host "CADM Account Username - $($AzureQuery.UserPrincipalName)" -ForegroundColor Cyan ; Write-Host

                    Write-Host "CADM Account Display Name - $($CADM_DisplayName)" -ForegroundColor Cyan ; Write-Host

                    Write-Host "CADM Account Password - $($PasswordReset)" -ForegroundColor Cyan ; Write-Host

                    Write-Host 'WARNING: The credentials were exported to this PowerShell session only! Do NOT close this window before sending the credentials to the requested user.' -ForegroundColor Yellow ; Write-Host

                    Write-Host 'The shell will remain open for 5 minutes.' -ForegroundColor Yellow ; Start-Sleep 300 ; Exit

                }catch{

                    Write-OnPremLog -Request $SRID -ErrorMessage $_.Exception.Message

                    Write-Host
                    
                    Write-Host $_.Exception.Message -ForegroundColor Red ; Write-Host
    
                    Write-Host "NOTE - The Script will end in 30 seconds to prevent unwanted modifications, if you want to force close it press 'CTRL + C'." -ForegroundColor Red ; Start-Sleep 30 ; Exit

                }

            }else{

                Write-Host "Operation cancelled!" -ForegroundColor Yellow ; Write-Host

                Write-Host "NOTE - The Script will end in 30 seconds, if you want to force close it press 'CTRL + C'." -ForegroundColor Yellow ; Start-Sleep 30 ; Exit

            }

        }

    }else{
    
        Write-Host

        Write-Host "No Active Directory user has been found with the employeeID: $($EMPID)." -ForegroundColor Red ; Write-Host

        Write-Host "Please double check the 'employeeID' attribute. It shouldn't be empty!" -ForegroundColor Red ; Write-Host

        Write-Host "NOTE - The Script will end in 30 seconds to prevent unwanted modifications, if you want to force close it press 'CTRL + C'." -ForegroundColor Red ; Start-Sleep 30 ; Exit
    
    }

}else{

    Write-Host

    Write-Host "Invalid request! Please re-run the Script and try again." -ForegroundColor Red ; Write-Host

    Write-Host "NOTE - The Script will end in 30 seconds, if you want to force close it press 'CTRL + C'." -ForegroundColor Red ; Start-Sleep 30 ; Exit

}
