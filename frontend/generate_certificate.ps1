# Set certificate parameters
$Subject = "CN=ExcellenceCoachingHub"
$CertPath = "ExcellenceHubCert.pfx"
$Password = ConvertTo-SecureString "Excellence123!" -AsPlainText -Force

Write-Host "Generating self-signed certificate for MSIX signing..." -ForegroundColor Cyan

# Create the certificate
$cert = New-SelfSignedCertificate -Type CodeSigningCert -Subject $Subject -KeyUsage DigitalSignature -FriendlyName "Excellence Coaching Hub Signer" -NotAfter (Get-Date).AddYears(1)

# Export to PFX
Export-PfxCertificate -Cert $cert -FilePath $CertPath -Password $Password

Write-Host "--------------------------------------------------------" -ForegroundColor Green
Write-Host "SUCCESS: Certificate generated at: $CertPath" -ForegroundColor Green
Write-Host "Password: Excellence123!" -ForegroundColor Yellow
Write-Host "--------------------------------------------------------" -ForegroundColor Green
Write-Host "IMPORTANT: To trust this certificate on this machine:" -ForegroundColor White
Write-Host "1. Double-click $CertPath" -ForegroundColor White
Write-Host "2. Select 'Local Machine' -> Next" -ForegroundColor White
Write-Host "3. Enter password: Excellence123!" -ForegroundColor White
Write-Host "4. Select 'Place all certificates in the following store'" -ForegroundColor White
Write-Host "5. Click 'Browse' and select 'Trusted Root Certification Authorities'" -ForegroundColor White
Write-Host "6. Complete the wizard." -ForegroundColor White
