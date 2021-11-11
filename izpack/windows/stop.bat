@ECHO OFF
WMIC Process Where "Commandline Like '%%xin.Xin%%'" get Commandline | findstr /i /c:"iep-node.jar" > NUL && (
   echo Stopping IEP Node...
   WMIC Process Where "Commandline Like '%%xin.Xin%%'" Call Terminate 
) || (
   echo IEP Node is currently not running
)