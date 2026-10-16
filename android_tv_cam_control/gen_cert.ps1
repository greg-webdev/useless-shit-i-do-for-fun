Add-Type -AssemblyName System.Security
$rsa = [System.Security.Cryptography.RSA]::Create(2048)
$req = New-Object System.Security.Cryptography.X509Certificates.CertificateRequest(
    "CN=AndroidTV, O=Antigravity, OU=RemoteController",
    $rsa,
    [System.Security.Cryptography.HashAlgorithmName]::SHA256,
    [System.Security.Cryptography.RSASignaturePadding]::Pkcs1
)

$builder = New-Object System.Security.Cryptography.X509Certificates.SubjectAlternativeNameBuilder
$builder.AddDnsName("localhost")
$builder.AddDnsName("android-tv.local")
$builder.AddIpAddress([System.Net.IPAddress]::Parse("127.0.0.1"))
$builder.AddIpAddress([System.Net.IPAddress]::Parse("192.168.50.57"))
$req.CertificateExtensions.Add($builder.Build())

$cert = $req.CreateSelfSigned([DateTimeOffset]::UtcNow.AddDays(-1), [DateTimeOffset]::UtcNow.AddYears(10))

# Export to PFX then read back to get PKCS8 or export CNG key
$pfxBytes = $cert.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Pfx, "tempPass")
$certWithKey = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($pfxBytes, "tempPass", [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::Exportable)
$cngKey = [System.Security.Cryptography.X509Certificates.RSACertificateExtensions]::GetRSAPrivateKey($certWithKey).Key
$privKeyBytes = $cngKey.Export([System.Security.Cryptography.CngKeyBlobFormat]::Pkcs8PrivateBlob)

$privKeyBase64 = [Convert]::ToBase64String($privKeyBytes, [Base64FormattingOptions]::InsertLineBreaks)
$privKeyPem = "-----BEGIN PRIVATE KEY-----`n" + $privKeyBase64 + "`n-----END PRIVATE KEY-----"

$certBytes = $cert.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Cert)
$certBase64 = [Convert]::ToBase64String($certBytes, [Base64FormattingOptions]::InsertLineBreaks)
$certPem = "-----BEGIN CERTIFICATE-----`n" + $certBase64 + "`n-----END CERTIFICATE-----"

$dartContent = @"
// Auto-generated self-signed SSL certificate for HTTPS on port 82 / 8443
class SslCerts {
  static const String certificatePem = '''$certPem''';

  static const String privateKeyPem = '''$privKeyPem''';
}
"@

Set-Content -Path "lib\services\ssl_certs.dart" -Value $dartContent
Write-Host "Wrote lib\services\ssl_certs.dart successfully"
