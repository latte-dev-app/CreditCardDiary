@echo off
echo ========================================
echo Flutter Web App Deploy to GitHub Pages
echo ========================================

echo.
echo 1. Building Flutter web app...
flutter build web

if %errorlevel% neq 0 (
    echo Build failed! Exiting...
    pause
    exit /b 1
)

echo.
echo 2. Switching to gh-pages branch...
git checkout gh-pages

if %errorlevel% neq 0 (
    echo Failed to switch to gh-pages branch! Exiting...
    pause
    exit /b 1
)

echo.
echo 3. Copying build files to root...
Copy-Item -Recurse -Force build\web\* .

echo.
echo 4. Adding and committing changes...
git add .
git commit -m "Deploy: Update web build - %date% %time%"

echo.
echo 5. Pushing to GitHub Pages...
git push origin gh-pages

if %errorlevel% neq 0 (
    echo Push failed! Exiting...
    pause
    exit /b 1
)

echo.
echo ========================================
echo Deploy completed successfully!
echo ========================================
echo.
echo Your app will be available at:
echo https://latte-dev-app.github.io/CreditCardDiary
echo.
echo (It may take a few minutes to update)
echo.
pause
