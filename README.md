# OCI Kubernetes Cluster with ARM Workers

This Terraform configuration deploys a Kubernetes cluster (OKE) on Oracle Cloud Infrastructure using cost-effective ARM-based worker nodes.

## Prerequisites

1. [OCI CLI](https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/cliinstall.htm) installed and configured
2. [Terraform](https://www.terraform.io/downloads.html) installed (v1.0.0+)
3. OCI account with necessary permissions

## Configuration

Create a `terraform.tfvars` file in the `tf` directory with the following content:

```hcl
oci_profile     = "DEFAULT"  # OCI CLI profile name
region          = "us-ashburn-1"  # Your preferred OCI region
compartment_id  = "ocid1.compartment.oc1..aaaaaaa..."  # Your compartment OCID
availability_domain = "GrCH:US-ASHBURN-AD-1"  # Your availability domain
```

Customize other variables as needed:

- `kubernetes_version` - The Kubernetes version (default: "v1.27.2")
- `node_pool_size` - Number of worker nodes (default: 3)
- `node_image_id` - Oracle Linux ARM image OCID

## Usage

```bash
cd tf
terraform init
terraform plan
terraform apply
```

## Accessing the Cluster

After successful deployment, Terraform will output a command to get the kubeconfig file:

```bash
oci ce cluster create-kubeconfig --cluster-id <cluster_id> --file ~/.kube/config --region <region> --token-version 2.0.0
```

Run this command to configure kubectl to access your cluster:

```bash
kubectl get nodes
```

## Clean Up

To destroy all resources created by this Terraform configuration:

```bash
terraform destroy
```
