# OCI API Key Format Requirements

As of recent versions of the OCI SDK and CLI, Oracle requires a special label in your private key file to enhance security.

## Key Label Requirement

Your API private key file must contain the label `OCI_API_KEY` at the end of the file. This is a security measure implemented by Oracle.

### Why This Label Is Required

This label helps ensure that private keys specifically intended for OCI authentication aren't mistakenly used elsewhere, reducing security risks.

### How to Fix Your Key

If you see this warning:

```
Warning: To increase security of your API key located at ~/.oci/oci_api_key.pem, append an extra line with 'OCI_API_KEY' at the end.
```

You can fix it by running:

```bash
# Automatically fix the key format
chmod +x ./scripts/fix_key_label.sh
./scripts/fix_key_label.sh

# Or manually add the label
echo "OCI_API_KEY" >> ~/.oci/oci_api_key.pem
```

### Verify Your Key Format

To check if your key has the correct format:

```bash
chmod +x ./scripts/check_key_format.sh
./scripts/check_key_format.sh
```

### Suppressing the Warning

If you prefer not to modify your key, you can suppress the warning by setting an environment variable:

```bash
export SUPPRESS_LABEL_WARNING=True
```

You can add this to your `~/.bashrc` or `~/.zshrc` file to make it permanent.

## Regenerating Keys with the Correct Format

When generating new keys, you should add the OCI_API_KEY label:

```bash
# Generate the key
openssl genrsa -out ~/.oci/oci_api_key.pem 2048
chmod 600 ~/.oci/oci_api_key.pem

# Add the label
echo "OCI_API_KEY" >> ~/.oci/oci_api_key.pem

# Generate public key
openssl rsa -pubout -in ~/.oci/oci_api_key.pem -out ~/.oci/oci_api_key_public.pem
```

## Reference

For more information, see the [Oracle documentation on API signing keys](https://docs.oracle.com/iaas/Content/API/Concepts/apisigningkey.htm).
