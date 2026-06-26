<#
Generate-AppStructure.ps1

Script para criar a estrutura completa de uma aplicação Intune.
Cria diretórios, gera Install.ps1, Uninstall.ps1 e copia módulos.

Uso: .\Generate-AppStructure.ps1
#>

function Read-Input {
    param($Prompt, $Default)
    $input = Read-Host "$Prompt [$Default]"
    if ([string]::IsNullOrWhiteSpace($input)) { return $Default }
    return $input
}

function Create-InstallScript {
    param($Path, $AppCompany, $AppName, $AppVersion, $AppSystem, $AppLanguage, $AppInternalVersion, 
          $DetectionPath, $DetectionVersion, $DetectionRegistry, $UXSystem, $UXUser, $UXLogon, $UXVisibility,
          $MSIFileName, $AdditionalArgs, $ProcCommands)
    
    $dateStr = Get-Date -Format "dd/MM/yyyy"
    $content = "######################################################################################`n"
    $content += "#### Template PS v.4.0                                                               #`n"
    $content += "#### Modification Date $dateStr                                    #`n"
    $content += "######################################################################################`n"
    $content += "# Application Info (REQUIRED)                                                        #`n"
    $content += "######################################################################################`n"
    $content += "`n"
    $content += "`$APP_Company         = `"$AppCompany`"`n"
    $content += "`$APP_Name            = `"$AppName`"`n"
    $content += "`$APP_Version         = `"$AppVersion`"`n"
    $content += "`$APP_System          = `"$AppSystem`"`n"
    $content += "`$APP_Language        = `"$AppLanguage`"`n"
    $content += "`$APP_InternalVersion = `"$AppInternalVersion`"`n"
    $content += "`n"
    $content += "######################################################################################`n"
    $content += "# Deployment Info (REQUIRED)                                                         #`n"
    $content += "######################################################################################`n"
    $content += "#`n"
    $content += "# @ DETECTION METHOD`n"
    $content += "#      Type`n"
    $content += "#            File System`n"
    $content += "#                File:  `"$DetectionPath`"`n"
    $content += "#                Version:  $DetectionVersion`n"
    $content += "#                Date:`n"
    $content += "#            Registry: $DetectionRegistry`n"
    $content += "#            Windows Installer:`n"
    $content += "#            Script:`n"
    $content += "#`n"
    $content += "# @ USER EXPERIENCE`n"
    $content += "#      Installation behavior`n"
    $content += "#            Install for system: $UXSystem`n"
    $content += "#            Install for user: $UXUser`n"
    $content += "#      Logon Requirement`n"
    $content += "#            $UXLogon`n"
    $content += "#      Installation Program Visibility`n"
    $content += "#            $UXVisibility`n"
    $content += "#`n"
    $content += "######################################################################################`n"
    $content += "`n"
    $content += "##################################################################################################################`n"
    $content += "#                                                                                                                #`n"
    $content += "#                                          DO NOT MODIFY BELOW THIS LINE                                         #`n"
    $content += "#                                                                                                                #`n"
    $content += "##################################################################################################################`n"
    $content += "`n"
    $content += "######################################################################################`n"
    $content += "# Initialize Modules and Variables`n"
    $content += "######################################################################################`n"
    $content += "`n"
    $content += "Import-Module .\Modules\SDS_Custom_Module.psm1`n"
    $content += "`$Global:App_Info = FN_Get_AppInformation`n"
    $content += "`$Global:Util_Info = FN_Utility -Action Install`n"
    $content += "`$Global:Computer_info = FN_ComputerInformation`n"
    $content += "`$Global:DebugMode = `$true`n"
    $content += "FN_Create_LogFile`n"
    $content += "`n"
    $content += "##################################################################################################################`n"
    $content += "#                                                                                                                #`n"
    $content += "#                                          DO NOT MODIFY ABOVE THIS LINE                                         #`n"
    $content += "#                                                                                                                #`n"
    $content += "##################################################################################################################`n"
    $content += "`n`n"
    $content += "##########################`n"
    $content += "# Script START (Code Here)`n"
    $content += "#-------------------------`n"
    $content += "`n"
    $content += "FN_Update_LogFile -Message `"Starting Install process`"`n"
    $content += "FN_Update_LogFile -Message `"Running pre-uninstall step (if installed)`"`n"
    $content += "`n"
    $content += "# Fechar processos`n"
    $content += $ProcCommands
    $content += "`n"
    $content += "Start-Sleep -Seconds 5`n"
    $content += "`n"
    $content += "# Procura versoes anteriores e remove`n"
    $content += "`$Installed = Get-ChildItem HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall,HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall | Get-ItemProperty | Where-Object {`$_.DisplayName -like `"$AppName*`" -and `$_.UninstallString -match `"MsiExec`"}`n"
    $content += "foreach (`$app in `$Installed) {`n"
    $content += "    FN_Update_LogFile -Message `"Removing detected version: `$(`$app.DisplayName)`"`n"
    $content += "    `$UninstallExit = FN_MSI_Installer -Action UnInstall -ProductCode `$app.PSChildName`n"
    $content += "    FN_Update_LogFile -Message `"Pre-uninstall ExitCode: `$UninstallExit`"`n"
    $content += "}`n"
    $content += "`n"
    $content += "Start-Sleep -Seconds 5`n"
    $content += "`n"
    $content += "# Começa a instalação`n"
    $content += "`$MSI = `"$MSIFileName`"`n"
    $content += "FN_Update_LogFile -Message `"Starting Install process`"`n"
    $content += "`n"
    $content += "`$ExitCode = FN_MSI_Installer -Action Install -MSIFilePath `"`$(`$Util_Info.Path_Prog)\`$MSI`" -Additional_Arguments '$AdditionalArgs'`n"
    $content += "`n"
    $content += "FN_Update_LogFile -Message `"Install process finished`"`n"
    $content += "#-------------------------`n"
    $content += "# Script END`n"
    $content += "##########################`n"
    $content += "`n"
    $content += "##################################################################################################################`n"
    $content += "#                                                                                                                #`n"
    $content += "#                                          DO NOT MODIFY BELOW THIS LINE                                         #`n"
    $content += "#                                                                                                                #`n"
    $content += "##################################################################################################################`n"
    $content += "`n"
    $content += "FN_Finish_LogFile -Final_ExitCode `$ExitCode`n"
    
    Set-Content -Path $Path -Value $content -Encoding UTF8
}

