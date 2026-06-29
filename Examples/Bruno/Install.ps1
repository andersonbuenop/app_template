######################################################################################
#### Template PS v.4.0                                                               #
#### Modification Date 29/05/2026                                                    #
######################################################################################
# Application Info (REQUIRED)                                                        #
######################################################################################

$APP_Company         = "AnnpMD"
$APP_Name            = "Bruno"
$APP_Version         = "3.4.2"
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
#                File:  			"C:\Program Files\Bruno\bruno.exe"   
#                Version:  			3.4.2.0
#                Date:     			
#            Registry:				HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{971920F7-151F-4867-8BAF-170E4B083CF8}
#            Windows Installer: 
#            Script: 
#
# @ USER EXPERIENCE
#      Installation behavior
#            Install for system: x
#            Install for user: 
#      Logon Requirement
#            Only when a user is logged on: 
#            Whether or not a user is logged on: x
#            Only when no user is logged on: 
#      Installation Program Visibility
#            Normal: 
#            Hidden: x
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
FN_Close_Process -ProcessName "bruno"

Start-Sleep -Seconds 30

#Procura versoes anteriores e remove
$Installed = Get-ChildItem HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall,HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall | Get-ItemProperty | Where-Object {$_.DisplayName -like "bruno*" -and $_.UninstallString -match "MsiExec"}
foreach ($app in $Installed) {
    FN_Update_LogFile -Message "Removing detected version: $($app.DisplayName)"

    $UninstallExit = FN_MSI_Installer -Action UnInstall -ProductCode $app.PSChildName

    FN_Update_LogFile -Message "Pre-uninstall ExitCode: $UninstallExit"
}

Start-Sleep -Seconds 30

# começa a instalação
#Definir na variavel $MSI o nome exato do app.msi que se encontra dentro da pasta PROG
$MSI = "bruno_3.4.2_x64_win.msi"

FN_Update_LogFile -Message "Starting Install process"

#Comando para fazer a instalação, usei o parametro -Additional_Arguments, para adicionar o parametro de INSTALLDIR
$ExitCode = FN_MSI_Installer -Action Install -MSIFilePath "$($Util_Info.Path_Prog)\$MSI" -Additional_Arguments 'INSTALLDIR="C:\Applics\Bruno"'

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
