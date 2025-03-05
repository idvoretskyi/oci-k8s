# Troubleshooting OCI Authentication Issues

This guide helps diagnose and fix common authentication issues with Oracle Cloud Infrastructure.

## 401-NotAuthenticated Errors

If you see a 401-NotAuthenticated error, it means your authentication credentials are being rejected by OCI. Follow these steps to diagnose and fix the issue:

### 1. Verify OCI CLI Authentication

First, check if the OCI CLI can authenticate with your credentials:

```bash
# Run our test script
chmod +x ./scripts/test_oci_auth.sh
./scripts/test_oci_auth.sh

# Or run this command directly
oci iam region list
```

If this fails, your credentials are incorrect or invalid.

### 2. Verify Your Fingerprint

```bash
chmod +x ./scripts/verify_fingerprint.sh
./scripts/verify_fingerprint.sh
```

This will check if the fingerprint in your config matches your private key.

### 3. Check Your OCI Configuration

Ensure your `~/.oci/config` file contains correct information:
- `user` should be your user OCID from OCI Console
- `tenancy` should be your tenancy OCID
- `fingerprint` should match the one for the key uploaded to OCI
- `region` should be a valid OCI region (e.g., uk-london-1)

### 4. Regenerate Your Keys

If the verification steps indicate issues, generate new keys:

```bash
# Generate a new key pair
openssl genrsa -out ~/.oci/oci_api_key.pem 2048
chmod 600 ~/.oci/oci_api_key.pem
openssl rsa -pubout -in ~/.oci/oci_api_key.pem -out ~/.oci/oci_api_key_public.pem

# Get the fingerprint
openssl rsa -pubout -outform DER -in ~/.oci/oci_api_key.pem | openssl md5 -c
```

Then:
1. Upload the public key (`~/.oci/oci_api_key_public.pem`) to the OCI Console
2. Update the fingerprint in `~/.oci/config`

### 5. Permissions Issues

Ensure your user has appropriate permissions:
- Belongs to at least one group
- The group has policies allowing it to use resources

A minimal policy would be:
```
Allow group <your-group> to read all-resources in tenancy
```

For Terraform to create resources, you'll need more extensive permissions.

### 6. Verify User Status

Check if your user account is active and not locked.

## Common Error Messages and Solutions

### "The required information to complete authentication was not provided or was incorrect"

This typically means:
- Incorrect fingerprint
- Key mismatch (private key doesn't match public key in OCI)
- Incorrect user or tenancy OCID

### "Not Authorized"

This means:
- Your credentials are correct but you lack permissions
- Check IAM policies for your user's groups

### "Wrong Private Key PEM Format"

This means:
- Your private key isn't in the expected format
- Try converting it: `openssl rsa -in ~/.oci/oci_api_key.pem -out ~/.oci/oci_api_key_new.pem`
- Then update your config to use the new key
