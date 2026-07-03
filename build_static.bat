@echo off

setlocal EnableDelayedExpansion

set "OPENSSL_REF=openssl-3.6.2"
set "OPENSSL_REMOTE=https://github.com/openssl/openssl.git"
set "OPENSSL_SRC=openssl"

set "VENDOR_WINDOWS_ARCH=%VSCMD_ARG_TGT_ARCH%"
if not defined VENDOR_WINDOWS_ARCH set "VENDOR_WINDOWS_ARCH=%PROCESSOR_ARCHITECTURE%"
if /I "%VENDOR_WINDOWS_ARCH%"=="AMD64" set "VENDOR_WINDOWS_ARCH=x64"
if /I "%VENDOR_WINDOWS_ARCH%"=="ARM64" set "VENDOR_WINDOWS_ARCH=arm64"
if /I "%VENDOR_WINDOWS_ARCH%"=="X86" set "VENDOR_WINDOWS_ARCH=x64"

set "OPENSSL_TARGET=VC-WIN64A"
if /I "%VENDOR_WINDOWS_ARCH%"=="arm64" set "OPENSSL_TARGET=VC-WIN64-ARM"
set "OUTPUT_DIR=windows_%VENDOR_WINDOWS_ARCH%"

call :ensure_tool perl || exit /b 1
call :ensure_tool nmake || exit /b 1

if not exist "%OPENSSL_SRC%\.git" (
    git clone --depth=1 --branch "%OPENSSL_REF%" "%OPENSSL_REMOTE%" "%OPENSSL_SRC%" || exit /b 1
) else (
    git -C "%OPENSSL_SRC%" fetch --depth=1 origin "%OPENSSL_REF%" || exit /b 1
    git -C "%OPENSSL_SRC%" checkout --detach FETCH_HEAD || exit /b 1
)

if not exist "%OUTPUT_DIR%" mkdir "%OUTPUT_DIR%"

call :reset_checkout || exit /b 1
pushd "%OPENSSL_SRC%" || exit /b 1
perl Configure %OPENSSL_TARGET% no-tests no-shared || exit /b 1
nmake /nologo || exit /b 1
copy /y "libssl.lib" "..\%OUTPUT_DIR%\libssl_static.lib" >nul || exit /b 1
copy /y "libcrypto.lib" "..\%OUTPUT_DIR%\libcrypto_static.lib" >nul || exit /b 1
popd || exit /b 1

echo Build completed successfully!
exit /b 0

:reset_checkout
git -C "%OPENSSL_SRC%" reset --hard HEAD >nul || exit /b 1
git -C "%OPENSSL_SRC%" clean -fdx >nul || exit /b 1
goto :eof

:ensure_tool
where %~1 >nul 2>nul
if errorlevel 1 (
    echo ERROR: missing required tool: %~1
    exit /b 1
)
goto :eof
