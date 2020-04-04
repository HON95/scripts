@echo off
REM Windows 10 WiFi AdHoc network setup script by HON

echo Win10 WiFi AdHoc SETUP
set /p ssid=Enter SSID: 
set /p pass=Enter password: 
echo The hosted network is being configured...
netsh wlan set hostednetwork mode=allow ssid=%ssid% key=%pass%
REM does not return !0 if fail
if errorlevel 0 echo Success! Configured with SSID "%ssid%" and password "%pass%".
if not errorlevel 0 echo Failed!
echo.
pause
