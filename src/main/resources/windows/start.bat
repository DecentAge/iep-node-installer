@ECHO OFF
FOR %%A IN ("%~dp0.") DO SET INSTALL_DIR=%%~dpA
SET INSTALL_DIR=%INSTALL_DIR:~0,-1%
SET JAVA_HOME=%INSTALL_DIR%\jre
ECHO INSTALL_DIR=%INSTALL_DIR%
ECHO JAVA_HOME=%JAVA_HOME%

setlocal

cd %INSTALL_DIR%
SET IEP_NODE_OPTS=--module-path "%INSTALL_DIR%\javafx-sdk\lib" --add-modules javafx.controls,javafx.web --add-exports javafx.web/com.sun.javafx.webkit=ALL-UNNAMED -Dxin.runtime.mode=desktop -Duser.home=%USERPROFILE%
start bin\iep-node
endlocal