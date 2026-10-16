import datetime
import ipaddress
import os
from cryptography import x509
from cryptography.x509.oid import NameOID
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.asymmetric import rsa
from cryptography.hazmat.primitives import serialization

# Generate 2048-bit RSA private key
key = rsa.generate_private_key(
    public_exponent=65537,
    key_size=2048,
)

# Build certificate subject
subject = issuer = x509.Name([
    x509.NameAttribute(NameOID.COMMON_NAME, "DroidMonitor"),
    x509.NameAttribute(NameOID.ORGANIZATION_NAME, "Antigravity"),
    x509.NameAttribute(NameOID.ORGANIZATIONAL_UNIT_NAME, "TelemetryServer"),
])

# Add SANs
alt_names = [
    x509.DNSName("localhost"),
    x509.DNSName("droid-monitor.local"),
    x509.DNSName("android.local"),
    x509.IPAddress(ipaddress.IPv4Address("127.0.0.1")),
    x509.IPAddress(ipaddress.IPv4Address("0.0.0.0")),
]

# Generate self-signed certificate valid for 10 years
now = datetime.datetime.now(datetime.timezone.utc)
cert = (
    x509.CertificateBuilder()
    .subject_name(subject)
    .issuer_name(issuer)
    .public_key(key.public_key())
    .serial_number(x509.random_serial_number())
    .not_valid_before(now - datetime.timedelta(days=1))
    .not_valid_after(now + datetime.timedelta(days=3650))
    .add_extension(x509.SubjectAlternativeName(alt_names), critical=False)
    .add_extension(
        x509.BasicConstraints(ca=True, path_length=None), critical=True
    )
    .sign(key, hashes.SHA256())
)

# Export PEM
cert_pem = cert.public_bytes(serialization.Encoding.PEM).decode("utf-8")
key_pem = key.private_bytes(
    encoding=serialization.Encoding.PEM,
    format=serialization.PrivateFormat.PKCS8,
    encryption_algorithm=serialization.NoEncryption(),
).decode("utf-8")

os.makedirs("lib/services", exist_ok=True)
dart_content = f'''// Auto-generated self-signed SSL certificate for HTTPS on port 1212
class SslCerts {{
  static const String certificatePem = r\'\'\'{cert_pem}\'\'\';

  static const String privateKeyPem = r\'\'\'{key_pem}\'\'\';
}}
'''

with open("lib/services/ssl_certs.dart", "w", encoding="utf-8") as f:
    f.write(dart_content)

print("Generated lib/services/ssl_certs.dart successfully with Python cryptography!")
