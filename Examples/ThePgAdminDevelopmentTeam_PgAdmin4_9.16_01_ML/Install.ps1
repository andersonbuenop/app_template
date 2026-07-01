######################################################################################
#### Template PS v.4.0                                                               #
#### Modification Date 10/03/2024                                                    #
######################################################################################
# Application Info (REQUIRED)                                                        #
######################################################################################
$APP_Company = "ThePgAdminDevelopmentTeam"
$APP_Name = "pgAdmin 4"
$APP_Version = "9.16"
$APP_System = "01"
$APP_Language = "ML"
$APP_InternalVersion = "01.00"

######################################################################################
# Deployment Info (REQUIRED)                                                         #
######################################################################################
#
# @ DETECTION METHOD
#      Type
#            File System
#                File: "HKLM\SOFTWARE\pgAdmin 4\"
#                Version: Version = 9.16
#                Date: 
#            Registry: 
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

Import-Module .\Modules\SDS_Custom_Module.psm1 -Force
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

$ExitCode = 0
FN_Update_LogFile -Message "Starting Install process"
FN_Update_LogFile -Message "Running pre-uninstall step"

# Fechar processos
# Nenhum processo informado.
Start-Sleep -Seconds 5

$UninstallerPath = "C:\Applics\PGAdmin\unins000.exe"
if (Test-Path -LiteralPath $UninstallerPath) {
    FN_Update_LogFile -Message "Running EXE uninstaller: $UninstallerPath"
    $UninstallExit = FN_Run_EXE_File -EXEFilePath $UninstallerPath -Arguments "/VERYSILENT /NORESTART" -Wait All
} else {
    FN_Update_LogFile -Message "EXE uninstaller not found; nothing to remove: $UninstallerPath"
    $UninstallExit = 0
}
Start-Sleep -Seconds 5

$EXE = "pgadmin4-9.16-x64.exe"
FN_Update_LogFile -Message "Installing $EXE"
$ExitCode = FN_Run_EXE_File -EXEFilePath "$($Util_Info.Path_Prog)\$EXE" -Arguments '/ALLUSERS /VERYSILENT /NORESTART /DIR="C:\Applics\PGAdmin" /LOG="C:\Sys_com\Logs\Pgadmin4916.log"' -Wait All
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

