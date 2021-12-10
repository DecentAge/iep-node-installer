@ECHO OFF

SET INSTALL_DIR=${INSTALL_PATH}
SET INSTALL_JAVA_HOME=%INSTALL_DIR%\jre
SET UNINSTALL_JAVA_HOME=%USERPROFILE%\IEPUninstaller\jre

xcopy "%INSTALL_JAVA_HOME%" "%UNINSTALL_JAVA_HOME%" /q /s /e /k /y /i

"%UNINSTALL_JAVA_HOME%\bin\javaw.exe" -jar "%USERPROFILE%\IEPUninstaller\uninstaller.jar"

rmdir /S /Q "%INSTALL_DIR%"
rmdir /S /Q "%USERPROFILE%\IEPUninstaller"