function Create-UninstallScript {
    param($Path, $AppName, $ProcCommands)
    
    $dateStr = Get-Date -Format "dd/MM/yyyy"
    $content = "######################################################################################`n"
    $content += "#### Uninstall.ps1 - $AppName                                                       #`n"
    $content += "#### Modification Date $dateStr                                    #`n"
    $content += "######################################################################################`n"
    $content += "`n"
    $content += "Import-Module .\Modules\SDS_Custom_Module.psm1`n"
    $content += "`$Global:App_Info = FN_Get_AppInformation`n"
    $content += "`$Global:Util_Info = FN_Utility -Action UnInstall`n"
    $content += "`$Global:Computer_info = FN_ComputerInformation`n"
    $content += "`$Global:DebugMode = `$true`n"
    $content += "FN_Create_LogFile`n"
    $content += "`n"
    $content += "FN_Update_LogFile -Message `"Starting Uninstall process`"`n"
    $content += "`n"
    $content += "# Fechar processos`n"
    $content += $ProcCommands
    $content += "`n"
    $content += "Start-Sleep -Seconds 5`n"
    $content += "`n"
    $content += "# Procura versoes para remover`n"
    $content += "`$Installed = Get-ChildItem HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall,HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall | Get-ItemProperty | Where-Object {`$_.DisplayName -like `"$AppName*`" -and `$_.UninstallString -match `"MsiExec`"}`n"
    $content += "foreach (`$app in `$Installed) {`n"
    $content += "    FN_Update_LogFile -Message `"Uninstalling: `$(`$app.DisplayName)`"`n"
    $content += "    `$ExitCode = FN_MSI_Installer -Action UnInstall -ProductCode `$app.PSChildName`n"
    $content += "    FN_Update_LogFile -Message `"Uninstall ExitCode: `$ExitCode`"`n"
    $content += "}`n"
    $content += "`n"
    $content += "FN_Update_LogFile -Message `"Uninstall process finished`"`n"
    $content += "FN_Finish_LogFile -Final_ExitCode `$ExitCode`n"
    
    Set-Content -Path $Path -Value $content -Encoding UTF8
}

