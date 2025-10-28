@echo off
echo ========================================
echo Simple Flutter Web Deploy
echo ========================================

echo.
echo Building Flutter web app...
flutter build web

if %errorlevel% neq 0 (
    echo Build failed! Exiting...
    pause
    exit /b 1
)

echo.
echo Adding build files to main branch...
git add build/web/
git commit -m "Deploy: Update web build - %date% %time%"

echo.
echo Pushing to GitHub...
git push origin main

echo.
echo ========================================
echo Deploy completed!
echo ========================================
echo.
echo If using GitHub Actions, your site will be updated automatically.
echo If using Netlify, your site will be updated automatically.
echo.
pause
