@echo off
REM Windows 10 WiFi AdHoc network stopping script by HON

echo Win10 WiFi AdHoc STOP
echo The hosted network is stopping...
netsh wlan stop hostednetwork
REM netsh wlan set hostednetwork mode=disallow
if errorlevel 0 echo Success!
if not errorlevel 0 echo Failed!
echo.
pause
