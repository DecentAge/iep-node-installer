@ECHO OFF
FOR %%A IN ("%~dp0.") DO SET INSTALL_DIR=%%~dpA
SET INSTALL_DIR=%INSTALL_DIR:~0,-1%
SET WORK_DIR=%USERPROFILE%\.iep
SET JAVA_HOME=%INSTALL_DIR%\jre

ECHO INSTALL_DIR=%INSTALL_DIR%
ECHO JAVA_HOME=%JAVA_HOME%

WMIC Process Where "Commandline Like '%%xin.Xin%%'" get Commandline > NUL | findstr /i /c:"iep-node.jar" > NUL && (
	echo IEP Node is already runnig
) || (
	echo Starting IEP Node...
	setlocal
	SET IEP_NODE_OPTS=--module-path "%INSTALL_DIR%\javafx-sdk\lib" --add-modules javafx.controls,javafx.web --add-exports javafx.web/com.sun.javafx.webkit=ALL-UNNAMED -Dxin.runtime.mode=desktop -Dxin.workDir="%WORK_DIR%" -Duser.home="%USERPROFILE%"
	cd %INSTALL_DIR%
	start bin\iep-node
	endlocal
)