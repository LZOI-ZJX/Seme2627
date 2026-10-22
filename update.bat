@echo off
setlocal EnableExtensions
cd /d "%~dp0"
title Update notes

where git >nul 2>&1
if errorlevel 1 (
  echo Git was not found. Install Git for Windows first.
  pause
  exit /b 1
)

echo.
echo Folder: %CD%
echo Remote: https://github.com/LZOI-ZJX/Seme2627
echo.
echo ===== Current changes =====
git status -sb
echo.
echo This uploads note changes that are not excluded by .gitignore.
echo HTML, secrets, cookies, and the microwave download scripts stay local.
echo.

set "GO="
set /p GO=Review files to upload? Type y: 
if /i not "%GO%"=="y" if /i not "%GO%"=="yes" goto :cancel

git add -A
if errorlevel 1 goto :fail

echo.
echo ===== Files to upload =====
git diff --cached --stat
echo.

git diff --cached --quiet
if not errorlevel 1 (
  echo No note changes to upload.
  goto :done
)

git diff --cached --name-only > "%TEMP%\seme2627-staged.txt"
findstr /i /r "\.env \.key \.pem cookie privatekey \.html$" "%TEMP%\seme2627-staged.txt" >nul
if not errorlevel 1 (
  echo Staged files include a secret or HTML. Stopped. Nothing was uploaded.
  git reset >nul
  goto :done
)

echo.
set "MSG="
set /p MSG=Commit message, or press Enter for "Update notes.": 
if not defined MSG set "MSG=Update notes."

echo.
set "PUSH="
set /p PUSH=Commit and push to GitHub? Type y: 
if /i not "%PUSH%"=="y" if /i not "%PUSH%"=="yes" (
  git reset >nul
  goto :cancel
)

set "COMMIT_MSG=%MSG%"
powershell -NoProfile -Command "$p = Join-Path (Get-Location) '.git\COMMIT_MSG_BAT.txt'; $enc = New-Object System.Text.UTF8Encoding $false; [System.IO.File]::WriteAllText($p, $env:COMMIT_MSG + [Environment]::NewLine, $enc)"
if errorlevel 1 goto :fail

git commit -F .git\COMMIT_MSG_BAT.txt
if errorlevel 1 goto :fail

echo.
echo ===== Sync and push =====
git pull --rebase origin main
if errorlevel 1 (
  echo Rebase failed. The local commit is kept. Fix the conflict, then run this again.
  goto :done
)

git push origin main
if errorlevel 1 (
  echo Push failed. The local commit is kept. Run this again after network or login is restored.
  goto :done
)

echo.
echo Pushed to main. GitHub Actions will render the site:
echo https://lzoi-zjx.github.io/Seme2627/
goto :done

:cancel
echo.
echo Cancelled. Nothing was uploaded.
goto :done

:fail
echo.
echo Failed. Nothing was uploaded.
goto :done

:done
echo.
pause
exit /b 0
