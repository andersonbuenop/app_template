######################################################################################
#### Template PS v.4.0                                                               #
#### Modification Date 10/03/2024                                                    #
######################################################################################
# Application Info (REQUIRED)                                                        #
######################################################################################

$APP_Company         = "Company or Manufacturer"
$APP_Name            = "Aplication Name"
$APP_Version         = "1.1.1.1"
$APP_System          = "0X"
$APP_Language        = "ML"
$APP_InternalVersion = "01.00"

######################################################################################
# Deployment Info (REQUIRED)                                                         #
######################################################################################
#
# @ DETECTION METHOD
#      Type
#            File System
#                File: 
#                Version: 
#                Date: 
#            Registry: 
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
FN_Create_LogFile

##################################################################################################################
#                                                                                                                #
#                                          DO NOT MODIFY ABOVE THIS LINE                                         #
#                                                                                                                #
##################################################################################################################


##########################
# Script START (Code Here)
#-------------------------


if ($(FN_Message_To_User -EN_Text "Text in English" -ES_Text "Texto en Español") -eq 'Ok') {
$ExitCode = FN_Run_EXE_File -EXEFilePath C:\windows\system32\cmd.exe -Wait All
}



#-------------------------
# Script END
##########################

##################################################################################################################
#                                                                                                                #
#                                          DO NOT MODIFY BELOW THIS LINE                                         #
#                                                                                                                #
##################################################################################################################

FN_Finish_LogFile -Final_ExitCode $ExitCode
