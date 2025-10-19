@echo off
set prefecs=; MD5:
FOR /F "delims=" %%i IN ('certutil -hashfile %1 MD5^|find /v "MD5"^|find /v "CertUtil"') DO set md5=%%i
set "md5=%md5: =%"
set payload=%prefecs%%md5%
REM echo %payload%>>%1 
SET filename=%1
echo %payload% > %TEMP%\temp.md5 & type %filename:/=\% >> %TEMP%\temp.md5 & move /y %TEMP%\temp.md5 %filename:/=\% >nul
