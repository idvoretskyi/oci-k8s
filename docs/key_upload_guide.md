# OCI API Key Upload Guide

This guide shows you how to upload an API key to your OCI user account.

## Step 1: Access User Settings

1. Log in to the OCI Console at https://cloud.oracle.com/
2. Click on the profile icon in the top right corner
3. Select "User Settings" from the dropdown menu

![User Settings](https://docs.oracle.com/en-us/iaas/Content/Resources/Images/console_profile_menu.png)

## Step 2: Navigate to API Keys Section

1. On the left sidebar of the User Details page, find "Resources"
2. Click on "API Keys"

## Step 3: Add a New API Key

1. Click the "Add API Key" button
2. In the dialog that appears, select "Paste Public Key"
3. Paste the contents of your public key file (`~/.oci/oci_api_key_public.pem`)
4. Click "Add"

![Add API Key](https://docs.oracle.com/en-us/iaas/Content/Resources/Images/add_api_key_dialog.png)

## Step 4: Verify Your API Key

1. The fingerprint of your uploaded key will be displayed in the API Keys list
2. Make sure this fingerprint matches the one in your `~/.oci/config` file
3. You can have multiple API keys, but make sure you're using the correct fingerprint in your config

## Step 5: Test Your Configuration

Run the following command to test your OCI CLI configuration:

```bash
oci iam region list
```

If this works, your API key is properly configured.

## Common Issues

### Too Many API Keys

If you get an error saying you have too many API keys, you'll need to delete an existing key:

1. In the API Keys section, find an old key you no longer need
2. Click the three dots menu (⋮) next to it
3. Select "Delete"
4. Confirm the deletion
5. Try adding your new key again

### Fingerprint Mismatch

If you get authentication errors, verify that the fingerprint in your `~/.oci/config` file exactly matches the one shown in the OCI Console for your key.
