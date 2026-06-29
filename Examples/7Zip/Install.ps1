######################################################################################
#### Template PS v.4.0                                                               #
#### Modification Date 29/05/2026                                                    #
######################################################################################
# Application Info (REQUIRED)                                                        #
######################################################################################

$APP_Company         = "IgorPavlov"
$APP_Name            = "7 zip"
$APP_Version         = "26.01"
$APP_System          = "01"
$APP_Language        = "ML"
$APP_InternalVersion = "01.00"

######################################################################################
# Deployment Info (REQUIRED)                                                         #
######################################################################################
#
# @ DETECTION METHOD
#      Type
#            File System
#                File:  			"C:\Applics\7-zip\7z.exe"   
#                Version:  			26.01
#                Date:     			
#            Registry:				HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{23170F69-40C1-2702-2601-000001000000}
#            Windows Installer: 
#            Script: 
#
# @ USER EXPERIENCE
#      Installation behavior
#            Install for system: 
#            Install for user: 
#      Logon Requirement
#            Only when a user is logged on: 
#            Whether or not a user is logged on: 
#            Only when no user is logged on: 
#      Installation Program Visibility
#            Normal: 
#            Hidden: 
#
# @ DEPENDENCIES:
# 
# 
#
# @ COMMENTS:
# 
#
#
######################################################################################

##################################################################################################################
#                                                                                                                #
#                                          DO NOT MODIFY BELOW THIS LINE                                         #
#                                                                                                                #
##################################################################################################################

######################################################################################
# Initialize Modules and Variables													 # 
######################################################################################

Import-Module .\Modules\SDS_Custom_Module.psm1
$Global:App_Info = FN_Get_AppInformation
$Global:Util_Info = FN_Utility -Action Install
$Global:Computer_info = FN_ComputerInformation
$Global:DebugMode = $true
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
FN_Close_Process -ProcessName "7zFM"
FN_Close_Process -ProcessName "7z"

Start-Sleep -Seconds 30

#Procura versoes anteriores e remove
$Installed = Get-ChildItem HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall,HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall | Get-ItemProperty | Where-Object {$_.DisplayName -like "7-Zip*" -and $_.UninstallString -match "MsiExec"}
foreach ($app in $Installed) {
    FN_Update_LogFile -Message "Removing detected version: $($app.DisplayName)"

    $UninstallExit = FN_MSI_Installer -Action UnInstall -ProductCode $app.PSChildName

    FN_Update_LogFile -Message "Pre-uninstall ExitCode: $UninstallExit"
}

Start-Sleep -Seconds 30

# começa a instalação
#Definir na variavel $MSI o nome exato do app.msi que se encontra dentro da pasta PROG
$MSI = "7z2601-x64.msi"

FN_Update_LogFile -Message "Starting Install process"

#Comando para fazer a instalação, usei o parametro -Additional_Arguments, para adicionar o parametro de INSTALLDIR
$ExitCode = FN_MSI_Installer -Action Install -MSIFilePath "$($Util_Info.Path_Prog)\$MSI" -Additional_Arguments 'INSTALLDIR="C:\Applics\7-Zip"'

FN_Update_LogFile -Message "Install process finished"
#-------------------------
# Script END
##########################

##################################################################################################################
#                                                                                                                #
#                                          DO NOT MODIFY BELOW THIS LINE                                         #
#                                                                                                                #
##################################################################################################################

FN_Finish_LogFile -Final_ExitCode $ExitCode
