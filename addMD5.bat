@echo off
setlocal enabledelayedexpansion

set "filename=%~1"

if "%filename%"=="" (
    echo Error: No filename specified
    echo Usage: %~nx0 "filename"
    pause
    exit /b 1
)

if not exist "%filename%" (
    echo Error: File not found - "%filename%"
    echo Usage: %~nx0 "filename"
    pause
    exit /b 1
)

set "prefecs=; MD5:"
set "md5="

for /f "tokens=*" %%i in ('certutil -hashfile "%filename%" MD5 2^>nul ^| findstr /r /c:"^[0-9a-fA-F][0-9a-fA-F]*$"') do (
    if not defined md5 (
        set "md5=%%i"
        goto :md5_found
    )
)
:md5_found

if not defined md5 (
    for /f "skip=1 tokens=*" %%i in ('certutil -hashfile "%filename%" MD5 2^>nul') do (
        if not defined md5 (
            set "line=%%i"
            set "line=!line: =!"
            if "!line!" neq "" (
                set "md5=!line!"
            )
        )
    )
)

if not defined md5 (
    echo Error: Cannot calculate MD5 hash
    echo Debug: certutil output:
    certutil -hashfile "%filename%" MD5
    pause
    exit /b 1
)

set "payload=%prefecs%!md5!"

set "tempfile=%TEMP%\md5_temp_%RANDOM%.tmp"

(
    echo !payload!
    type "%filename%"
) > "!tempfile!" 2>nul

if errorlevel 1 (
    echo Error: Cannot create temporary file
    if exist "!tempfile!" del /f /q "!tempfile!" >nul 2>&1
    pause
    exit /b 1
)

move /y "!tempfile!" "%filename%" >nul 2>&1

if errorlevel 1 (
    echo Error: Cannot update file
    if exist "!tempfile!" del /f /q "!tempfile!" >nul 2>&1
    pause
    exit /b 1
)

echo Success: MD5 hash added to beginning of file
echo File: "%filename%"
echo MD5: !md5!

endlocal
exit /b 0
