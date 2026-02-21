@echo off
powershell -Command "New-SelfSignedCertificate -Type CodeSigningCert -Subject 'CN=ExcellenceCoachingHub' -KeyUsage DigitalSignature -FriendlyName 'Excellence Coaching Hub Signer' -NotAfter (Get-Date).AddYears(1) | Export-PfxCertificate -FilePath 'ExcellenceHubCert.pfx' -Password (ConvertTo-SecureString 'Excellence123!' -AsPlainText -Force)"
