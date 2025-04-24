# OCI Kubernetes with OpenTofu

This project creates a Kubernetes cluster (OKE) on Oracle Cloud Infrastructure using OpenTofu (an open source infrastructure-as-code tool).

## Repository Structure

```
.
├── modules
│   ├── cluster
│   ├── network
│   ├── node-pool
│   └── monitoring
├── tf
│   ├── main.tf
│   ├── outputs.tf
│   ├── provider.tf
│   ├── variables.tf
│   └── versions.tf
├── docs
│   ├── troubleshooting.md
│   ├── key_format.md
│   └── key_upload_guide.md
└── README.md
```

## Prerequisites

1. Install OCI CLI and OpenTofu
2. Configure OCI credentials

## OCI CLI Configuration

Before running OpenTofu, ensure your OCI CLI is configured with proper authentication:

```bash
# Install OCI CLI
bash -c "$(curl -L https://raw.githubusercontent.com/oracle/oci-cli/master/scripts/install/install.sh)"

# Configure OCI CLI
oci setup config
```

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

OpenTofu can use your OCI configuration automatically without explicitly setting credentials in the provider block. The oci-k8s project is set up to use:

1. The **DEFAULT** profile from `~/.oci/config` (simplest approach)
2. Environment variables if present (override config file)

### Verifying Your Configuration

Run the following commands to ensure your OCI config is complete:

```bash
oci iam region list
```

### Using Environment Variables

If your configuration file isn't working, you can use environment variables instead:

```bash
export TF_VAR_user_ocid="ocid1.user.oc1..example"
export TF_VAR_fingerprint="aa:bb:cc:dd:ee:ff:gg:hh:ii:jj:kk:ll:mm:nn:oo:pp"
export TF_VAR_private_key_path="~/.oci/oci_api_key.pem"
export TF_VAR_tenancy_ocid="ocid1.tenancy.oc1..example"
export TF_VAR_region="uk-london-1"
```

## Security Requirements

### Required Variables

When using this project, you must set the following variables for security:

- `grafana_admin_password` - Must be set to a strong password (min 12 chars, mix of letters, numbers, symbols)

Example using environment variable:
```bash
export TF_VAR_grafana_admin_password="StrongUnique-Password!123"
```

Or in your own tfvars file (do not commit this file to version control):
```hcl
grafana_admin_password = "StrongUnique-Password!123"
```

## Usage

```bash
cd tf
tofu init
tofu plan
tofu apply
```

## Accessing Your Kubernetes Cluster

After the cluster is created, you can access it using kubectl in two ways:

### Method 1: Using OpenTofu Outputs

1. **Get the kubeconfig command directly from OpenTofu output**:

   ```bash
   # This will output the full command needed to generate your kubeconfig
   tofu output -raw get_kubeconfig_command
   ```

2. **Run the generated command directly**:

   ```bash
   # This executes the command from OpenTofu output
   eval $(tofu output -raw get_kubeconfig_command)
   ```

3. **Verify your connection**:
   ```bash
   kubectl get nodes
   kubectl cluster-info
   ```

### Method 2: Manual Configuration

1. **Get the cluster ID and region**:

   ```bash
   # Get cluster ID
   CLUSTER_ID=$(tofu output -raw cluster_id)

   # Get region
   REGION=$(tofu output -raw region)

   # Generate kubeconfig
   oci ce cluster create-kubeconfig --cluster-id $CLUSTER_ID --file ~/.kube/config --region $REGION --token-version 2.0.0
   ```

2. **Set kubectl context**:
   ```bash
   kubectl config use-context <context-name>
   ```

### Accessing the Monitoring Dashboards

If monitoring is enabled (default), you can access the dashboards using:

```bash
# Check if monitoring is enabled
tofu output monitoring_enabled

# Get Grafana credentials
tofu output grafana_admin_info

# Port-forward to access Grafana
kubectl port-forward svc/prometheus-grafana 3000:80 -n monitoring
```

Then access Grafana at http://localhost:3000

## Monitoring

This project includes a comprehensive monitoring stack:

### Components

- **Prometheus**: Metrics collection and storage
- **Grafana**: Metrics visualization and dashboards
- **Alertmanager**: Alert management and notifications
- **Node Exporter**: Machine-level metrics collection
- **Loki** (optional): Log aggregation

### Accessing the Dashboards

After creating the cluster, you can access the monitoring dashboards:

1. **Port Forward Grafana**:

   ```bash
   kubectl port-forward svc/prometheus-grafana 3000:80 -n monitoring
   ```

2. **Access Grafana**:

   - URL: http://localhost:3000
   - Default credentials:
     - Username: admin
     - Password: The value you set for `grafana_admin_password`

3. **Port Forward Prometheus** (optional):
   ```bash
   kubectl port-forward svc/prometheus-kube-prometheus-prometheus 9090:9090 -n monitoring
   ```

### Pre-configured Dashboards

The Grafana installation comes with several pre-configured dashboards:

- Kubernetes Cluster Overview
- Node Exporter metrics
- Pod Monitoring

### Customizing Monitoring

You can customize the monitoring stack by:

- Setting `enable_monitoring = false` to disable it completely
- Adjusting storage sizes via variables
- Providing custom configuration values
- Enabling or disabling Loki for log collection

## Security Scanning

This project uses automated security scanning to identify potential vulnerabilities:

- **GitHub Actions**: Automatically scans code on push/PR and uploads results to GitHub Security
- **Pre-commit hooks**: Scans code locally before committing

For more information, see [Security Scanning Documentation](docs/security-scanning.md).

## Troubleshooting

If you encounter authentication issues:

1. **Verify OCI CLI works**: Run `oci iam region list` to verify your CLI configuration works
2. **Check key permissions**: Run `chmod 600 ~/.oci/oci_api_key.pem` to set correct permissions
3. **Use environment variables**: If config file doesn't work, use the environment variable approach
4. **Check your keys**: Ensure your API key is properly generated and uploaded to OCI console