Write-Host "`n=== APP STRUCTURE GENERATOR ===" -ForegroundColor Cyan

# 1. Coletar informações da aplicação
Write-Host "`n--- Application Info ---" -ForegroundColor Yellow
$APP_Company         = Read-Input 'Company' 'AnnpMD'
$APP_Name            = Read-Input 'Application Name' 'MyApp'
$APP_Version         = Read-Input 'Version (ex: 3.4.2)' '1.0.0'
$APP_System          = Read-Input 'System Code (ex: 01)' '01'
$APP_Language        = Read-Input 'Language (ex: ML, EN, PT)' 'ML'
$APP_InternalVersion = Read-Input 'Internal Version (ex: 01.00)' '01.00'

# 2. Informações de Detecção
Write-Host "`n--- Detection Info ---" -ForegroundColor Yellow
$DETECTION_FilePath = Read-Input "Detection exe path (ex: C:\Program Files\$APP_Name\$($APP_Name.ToLower()).exe)" "C:\Program Files\$APP_Name\$($APP_Name.ToLower()).exe"
$DETECTION_Version = Read-Input "Detection exe version (optional)" ""
$DETECTION_RegistryKey = Read-Input "Registry key (optional)" ""

# 3. User Experience
Write-Host "`n--- User Experience ---" -ForegroundColor Yellow
$UX_System = if ((Read-Input "Install for system? (y/n)" "y") -eq "y") { "x" } else { "" }
$UX_User = if ((Read-Input "Install for user? (y/n)" "n") -eq "y") { "x" } else { "" }
$UX_LogonReq = Read-Input "Logon requirement: OnlyWhenUser / WhetherOrNot / OnlyWhenNoUser" "Whether or not a user is logged on"
$UX_Visibility = Read-Input "Visibility: Normal / Hidden" "Hidden"

# 4. Processos a fechar
Write-Host "`n--- Processes to Close ---" -ForegroundColor Yellow
$procsInput = Read-Input "Processes to close (comma separated, ex: app1,app2)" $APP_Name.ToLower()
$processList = @()
if (-not [string]::IsNullOrWhiteSpace($procsInput)) {
    $processList = $procsInput -split '\s*,\s*'
}

# 5. Nome do MSI
Write-Host "`n--- MSI Info ---" -ForegroundColor Yellow
$MSI_FileName = Read-Input "MSI filename (ex: app_1.0.0_x64_win.msi)" "$($APP_Name.ToLower())_$($APP_Version)_x64_win.msi"

# 6. Argumentos adicionais
Write-Host "`n--- Additional Arguments ---" -ForegroundColor Yellow
$defaultInstallDir = "C:\Applics\$APP_Name"
$additionalArgs = Read-Input "Additional MSI arguments (ex: INSTALLDIR=`"$defaultInstallDir`")" "INSTALLDIR=`"$defaultInstallDir`""

# 7. Diretório de saída
Write-Host "`n--- Output Directory ---" -ForegroundColor Yellow
$workspaceName = "${APP_Company}_${APP_Name}_${APP_Version}_${APP_System}_${APP_Language}"
$baseDir = Read-Input "Output base directory" (Get-Location).Path
$appDir = Join-Path $baseDir $workspaceName

