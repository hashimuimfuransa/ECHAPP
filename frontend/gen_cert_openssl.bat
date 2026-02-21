@echo off
set "CERT_NAME=ExcellenceHubCert"
set "PASSWORD=Excellence123!"

echo Generating private key and self-signed certificate...
openssl req -x509 -newkey rsa:2048 -keyout "%CERT_NAME%.key" -out "%CERT_NAME%.crt" -days 365 -nodes -subj "/CN=ExcellenceCoachingHub"

echo Combining into PFX file...
openssl pkcs12 -export -out "%CERT_NAME%.pfx" -inkey "%CERT_NAME%.key" -in "%CERT_NAME%.crt" -passout "pass:%PASSWORD%"

echo Cleaning up temporary files...
del "%CERT_NAME%.key"
del "%CERT_NAME%.crt"

echo.
echo ========================================================
echo SUCCESS: Certificate generated at: %CERT_NAME%.pfx
echo Password: %PASSWORD%
echo ========================================================
