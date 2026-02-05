@echo off
echo Finding your machine's IP address...
echo.
echo Your IPv4 addresses:
ipconfig | findstr /R "IPv4"
echo.
echo Use the address that corresponds to your WiFi/Ethernet connection
echo (Usually starts with 192.168.x.x or 10.x.x.x)
pause