# Confirmar
Write-Host "`n--- RESUMO ---" -ForegroundColor Cyan
Write-Host "Company: $APP_Company"
Write-Host "Application: $APP_Name v$APP_Version"
Write-Host "Output: $appDir"
Write-Host "MSI: $MSI_FileName"
$procDisplay = if ($processList.Count -gt 0) { $processList -join ', ' } else { 'Nenhum' }
Write-Host "Processos: $procDisplay"

$confirm = Read-Input "`nProsseguir com a criação? (y/n)" "y"
if ($confirm -ne "y") { Write-Host "Cancelado."; exit }

# 8. Criar estrutura de diretórios
Write-Host "`nCriando estrutura..." -ForegroundColor Cyan

if (Test-Path $appDir) {
    Write-Host "AVISO: $appDir já existe!" -ForegroundColor Yellow
    $overwrite = Read-Input "Sobrescrever? (y/n)" "n"
    if ($overwrite -ne "y") { exit }
}

New-Item -ItemType Directory -Path $appDir -Force | Out-Null
New-Item -ItemType Directory -Path "$appDir\Modules" -Force | Out-Null
New-Item -ItemType Directory -Path "$appDir\Prog" -Force | Out-Null

Write-Host "✓ Diretórios criados" -ForegroundColor Green

# 9. Criar Install.ps1
$procCommands = ""
foreach ($proc in $processList) {
    if (-not [string]::IsNullOrWhiteSpace($proc)) {
        $procCommands += "FN_Close_Process -ProcessName `"$proc`"`n"
    }
}

$installContent = @"
######################################################################################
#### Template PS v.4.0                                                               #
#### Modification Date $(Get-Date -Format "dd/MM/yyyy")                                    #
######################################################################################
# Application Info (REQUIRED)                                                        #
######################################################################################

`$APP_Company         = "$APP_Company"
`$APP_Name            = "$APP_Name"
`$APP_Version         = "$APP_Version"
`$APP_System          = "$APP_System"
`$APP_Language        = "$APP_Language"
`$APP_InternalVersion = "$APP_InternalVersion"

######################################################################################
# Deployment Info (REQUIRED)                                                         #
######################################################################################
#
# @ DETECTION METHOD
#      Type
#            File System
#                File:  "$DETECTION_FilePath"
#                Version:  $DETECTION_Version
#                Date:
#            Registry: $DETECTION_RegistryKey
#            Windows Installer:
#            Script:
#
# @ USER EXPERIENCE
#      Installation behavior
#            Install for system: $UX_System
#            Install for user: $UX_User
#      Logon Requirement
#            $UX_LogonReq
#      Installation Program Visibility
#            $UX_Visibility
#
######################################################################################

##################################################################################################################
#                                                                                                                #
#                                          DO NOT MODIFY BELOW THIS LINE                                         #
#                                                                                                                #
##################################################################################################################

######################################################################################
# Initialize Modules and Variables
######################################################################################

Import-Module .\Modules\SDS_Custom_Module.psm1
`$Global:App_Info = FN_Get_AppInformation
`$Global:Util_Info = FN_Utility -Action Install
`$Global:Computer_info = FN_ComputerInformation
`$Global:DebugMode = `$true
FN_Create_LogFile

##################################################################################################################
#                                                                                                                #
#                                          DO NOT MODIFY ABOVE THIS LINE                                         #
#                                                                                                                #
##################################################################################################################


##########################
# Script START (Code Here)
#-------------------------

FN_Update_LogFile -Message "Starting Install process"
FN_Update_LogFile -Message "Running pre-uninstall step (if installed)"

# Fechar processos
$procCommands
Start-Sleep -Seconds 5

# Procura versoes anteriores e remove
`$Installed = Get-ChildItem HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall,HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall | Get-ItemProperty | Where-Object {`$_.DisplayName -like "$APP_Name*" -and `$_.UninstallString -match "MsiExec"}
foreach (`$app in `$Installed) {
    FN_Update_LogFile -Message "Removing detected version: `$(`$app.DisplayName)"
    `$UninstallExit = FN_MSI_Installer -Action UnInstall -ProductCode `$app.PSChildName
    FN_Update_LogFile -Message "Pre-uninstall ExitCode: `$UninstallExit"
}

