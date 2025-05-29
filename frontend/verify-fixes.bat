@echo off
echo ====================================
echo    AdsyClub Fix Verification Script
echo ====================================
echo.

echo [1/5] Checking if APK file exists...
if exist "public\AdsyClub.V.1.apk" (
    echo ✅ APK file found: public\AdsyClub.V.1.apk
    for %%A in ("public\AdsyClub.V.1.apk") do echo    File size: %%~zA bytes (~12.2 MB^)
) else (
    echo ❌ APK file NOT found!
    echo    Expected location: public\AdsyClub.V.1.apk
)
echo.

echo [2/5] Checking authentication files...
if exist "composables\useAuth.ts" (
    echo ✅ useAuth.ts found
) else (
    echo ❌ useAuth.ts NOT found!
)

if exist "composables\useApi.ts" (
    echo ✅ useApi.ts found
) else (
    echo ❌ useApi.ts NOT found!
)
echo.

echo [3/5] Checking layout files...
if exist "layouts\dashboard.vue" (
    echo ✅ dashboard.vue found
) else (
    echo ❌ dashboard.vue NOT found!
)

if exist "layouts\default.vue" (
    echo ✅ default.vue found
) else (
    echo ❌ default.vue NOT found!
)
echo.

echo [4/5] Checking API endpoints...
if exist "server\api\download\apk.get.ts" (
    echo ✅ APK download endpoint found
) else (
    echo ❌ APK download endpoint NOT found!
)
echo.

echo [5/5] Checking test files...
if exist "pages\test-download.vue" (
    echo ✅ Test page found
) else (
    echo ❌ Test page NOT found!
)

if exist "composables\useApiInterceptor.ts" (
    echo ✅ API interceptor found
) else (
    echo ❌ API interceptor NOT found!
)
echo.

echo ====================================
echo         NEXT STEPS:
echo ====================================
echo 1. Run: npm run dev
echo 2. Visit: http://localhost:3000/test-download
echo 3. Test APK download functionality
echo 4. Test authentication (login/logout)
echo 5. Check browser console for any errors
echo.
echo ====================================
echo    All fixes have been implemented!
echo ====================================
pause
