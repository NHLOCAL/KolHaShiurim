import json
import base64
from datetime import datetime, timedelta, timezone
import argparse

from Crypto.Hash import SHA256
from Crypto.PublicKey import RSA
from Crypto.Signature import pkcs1_15

def generate_license(private_key_path, hardware_fingerprint, issued_to, validity_days, output_file, features=None):
    """
    Generates a rock-solid, canonical license file for the Torah Shiurim Transfer application.
    This version implements the recommended canonicalization and signing process.
    """
    print("--- 🔐 Generating License (v5 - Fully Canonical) ---")

    # 1. Load the private key
    try:
        with open(private_key_path, "rb") as key_file:
            private_key = RSA.import_key(key_file.read())
        print(f"✅ Private key loaded from: {private_key_path}")
    except Exception as e:
        print(f"❌ ERROR: Failed to load private key. {e}")
        return

    # 2. Prepare the license payload. This is the data that will be signed.
    issued_on = datetime.now(timezone.utc)
    valid_until = issued_on + timedelta(days=validity_days)
    
    payload_map = {
        'fingerprint': hardware_fingerprint,
        'issued_to': issued_to,
        'issued_on': issued_on.isoformat().replace('+00:00', 'Z'),
        'valid_until': valid_until.isoformat().replace('+00:00', 'Z'),
        'features': features or [],
    }
    print(f"📝 Payload created for '{issued_to}' valid for {validity_days} days.")

    # 3. Create the CANONICAL JSON payload bytes. This is the core fix.
    #    - sort_keys=True: Alphabetically sorts keys.
    #    - separators=(',', ':'): Removes all whitespace.
    #    - ensure_ascii=False: Correctly handles non-ASCII characters.
    payload_bytes = json.dumps(
        payload_map,
        sort_keys=True,
        separators=(',', ':'),
        ensure_ascii=False
    ).encode('utf-8')
    
    print("   Canonical payload string created for signing:")
    print(f"   {payload_bytes.decode('utf-8')}")

    # 4. Sign the canonical payload bytes using RSA-2048 PKCS#1 v1.5 + SHA-256
    h = SHA256.new(payload_bytes)
    signer = pkcs1_15.new(private_key)
    signature = signer.sign(h)
    print("   Payload signed successfully.")

    # 5. Encode the signature using URL-safe Base64
    signature_b64url = base64.urlsafe_b64encode(signature).decode('utf-8')
    print("   Signature encoded to URL-safe Base64.")

    # 6. Create the final license object for the file, including the signature
    final_license_data = payload_map.copy()
    final_license_data['signature'] = signature_b64url
    print("   Final license object constructed for file output.")

    # 7. Save the final object to the license file
    try:
        with open(output_file, 'w', encoding='utf-8') as f:
            # The final file can be pretty-printed for readability
            json.dump(final_license_data, f, indent=2, ensure_ascii=False)
        print(f"✅ License file successfully saved to: {output_file}")
        print("--- Generation Complete ---")
    except Exception as e:
        print(f"❌ ERROR: Failed to save the license file. {e}")


def main():
    parser = argparse.ArgumentParser(description="Torah Shiurim Transfer - Canonical License Generator")
    parser.add_argument("fingerprint", help="The hardware fingerprint provided by the client's application.")
    parser.add_argument("-n", "--name", required=True, help="Name of the person or entity the license is issued to.")
    parser.add_argument("-d", "--days", type=int, default=365, help="Number of days the license will be valid.")
    parser.add_argument("-k", "--key", default="private.pem", help="Path to the RSA private key file.")
    parser.add_argument("-o", "--output", default="license.lic", help="Name of the output license file.")
    parser.add_argument("-f", "--feature", action='append', help="A feature to include in the license.")

    args = parser.parse_args()
    generate_license(
        private_key_path=args.key,
        hardware_fingerprint=args.fingerprint,
        issued_to=args.name,
        validity_days=args.days,
        output_file=args.output,
        features=args.feature
    )

if __name__ == "__main__":
    main()