Start-Sleep -Seconds 5

# Começa a instalação
`$MSI = "$MSI_FileName"
FN_Update_LogFile -Message "Starting Install process"

`$ExitCode = FN_MSI_Installer -Action Install -MSIFilePath "`$(`$Util_Info.Path_Prog)\`$MSI" -Additional_Arguments '$additionalArgs'

FN_Update_LogFile -Message "Install process finished"
#-------------------------
# Script END
##########################

##################################################################################################################
#                                                                                                                #
#                                          DO NOT MODIFY BELOW THIS LINE                                         #
#                                                                                                                #
##################################################################################################################

FN_Finish_LogFile -Final_ExitCode `$ExitCode
"@

Set-Content -Path "$appDir\Install.ps1" -Value $installContent -Encoding UTF8
Write-Host "✓ Install.ps1 criado" -ForegroundColor Green

# 10. Criar Uninstall.ps1
$uninstallContent = @"
######################################################################################
#### Uninstall.ps1 - $APP_Name                                                       #
#### Modification Date $(Get-Date -Format "dd/MM/yyyy")                                    #
######################################################################################

Import-Module .\Modules\SDS_Custom_Module.psm1
`$Global:App_Info = FN_Get_AppInformation
`$Global:Util_Info = FN_Utility -Action UnInstall
`$Global:Computer_info = FN_ComputerInformation
`$Global:DebugMode = `$true
FN_Create_LogFile

FN_Update_LogFile -Message "Starting Uninstall process"

# Fechar processos
$procCommands
Start-Sleep -Seconds 5

# Procura versoes para remover
`$Installed = Get-ChildItem HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall,HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall | Get-ItemProperty | Where-Object {`$_.DisplayName -like "$APP_Name*" -and `$_.UninstallString -match "MsiExec"}
foreach (`$app in `$Installed) {
    FN_Update_LogFile -Message "Uninstalling: `$(`$app.DisplayName)"
    `$ExitCode = FN_MSI_Installer -Action UnInstall -ProductCode `$app.PSChildName
    FN_Update_LogFile -Message "Uninstall ExitCode: `$ExitCode"
}

FN_Update_LogFile -Message "Uninstall process finished"
FN_Finish_LogFile -Final_ExitCode `$ExitCode
"@

Set-Content -Path "$appDir\Uninstall.ps1" -Value $uninstallContent -Encoding UTF8
Write-Host "✓ Uninstall.ps1 criado" -ForegroundColor Green

# 11. Copiar módulo (se existir no diretório atual)
$currentModulePath = ".\Modules\SDS_Custom_Module.psm1"
if (Test-Path $currentModulePath) {
    Copy-Item -Path $currentModulePath -Destination "$appDir\Modules\SDS_Custom_Module.psm1" -Force
    Write-Host "✓ Módulo copiado" -ForegroundColor Green
} else {
    Write-Host "⚠ Módulo não encontrado em $currentModulePath (copie manualmente)" -ForegroundColor Yellow
}

Write-Host "`n✓ ESTRUTURA CRIADA COM SUCESSO!" -ForegroundColor Green
Write-Host "Localização: $appDir" -ForegroundColor Cyan
Write-Host "`nPróximos passos:" -ForegroundColor Yellow
Write-Host "1. Copie o arquivo .msi para a pasta: $appDir\Prog"
Write-Host "2. Revise os arquivos Install.ps1 e Uninstall.ps1"
Write-Host "3. Teste o script"
