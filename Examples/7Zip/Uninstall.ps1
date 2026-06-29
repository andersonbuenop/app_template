######################################################################################
#### Template PS v.4.0                                                               #
#### Modification Date 10/03/2024                                                    #
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
$Global:Util_Info = FN_Utility -Action UnInstall
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

# Define custom install path
$AppInstallPath = "C:\Applics\7-Zip"

FN_Update_LogFile -Message "Starting Uninstall process"

# Close processes
FN_Close_Process -ProcessName "7zFM"
FN_Close_Process -ProcessName "7z"

Start-Sleep -Seconds 30

$Installed = Get-ChildItem HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall,HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall | Get-ItemProperty | Where-Object {$_.DisplayName -like "7-Zip*" -and $_.UninstallString -match "MsiExec"}
foreach ($app in $Installed) {
    FN_Update_LogFile -Message "Removing detected version: $($app.DisplayName)"

    $UninstallExit = FN_MSI_Installer -Action UnInstall -ProductCode $app.PSChildName

    # Remove leftover files
    #FN_Remove_Folder -FolderPath $AppInstallPath

    FN_Update_LogFile -Message "Uninstall ExitCode: $UninstallExit"
}


FN_Update_LogFile -Message "Uninstall process finished"


#-------------------------
# Script END
##########################

##################################################################################################################
#                                                                                                                #
#                                          DO NOT MODIFY BELOW THIS LINE                                         #
#                                                                                                                #
##################################################################################################################

FN_Finish_LogFile -Final_ExitCode $ExitCode
