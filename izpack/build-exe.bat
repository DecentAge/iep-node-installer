@echo off
FOR %%A IN ("%~dp0.") DO SET INSTALLER_DIR=%%~dpA
SET INSTALLER_DIR=%INSTALLER_DIR:~0,-1%
echo %INSTALLER_DIR%

setlocal
cd %INSTALLER_DIR%\build\izpack-utils\utils\wrappers\izpack2exe

python izpack2exe.py ^
--file %INSTALLER_DIR%\build\distributions\iep-node-installer.jar ^
--output %INSTALLER_DIR%\build\distributions\xin.exe ^
--with-7z=7za ^
--no-upx ^
--name xin

endlocal