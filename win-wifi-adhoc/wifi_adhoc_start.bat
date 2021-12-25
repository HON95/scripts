@echo off
REM Windows 10 WiFi AdHoc network starting script by HON

echo Win10 WiFi AdHoc START
echo The hosted network is starting...
netsh wlan start hostednetwork
if errorlevel 0 echo Success!
if not errorlevel 0 echo Failed!
echo.
pause
