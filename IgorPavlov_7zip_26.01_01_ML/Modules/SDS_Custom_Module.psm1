<#
Module Version: 1.4
PowerShell Module monitored by Microsoft Intune Scripts and Remediations
Please, do not modify this file in a monitored environment
#>

function FN_Utility {
param(
[Parameter(Mandatory = $true)][string]$Action
)
$Path_Log = 'C:\Sys_com\Logs'
if ($Action -eq 'UnInstall') { $Path_LogFile = ($Path_Log + '\' + $($App_Info.FullName) + '_UnInstall.log') } Else { $Path_LogFile = ($Path_Log + '\' + $($App_Info.FullName) + '.log') }
$Path_Script = $(Get-Location).Path
$Path_Prog = $Path_Script + "\Prog"
$Global:ExitCode = 0
$Folder_AllUserDesktop = [Environment]::GetFolderPath("CommonDesktopDirectory") # All user desktop
$Folder_AllUserPrograms = [Environment]::GetFolderPath("CommonPrograms") # Start Menu for All user
$Folder_ProgramData = (Get-Item env:ALLUSERSPROFILE).value
$Script_Start_Time = get-date -Format 'HH:mm:ss'
$System_Reboot_Needed = $false
$Program_Files = (Get-Item env:ProgramW6432).value
$Program_Files_x86 = (Get-Item "env:ProgramFiles(x86)").value
$Module_ID = $(Get-FileHash -Path "$($Path_Script)\Modules\SDS_Custom_Module.psm1").hash
$Output_Values_Items = @('Path_Log','Path_LogFile','Path_Script','Path_Prog','Folder_AllUserDesktop','Folder_AllUserPrograms','Folder_ProgramData','Script_StartTime','System_Reboot_Needed','ProgramFiles','ProgramFiles_x86','Module_ID')
$Output_Values_Items_Data = $Path_Log, $Path_LogFile, $Path_Script, $Path_Prog, $Folder_AllUserDesktop, $Folder_AllUserPrograms, $Folder_ProgramData, $Script_Start_Time, $System_Reboot_Needed, $Program_Files, $Program_Files_x86, $Module_ID
$Output_Values = New-Object PSObject
$Output_Index = 0
foreach ($Item in $Output_Values_Items) { $Output_Values | Add-Member -MemberType NoteProperty -Name $Item -Value $($Output_Values_Items_Data[$Output_Index]) ; $Output_Index++ }
Return $Output_Values

}

function FN_Get_AppInformation {

$APP_Company = (Select-String -Path .\Install.ps1 -Pattern ('APP_Company'))[0].ToString().Split('=')[1].Replace('"','').Trim()
$APP_Name = (Select-String -Path .\Install.ps1 -Pattern ('APP_Name'))[0].ToString().Split('=')[1].Replace('"','').Trim()
$APP_Version = (Select-String -Path .\Install.ps1 -Pattern ('APP_Version'))[0].ToString().Split('=')[1].Replace('"','').Trim()
$APP_Language = (Select-String -Path .\Install.ps1 -Pattern ('APP_Language'))[0].ToString().Split('=')[1].Replace('"','').Trim()
$APP_System = (Select-String -Path .\Install.ps1 -Pattern ('APP_System'))[0].ToString().Split('=')[1].Replace('"','').Trim()
$APP_InternalVersion = (Select-String -Path .\Install.ps1 -Pattern ('APP_InternalVersion'))[0].ToString().Split('=')[1].Replace('"','').Trim()
$Output_Items = @('FullName','Company','Name','Version','System','Language','InternalVersion')
$Output_Items_Data = $(("$($APP_Company)_$($APP_Name)_$($APP_Version)_$($APP_System)_$($APP_Language)").Replace(' ','_')), $APP_Company, $APP_Name, $APP_Version, $APP_System, $APP_Language, $APP_InternalVersion
$Output_Values = New-Object PSObject
$Output_Index = 0
foreach ($Item in $Output_Items) { $Output_Values | Add-Member -MemberType NoteProperty -Name $Item -Value $($Output_Items_Data[$Output_Index]) ; $Output_Index++ }
Return $Output_Values

}

function FN_ComputerInformation {

$Computer_OS_Info = Get-CimInstance Win32_OperatingSystem | Select Caption, Version, OSArchitecture 
$Computer_LoggedOn_User_Info += (Get-CimInstance win32_loggedonuser | where { ($_.antecedent.Domain -ne $env:COMPUTERNAME) -and ($_.antecedent.Name -ne 'SYSTEM') } | Select-Object -Unique).antecedent | Select Domain,Name
$Computer_HW_Info = Get-WMIObject -class Win32_ComputerSystem | Select Domain,Model
$Computer_Language_Info = Get-Culture
switch ($Computer_LoggedOn_User_Info.name.count) {
    {$_ -le 0} { $Logged_User = 'No user logged on' }
    {$_ -eq 1} { $Logged_User = ("$($Computer_LoggedOn_User_Info.domain)\$($Computer_LoggedOn_User_Info.name)") }
    {$_ -ge 2} { foreach ($Item in $Computer_LoggedOn_User_Info) { $Logged_User += ("$($Item.domain)\$($Item.name),") } ; $Logged_User = $Logged_User.Substring(0,$Logged_User.Length-1) }
}
$Output_Items = @('Launch_Process_User','Hostname','OS_Caption','OS_Version','OS_Architecture','OS_Language','Computer_Model','Logged_User_Name')
$Output_Items_Data = $([System.Security.Principal.WindowsIdentity]::GetCurrent().Name), $($env:computername), $($Computer_OS_Info.Caption), $($Computer_OS_Info.Version), $($Computer_OS_Info.OSArchitecture), $($Computer_Language_Info.DisplayName), $($Computer_HW_Info.Model), $Logged_User
$Output_Values = New-Object PSObject
$Output_Index = 0
foreach ($Item in $Output_Items) { $Output_Values | Add-Member -MemberType NoteProperty -Name $Item -Value $($Output_Items_Data[$Output_Index]) ; $Output_Index++ }
Return $Output_Values

}

function FN_Create_LogFile {

FN_Update_LogFile -Message '-----------------------------------------------------------------------------------'
FN_Update_LogFile -Message $App_Info.FullName
FN_Update_LogFile -Message "Internal Version: $($App_Info.InternalVersion)"
FN_Update_LogFile -Message '-----------------------------------------------------------------------------------'
FN_Update_LogFile -Message "<<<< Start $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss') >>>>>"
FN_Update_LogFile -Message " "
FN_Update_LogFile -Message "O.S. Caption >>> $($Computer_info.OS_Caption) - $($Computer_info.OS_Architecture)"
FN_Update_LogFile -Message "O.S. Language >>> $($Computer_info.OS_Language)"
FN_Update_LogFile -Message "O.S. Version >>> $($Computer_info.OS_Version)"
FN_Update_LogFile -Message "O.S. Hostname >>> $($Computer_info.Hostname)"
FN_Update_LogFile -Message "Logged User Name >>> $($Computer_info.Logged_User_Name)"
FN_Update_LogFile -Message "Install User >>> $($Computer_info.Launch_Process_User)"
FN_Update_LogFile -Message "Install Source Path >>> $($Util_Info.Path_Script)"
FN_Update_LogFile -Message "Custom Module ID >>> $($Util_Info.Module_ID)"
FN_Update_LogFile -Message '-----------------------------------------------------------------------------------'
FN_Update_LogFile -Message " "

}

Function FN_Message_To_User { 
param(
[Parameter(Mandatory = $true)][string]$EN_Text,
[Parameter(Mandatory = $true)][string]$ES_Text
)
FN_Update_LogFile -Message ' '
FN_Update_LogFile -Message '> Launch message to user...'

add-Type -AssemblyName Microsoft.VisualBasic
$Response = [Microsoft.VisualBasic.Interaction]::MsgBox("$ES_Text`n`n$EN_Text", 'OkCancel,systemmodal,Information', 'Atención / Attention')
FN_Update_LogFile -Message ('>>> User click action: ' + $Response)
Return $Response

}

function FN_Update_LogFile { 	
param(
[Parameter(Mandatory = $true)][string]$Message
)
$DateTime = Get-Date -Format ‘HH:mm:ss’
Add-Content -Value "$(Get-Date -Format ‘HH:mm:ss’) - $Message" -Path $($Util_Info.Path_LogFile)
}

Function FN_Extract_Zip {
param(
[Parameter(Mandatory = $true)][string]$ZipFile,
[Parameter(Mandatory = $true)][string]$Destination
)
FN_Update_LogFile -Message ' '
FN_Update_LogFile -Message "> Unzipping file..."

if (!(Test-Path $Zipfile)) {
    FN_Update_LogFile -Message '>>> [Error] ZIP File not found'
    $Result_UnZip = $false
 } Else {
    FN_Update_LogFile -Message ">>> Source: $ZipFile"
    FN_Update_LogFile -Message ">>> Destination: $Destination"
    Try {
        Expand-Archive -Path $ZipFile -DestinationPath $Destination -Force -ErrorAction Stop
        FN_Update_LogFile -Message '>>> UnZip file: Success'
        $Result_UnZip = $true
    } Catch {
        FN_Update_LogFile -Message '>>> [Error] UnZip failed'
        FN_Update_LogFile -Message ('>>> Output: ' + $_.Exception.Message)
        $Result_UnZip = $false
    }
}
return $Result_UnZip

}

function FN_Add_Firewall_Rules {
param(
[Parameter(Mandatory = $true)][string]$ProgramFile
)
FN_Update_LogFile -Message ' '
FN_Update_LogFile -Message "> Adding FW Rules for $ProgramFile"

if (!(Test-Path $ProgramFile)) {
    FN_Update_LogFile -Message '>>> [Error] File or path does not exist'
    $Result_Add_FWRules = $false
} Else {
    Try {
        New-NetFirewallRule -DisplayName "$((Get-Item $ProgramFile).Name) TCP" -Direction Inbound -Program $ProgramFile -Protocol TCP -Action Allow -Profile Domain, Private -Enabled True -ErrorAction Stop | Out-Null
        New-NetFirewallRule -DisplayName "$((Get-Item $ProgramFile).Name) UDP" -Direction Inbound -Program $ProgramFile -Protocol UDP -Action Allow -Profile Domain, Private -Enabled True -ErrorAction Stop | Out-Null
        FN_Update_LogFile -Message '>>> Firewall Rules created'
        $Result_Add_FWRules = $true
    } Catch {
        FN_Update_LogFile -Message '>>> [Error] Firewall Rules not created'
        FN_Update_LogFile -Message ('>>> Output: ' + $_.Exception.Message)
        $Result_Add_FWRules = $false
    }
}
return $Result_Add_FWRules

}

function FN_Remove_Folder {
param(
[Parameter(Mandatory = $true)][string]$FolderPath
)
FN_Update_LogFile -Message ' '
FN_Update_LogFile -Message "> Remove folder and content: $FolderPath"

if (!(Test-Path $FolderPath)) {
    FN_Update_LogFile -Message '>>> Folder path does not exist'
    $Result_RemoveFolder = $true
} Else {
    Try {
        Remove-Item -Path $FolderPath -Recurse -Force -ErrorAction Stop
        FN_Update_LogFile -Message '>>> Deleted folder and content'
        $Result_RemoveFolder = $true
     } Catch {
        FN_Update_LogFile -Message '>>> [Error] Some content or folder can not be deleted'
        FN_Update_LogFile -Message ('>>> Output: ' + $_.Exception.Message)
        $Result_RemoveFolder = $false
     }
}
return $Result_RemoveFolder

}

function FN_Close_Process {
param(
[Parameter(Mandatory = $true)][string]$ProcessName
)
FN_Update_LogFile -Message ' '
FN_Update_LogFile -Message "> Close process (if running): $ProcessName"

if (!(Get-Process -Name $ProcessName -ErrorAction SilentlyContinue)) {
    FN_Update_LogFile -Message '>>> Process not running'
    $Result_CloseProcess = $True
} Else {
    $Counter = 0
    $Running_Processes = (Get-Process -Name $ProcessName).Id
    FN_Update_LogFile -Message ('>>> Found ' + $($Running_Processes.Count) + ' processes running')
    foreach ($Proc in $Running_Processes) {
        Try {
            kill -Id $proc -Force -ErrorAction Stop
            $Counter ++
        } Catch {}
    }
    FN_Update_LogFile -Message ('>>> Closed ' + $Counter + ' of ' + $($Running_Processes.Count) + ' processes')
    if ($($Running_Processes.Count) -eq $Counter) { $Result_CloseProcess = $true } Else { $Result_CloseProcess = $false }
}
return $Result_CloseProcess

}

Function FN_MSI_Installer {
param(
[Parameter(Mandatory = $true)][ValidateSet('Install', 'UnInstall')][string]$Action,
[Parameter(Mandatory = $true,ParameterSetName='Install')][string]$MSIFilePath,
[Parameter(Mandatory = $true,ParameterSetName='UnInstall')][string]$ProductCode,
[Parameter(Mandatory = $false)][string]$Additional_Arguments
)
FN_Update_LogFile -Message ' '

Switch ($Action) {
    'Install' {
        if (Test-Path $MSIFilePath) {
            FN_Update_LogFile -Message ('> ' + $Action + ' MSI: ' + $MSIFilePath)
            $Install_MSIFile = $((Get-Item $MSIFilePath).Name)
            $Install_MSI_Log = ($($Util_Info.Path_Log) + '\Install - ' + $Install_MSIFile + '.log')
            $Install_Params = ('/i "' + $MSIFilePath + '" ' + $Additional_Arguments + ' /qn ALLUSERS=1 REINSTALLMODE=omus /norestart /L*v ' + """$Install_MSI_Log""")
            $Install_ExitCode = Start-Process "MSIExec" -ArgumentList $Install_Params -Wait -NoNewWindow -PassThru
            FN_Update_LogFile -Message ('>>> ExitCode: ' + $($Install_ExitCode.ExitCode))
            Switch ($Install_ExitCode.ExitCode) {
                '3010' { $Util_Info.System_Reboot_Needed = $true ; FN_Update_LogFile -Message '>>> Application Installed, but need a reboot' }
                '0' { FN_Update_LogFile -Message '>>> Application Installed' }
                '1618' { FN_Update_LogFile -Message '>>> [Warning] Application not installed but based in ExitCode it will be retried in 60sec' }
                Default { FN_Update_LogFile -Message '>>> [ERROR] Application not Installed' }
            }
            $Result_MSI_Action = $($Install_ExitCode.ExitCode)
        } Else {
            FN_Update_LogFile -Message '[Error] >>> MSI file or path does not exist'
            $Result_MSI_Action = $false
        }
    }

    'Uninstall' {
        FN_Update_LogFile -Message ('> ' + $Action + ' ProductCode: ' + $ProductCode)
        $Uninstall_Keys = "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall","HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"
        $Product_Found = @()
        foreach ($U_Key in $Uninstall_Keys) {
            $Product_Found += Get-ChildItem -recurse $U_Key | Get-ItemProperty | where { $_.UninstallString -match $ProductCode } 
        }
        if ($Product_Found) {
            $Product_Name = ($Product_Found | Select DisplayName).DisplayName
            FN_Update_LogFile -Message ('>>> Found installed ProductCode ' + $ProductCode + ' with appl name "' + $Product_Name + '". Trying to uninstall...')
            $Uninstall_MSI_Log = ($($Util_Info.Path_Log) + '\UnInstall - ' + $Product_Name + '.log')
            $Uninstall_Params = (' /x ' + $ProductCode + ' REBOOT=ReallySuppress /q /L*v '+"""$Uninstall_MSI_Log""")
            $Uninstall_ExitCode = Start-Process "MSIExec" -ArgumentList $Uninstall_Params -Wait -NoNewWindow -PassThru
            FN_Update_LogFile -Message ('>>> ExitCode: ' + $($Uninstall_ExitCode.ExitCode))
            Switch ($Uninstall_ExitCode.ExitCode) {
                '3010' { $Util_Info.System_Reboot_Needed = $true ; FN_Update_LogFile -Message '>>> Application Uninstalled, but need a reboot' }
                '0' { FN_Update_LogFile -Message '>>> Application Uninstalled' }
                '1618' { FN_Update_LogFile -Message '>>> [Warning] Application not Uninstalled but based in ExitCode it will be retried in 60sec' }
                Default { FN_Update_LogFile -Message '>>> [ERROR] Application not Uninstalled' }
            }
            $Result_MSI_Action = $($Uninstall_ExitCode.ExitCode)
        } Else {
            FN_Update_LogFile -Message '>>> ProductCode not found as installed'
            $Result_MSI_Action = $true
        }
    }
    
    Default { FN_Update_LogFile -Message '>>> [ERROR] Invalid action' ; $Result_MSI_Action = 666 }
}
Return $Result_MSI_Action

}

Function FN_Run_EXE_File {
param(
[Parameter(Mandatory = $true)][string]$EXEFilePath,
[Parameter(Mandatory = $true)][string]$Wait,
[Parameter(Mandatory = $false)][string]$Arguments
)
FN_Update_LogFile -Message ' '
FN_Update_LogFile -Message "> Run EXE file: $EXEFilePath"

if (!(Test-Path $EXEFilePath)) {
    FN_Update_LogFile -Message '[Error] >>> EXE file or path does not exist'
    $Result_EXE_Action = $false
} Else {
    if (!($Arguments)) {
        switch ($Wait) {
            'All' { $Run_EXE_ExitCode = (Start-Process $EXEFilePath -Wait -PassThru -NoNewWindow).ExitCode }
            {$_ -match "^[\d\.]+$"} { Start-Process $EXEFilePath -PassThru -NoNewWindow | Out-Null ; Start-Sleep $_ ; $Run_EXE_ExitCode = 'Unknown' }
        }
    } Else {
        switch ($Wait) {
            'All' { $Run_EXE_ExitCode = (Start-Process $EXEFilePath -ArgumentList $Arguments -Wait -PassThru -NoNewWindow).ExitCode }
            {$_ -match "^[\d\.]+$"} { Start-Process $EXEFilePath -ArgumentList $Arguments -PassThru -NoNewWindow | Out-Null ; Start-Sleep $_ ; $Run_EXE_ExitCode = 'Unknown' }
        }
    }    
    FN_Update_LogFile -Message ('>>> ExitCode: ' + $($Run_EXE_ExitCode))
    Switch ($Run_EXE_ExitCode) {
        '3010' { $Util_Info.System_Reboot_Needed = $true ; FN_Update_LogFile -Message '>>> EXE process finished, but need a reboot' }
        '0' { FN_Update_LogFile -Message '>>> EXE process finished' }
        '1618' { FN_Update_LogFile -Message '>>> [Warning] EXE process finished but based in ExitCode this process will be retried in 60sec' }
        'Unknown' { FN_Update_LogFile -Message ('>>> [Warning] Waiting time was set to "' + $Wait + '". Process was not monitored') }
        Default { FN_Update_LogFile -Message '>>> [ERROR] EXE process finished with error' }
    }
    $Result_EXE_Action = $($Run_EXE_ExitCode)
}
Return $Result_EXE_Action

}

function FN_Copy_Log_To_Intune {
    try {
        $IntuneLogDir = "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs"

        if (!(Test-Path $IntuneLogDir)) {
            New-Item -Path $IntuneLogDir -ItemType Directory -Force | Out-Null
        }

        if (Test-Path $Util_Info.Path_LogFile) {
            $IntuneLogFile = Join-Path $IntuneLogDir ("App-" + (Split-Path $Util_Info.Path_LogFile -Leaf))
            Copy-Item -Path $Util_Info.Path_LogFile -Destination $IntuneLogFile -Force -ErrorAction SilentlyContinue
        }

        # Opcional: copiar todos os logs desse app
        Get-ChildItem -Path $Util_Info.Path_Log -Filter "$($App_Info.FullName)*.log" -ErrorAction SilentlyContinue |
            ForEach-Object {
                Copy-Item $_.FullName -Destination (Join-Path $IntuneLogDir ("App-" + $_.Name)) -Force -ErrorAction SilentlyContinue
            }
    } catch {
        # Sem impacto na execução principal
    }
}

function FN_Finish_LogFile {
param(
[Parameter(Mandatory = $true)][string]$Final_ExitCode
)

switch ($Final_ExitCode) {
    $true { $Final_ExitCode = 0 }
    $false { $Final_ExitCode = 666 }
}

If ($Util_Info.System_Reboot_Needed -and ($Final_ExitCode -eq 0)) { 
    $Additional_Info = ('[Info] ExitCode current value is set to "' + $Final_ExitCode + '" but a reboot was required previously. Setting ExitCode as "RebootNeeded" (3010)' )
    $Final_ExitCode = 3010
}
If ($Util_Info.System_Reboot_Needed -and ($Final_ExitCode -notin ('0','3010'))) { 
    $Additional_Info = ('[Info] Pending reboot notified during installation process but last ExitCode was "' + $Final_ExitCode + '"' )
}

if (!($Additional_Info)) { $Additional_Info = "Final ExitCode value: $Final_ExitCode" }

FN_Update_LogFile -Message ' '
FN_Update_LogFile -Message '-----------------------------------------------------------------------------------'
FN_Update_LogFile -Message '********** Installation Finished **********'
FN_Update_LogFile -Message '-----------------------------------------------------------------------------------'
FN_Update_LogFile -Message $Additional_Info
FN_Update_LogFile -Message "System pending reboot has been set to: $($Util_Info.System_Reboot_Needed)"
FN_Update_LogFile -Message "Execution Time: $(New-TimeSpan -Start $($Util_Info.Script_StartTime) -End $(Get-Date -Format 'HH:mm:ss'))"
FN_Update_LogFile -Message "<<<< Finish $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss') >>>>>"
FN_Update_LogFile -Message '-----------------------------------------------------------------------------------'
FN_Update_LogFile -Message ' '
FN_Update_LogFile -Message ' '

FN_Copy_Log_To_Intune

if (-not $DebugMode) {
    $host.SetShouldExit($Final_ExitCode)
    Exit $Final_ExitCode
}

}


function FN_Create_Shortcut {
param (
[Parameter(Mandatory = $true)]$Location,
[Parameter(Mandatory = $true)]$Name,
[Parameter(Mandatory = $true)]$IconPath,
[Parameter(Mandatory = $false)]$WorkingDirectory,
[Parameter(Mandatory = $true)]$Program,
[Parameter(Mandatory = $false)]$Arguments
)
FN_Update_LogFile -Message ' '
FN_Update_LogFile -Message ('> Creating shortcut in "' + $Location + '"')

if (!(Test-Path $Location) -or !(Test-Path $IconPath) -or !($Name)) {
    FN_Update_LogFile -Message '>>> [Error] Check path parameters'
    FN_Update_LogFile -Message '>>> [Error] Parameters like Location, Name and Icon are required or must exist'
    $Result_NewShortcut = $false
} Else {
    if ($(Test-Path -Path $program -PathType Container )) {
        FN_Update_LogFile -Message '>>> [Info] Location identified as: Folder'
    } elseif ($(Test-Path -Path $program -PathType Leaf )) {
        FN_Update_LogFile -Message '>>> [Info] Location identified as: File'
    } else { 
        FN_Update_LogFile -Message '>>> [Info] Location identified as: URL or path that currently does not exist' 
    }
    $ShortCutPath = $Location + "\" + $Name + ".lnk"
    $WScriptShell = New-Object -ComObject WScript.Shell
    $Shortcut = $WScriptShell.CreateShortcut($ShortCutPath)
    $Shortcut.TargetPath = $Program
    if ($Arguments) { $shortcut.Arguments = """$arguments""" }
    $shortcut.IconLocation = $iconPath
    $shortcut.WorkingDirectory = $WorkingDirectory
    $Shortcut.Save()
    $Result_NewShortcut = $true
    FN_Update_LogFile -Message '>>> Success'
}
return $Result_NewShortcut

}

function FN_Uninstall_Keys {
param(
[Parameter(Mandatory = $true)][ValidateSet('Add', 'Remove')][string]$Action
)
FN_Update_LogFile -Message ' '
FN_Update_LogFile -Message ('> ' + $Action + ' UnInstall registry keys')

$Registy_App_Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$($App_Info.FullName)"

if ($Action -eq 'Add') {
    if ($Util_Info.Path_Script -match "CCMCache") { $Installer = 'softwarecenter:' } Else { $Installer = 'companyportal:' }
    FN_Update_LogFile -Message ('>>> Installer detected as: "' + $Installer + '"')

    $App_Icon_Path = "$env:windir\Santander_App_Icon.ico"
    if (!(Test-Path -Path $App_Icon_Path)) {
                                                                                                                                                                                                                                                                                        $Icon_Code = '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'
        FN_Update_LogFile -Message '>>> Installing Application Icon'
        [IO.File]::WriteAllBytes($App_Icon_Path, $([Convert]::FromBase64String($Icon_Code)))
    }

    FN_Update_LogFile -Message '>>> Adding registry information'
    Try {
        Remove-Item -LiteralPath $Registy_App_Path -Recurse -ErrorAction SilentlyContinue
        New-Item -Path $Registy_App_Path -ErrorAction Stop | Out-Null 
        New-ItemProperty -path $Registy_App_Path -propertyType String -Name "DisplayName" -value "$($App_Info.Name)" -Force -ErrorAction Stop | Out-Null
        New-ItemProperty -path $Registy_App_Path -propertyType String -Name "UninstallString" -value $Installer -Force -ErrorAction Stop | Out-Null
        New-ItemProperty -path $Registy_App_Path -propertyType String -Name "DisplayIcon" -value $App_Icon_Path -Force -ErrorAction Stop | Out-Null
        New-ItemProperty -path $Registy_App_Path -propertyType DWord -Name "NoModify" -value "1" -Force -ErrorAction Stop | Out-Null
        New-ItemProperty -path $Registy_App_Path -propertyType DWord -Name "NoRepair" -value "1" -Force -ErrorAction Stop | Out-Null
        New-ItemProperty -path $Registy_App_Path -propertyType DWord -Name "NoRemove" -value "1" -Force -ErrorAction Stop | Out-Null
        New-ItemProperty -path $Registy_App_Path -propertyType String -Name "Publisher" -value "$($App_Info.Company)" -Force -ErrorAction Stop | Out-Null
        New-ItemProperty -path $Registy_App_Path -propertyType String -Name "DisplayVersion" -value "$($App_Info.Version )" -Force -ErrorAction Stop | Out-Null
        FN_Update_LogFile -Message '>>> Done'
        $Result_Reg_Keys = $true
    } Catch {
        FN_Update_LogFile -Message '>>> [Error] Registry keys could not be created'
        FN_Update_LogFile -Message ('>>> Output: ' + $_.Exception.Message)
        $Result_Reg_Keys = $false
    }
} Else {
    FN_Update_LogFile -Message ('>>> Removing registry keys for: ' + $($App_Info.FullName))
    Try {
        if (Test-Path $Registy_App_Path) {
            Remove-Item -LiteralPath $Registy_App_Path -Recurse -ErrorAction Stop
            FN_Update_LogFile -Message ('>>> Registry keys deleted')
        } Else { FN_Update_LogFile -Message ('>>> Registry keys not found') }
        $Result_Reg_Keys = $true
    } Catch {
        FN_Update_LogFile -Message '>>> [Error] Registry keys could not be deleted'
        FN_Update_LogFile -Message ('>>> Output: ' + $_.Exception.Message)
        $Result_Reg_Keys = $false
    }
}
Return $Result_Reg_Keys

}

<# End of File #>
