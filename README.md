# Terraform OCI Kubernetes

This project creates a Kubernetes cluster (OKE) on Oracle Cloud Infrastructure using Terraform.

## Repository Structure

```
.
├── modules
│   ├── cluster
│   ├── network
│   └── node_pool
├── scripts
│   ├── set_env_vars.sh
│   └── verify_config.sh
├── main.tf
├── outputs.tf
├── provider.tf
├── variables.tf
└── README.md
```

## Prerequisites

1. Install OCI CLI and Terraform
2. Configure OCI credentials

## OCI CLI Configuration

Before running Terraform, ensure your OCI CLI is configured with proper authentication:

```bash
# Install OCI CLI
bash -c "$(curl -L https://raw.githubusercontent.com/oracle/oci-cli/master/scripts/install/install.sh)"

# Configure OCI CLI
oci setup config
```

N/A

This will create a config file at `~/.oci/config` with your credentials.

Ensure your config contains the following for the DEFAULT profile:

```
[DEFAULT]
user=ocid1.user.oc1..example
fingerprint=aa:bb:cc:dd:ee:ff:gg:hh:ii:jj:kk:ll:mm:nn:oo:pp
key_file=~/.oci/oci_api_key.pem
tenancy=ocid1.tenancy.oc1..example
region=uk-london-1
```

## Authentication

Terraform can use your OCI configuration automatically without explicitly setting credentials in the provider block. The terraform-oci-k8s project is set up to use:

1. The **DEFAULT** profile from `~/.oci/config` (simplest approach)
2. Environment variables if present (override config file)

### Verifying Your Configuration

Run the verification script to ensure your OCI config is complete:

```bash
chmod +x ./scripts/verify_config.sh
./scripts/verify_config.sh
```

### Using Environment Variables

If your configuration file isn't working, you can use environment variables instead:

```bash
chmod +x ./scripts/set_env_vars.sh
eval "$(./scripts/set_env_vars.sh)"
```

## Usage

```bash
cd tf
terraform init
terraform plan
terraform apply
```

## Troubleshooting

If you encounter authentication issues:

1. **Verify OCI CLI works**: Run `oci iam region list` to verify your CLI configuration works
2. **Check key permissions**: Run `chmod 600 ~/.oci/oci_api_key.pem` to set correct permissions
3. **Use environment variables**: If config file doesn't work, use the environment variable approach
4. **Check your keys**: Ensure your API key is properly generated and uploaded to OCI console
