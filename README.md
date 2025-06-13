# OCI ARM Kubernetes Cluster

Simple OpenTofu configuration for deploying ARM-based Kubernetes clusters on Oracle Cloud Infrastructure (OCI) in the London region.

## Features

- **ARM instances**: Uses cost-effective VM.Standard.A1.Flex shape
- **Automatic image selection**: Dynamically finds latest Oracle Linux 8 ARM image
- **Minimal configuration**: Clean, comment-free code with sensible defaults
- **London region**: Pre-configured for uk-london-1

## Architecture

- **Nodes**: 3x ARM nodes (1 vCPU, 6GB RAM each)
- **Network**: Simple VCN with public subnets
- **Security**: Basic security lists for SSH, K8s API, and NodePort services

## Prerequisites

- OCI CLI configured with API keys
- OpenTofu 1.0+
- `kubectl` for cluster access

## Quick Start

1. **Configure your tenancy**
   ```bash
   cd tf
   # Edit terraform.tfvars with your tenancy OCID
   ```

2. **Deploy**
   ```bash
   tofu init
   tofu apply
   ```

3. **Access cluster**
   ```bash
   # Use the output command to get kubeconfig
   tofu output kubeconfig_command
   # Then run the command it provides
   ```

## Configuration

Key variables in `terraform.tfvars`:

| Variable | Default | Description |
|----------|---------|-------------|
| `tenancy_ocid` | - | Your OCI tenancy OCID (required) |
| `cluster_name` | `oke-arm` | Cluster name |
| `node_count` | `3` | Number of worker nodes |
| `node_memory_gb` | `6` | Memory per node (GB) |
| `node_ocpus` | `1` | vCPUs per node |

## Cost Optimization

ARM instances (A1.Flex) are significantly cheaper than x86:
- Always Free eligible (up to 4 OCPUs, 24GB RAM)
- ~75% cost savings vs equivalent x86 instances

## Troubleshooting

**ARM capacity issues**: ARM instances may have limited availability. Try:
- Reducing `node_count` to 1
- Waiting and retrying later
- Using different availability domain

**Image not found**: The configuration automatically selects the latest ARM-compatible Oracle Linux 8 image for the London region.

## License

MIT License - see [LICENSE](LICENSE) file.