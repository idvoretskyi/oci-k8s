# Simple ARM OKE Cluster on Oracle Cloud Infrastructure

This configuration creates a straightforward ARM-based Kubernetes cluster on OCI, following Oracle's best practices for ARM deployments.

## Architecture

- **Compute**: VM.Standard.A1.Flex (ARM64)
- **Network**: Simple VCN with public/private subnets
- **Kubernetes**: Latest stable version with ARM optimizations
- **Node Pool**: Private subnet placement for security

## Prerequisites

1. OCI CLI configured with valid credentials
2. Terraform/OpenTofu installed
3. Valid OCI API key

## Quick Start

1. **Initialize:**
   ```bash
   tofu init
   ```

2. **Plan deployment:**
   ```bash
   tofu plan
   ```

3. **Deploy cluster:**
   ```bash
   tofu apply
   ```

4. **Configure kubectl:**
   ```bash
   # Get the kubeconfig command from outputs
   tofu output kubeconfig_command
   
   # Run the command (example):
   oci ce cluster create-kubeconfig --cluster-id <cluster-id> --file ~/.kube/config --region uk-london-1 --token-version 2.0.0
   ```

5. **Verify cluster:**
   ```bash
   kubectl get nodes -o wide
   kubectl get nodes --show-labels | grep arch
   ```

## ARM-Specific Features

- **Architecture Labels**: Nodes are automatically labeled with `kubernetes.io/arch=arm64`
- **Multi-arch Support**: Container runtime will automatically pull ARM64 images
- **Oracle Linux 8**: Latest ARM-compatible image
- **Private Networking**: Worker nodes in private subnet (Oracle recommendation)

## Configuration

Key variables in `terraform.tfvars`:

```hcl
cluster_name = "simple-arm-oke"
kubernetes_version = "v1.30.1"
node_count = 1
node_memory_gb = 6
node_ocpus = 1
```

## Testing ARM Deployment

Deploy a test application to verify ARM functionality:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: arm-test
spec:
  replicas: 1
  selector:
    matchLabels:
      app: arm-test
  template:
    metadata:
      labels:
        app: arm-test
    spec:
      containers:
      - name: nginx
        image: nginx:latest
        ports:
        - containerPort: 80
      nodeSelector:
        kubernetes.io/arch: arm64
```

## Cleanup

```bash
tofu destroy
```

## ARM Advantages

- **Cost Effective**: ARM instances typically cost 20-30% less
- **Energy Efficient**: Better performance per watt
- **Modern Architecture**: Latest ARM cores with advanced features
- **Container Optimized**: Excellent performance for containerized workloads

## Notes

- Start with small node configurations and scale as needed
- Most container images now support multi-architecture builds
- Java/bytecode applications typically work unchanged on ARM
- Compiled applications may need ARM-specific builds