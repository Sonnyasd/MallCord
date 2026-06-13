@echo off
setlocal EnableDelayedExpansion
chcp 65001 >nul 2>&1

:: ================================================
:: Private MallCord Installer
:: ================================================

set "REPO_URL=https://github.com/Sonnyasd/MallCord"
set "INSTALL_DIR=%USERPROFILE%\PrivateMallCord"

:: ANSI Colors
set "ESC=["
set "RED=%ESC%91m"
set "GREEN=%ESC%92m"
set "YELLOW=%ESC%93m"
set "BLUE=%ESC%94m"
set "CYAN=%ESC%96m"
set "RESET=%ESC%0m"

:print_header
cls
echo.
echo %CYAN%╔══════════════════════════════════════════════════════════════╗%RESET%
echo %CYAN%║%RESET%                 %GREEN%Private MallCord Setup%RESET%                 %CYAN%║%RESET%
echo %CYAN%╚══════════════════════════════════════════════════════════════╝%RESET%
echo.
goto :eof

:check_admin
net session >nul 2>&1
if !errorlevel! equ 0 (
    echo %YELLOW%WARNING:%RESET% You are running as Administrator. This may break Discord.
    choice /C YN /M "   Continue anyway?"
    if !errorlevel! equ 2 exit /b 1
)
goto :eof

:close_discord
echo %BLUE%Closing Discord processes...%RESET%
taskkill /F /IM Discord.exe >nul 2>&1
taskkill /F /IM DiscordPTB.exe >nul 2>&1
taskkill /F /IM DiscordCanary.exe >nul 2>&1
timeout /t 2 /nobreak >nul
goto :eof

call :print_header

echo   %CYAN%What would you like to do?%RESET%
echo.
echo   %GREEN%[1]%RESET% Install / Update
echo   %GREEN%[2]%RESET% Check for Updates
echo   %GREEN%[3]%RESET% Uninstall
echo   %GREEN%[4]%RESET% Exit
echo.
choice /C 1234 /M "   Choose an option"

set "CHOICE=!errorlevel!"

if !CHOICE! equ 4 goto :end
if !CHOICE! equ 3 goto :uninstall
if !CHOICE! equ 2 goto :check_update

:: ===================== INSTALL / UPDATE =====================
call :check_admin
call :close_discord

where git >nul 2>&1
if %errorlevel% neq 0 (
    echo %RED%ERROR:%RESET% Git not found. Install from: https://git-scm.com/download/win
    pause
    goto :end
)

where node >nul 2>&1
if %errorlevel% neq 0 (
    echo %RED%ERROR:%RESET% Node.js not found. Install LTS from https://nodejs.org
    pause
    goto :end
)

node -e "if(parseInt(process.version.slice(1))<18)process.exit(1)" >nul 2>&1
if %errorlevel% neq 0 (
    echo %RED%ERROR:%RESET% Node.js v18 or higher required.
    pause
    goto :end
)

where pnpm >nul 2>&1
if %errorlevel% neq 0 (
    echo %YELLOW%pnpm not found. Installing...%RESET%
    call npm install -g pnpm
)

echo %BLUE%Cloning / Updating repository...%RESET%
if exist "%INSTALL_DIR%\.git" (
    cd /d "%INSTALL_DIR%"
    git fetch origin main
    git reset --hard origin/main
) else (
    if exist "%INSTALL_DIR%" rmdir /s /q "%INSTALL_DIR%"
    git clone "%REPO_URL%" "%INSTALL_DIR%"
    if %errorlevel% neq 0 (
        echo %RED%ERROR:%RESET% Clone failed.
        pause
        goto :end
    )
    cd /d "%INSTALL_DIR%"
)

echo %BLUE%Installing dependencies...%RESET%
call pnpm install --no-frozen-lockfile
if %errorlevel% neq 0 (
    echo %RED%ERROR:%RESET% Failed to install dependencies.
    pause
    goto :end
)

echo %BLUE%Building Private MallCord...%RESET%
call pnpm build
if %errorlevel% neq 0 (
    echo %RED%ERROR:%RESET% Build failed.
    pause
    goto :end
)

echo %BLUE%Injecting into Discord...%RESET%
call node "%INSTALL_DIR%\scripts\runInstaller.mjs" -- --install

echo.
echo %GREEN%========================================%RESET%
echo %GREEN%   Private MallCord installed successfully!%RESET%
echo %GREEN%   Start Discord to load it.%RESET%
echo %GREEN%========================================%RESET%
pause
goto :end

:: ===================== CHECK FOR UPDATES =====================
:check_update
if not exist "%INSTALL_DIR%\.git" (
    echo %RED%Private MallCord is not installed yet.%RESET%
    pause
    goto :end
)
cd /d "%INSTALL_DIR%"
echo %BLUE%Checking for updates...%RESET%
git fetch origin main
git log HEAD..origin/main --oneline
echo.
choice /C YN /M "   Update now?"
if !errorlevel! equ 1 (
    call :close_discord
    git reset --hard origin/main
    call pnpm install --no-frozen-lockfile
    call pnpm build
    call node "%INSTALL_DIR%\scripts\runInstaller.mjs" -- --install
    echo %GREEN%Update completed successfully!%RESET%
)
pause
goto :end

:: ===================== UNINSTALL =====================
:uninstall
if not exist "%INSTALL_DIR%" (
    echo %RED%Private MallCord not found.%RESET%
    pause
    goto :end
)
call :close_discord
cd /d "%INSTALL_DIR%"
echo %BLUE%Removing from Discord...%RESET%
call node "%INSTALL_DIR%\scripts\runInstaller.mjs" -- --uninstall

echo.
choice /C YN /M "   Also delete the PrivateMallCord folder?"
if !errorlevel! equ 1 (
    cd /d "%USERPROFILE%"
    rmdir /s /q "%INSTALL_DIR%"
    echo %GREEN%Folder deleted.%RESET%
)
echo %GREEN%Private MallCord uninstalled. Restart Discord.%RESET%
pause
goto :end

:end
endlocal
