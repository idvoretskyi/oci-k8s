# Pod Security Policy Enforcement in OCI Kubernetes

This document explains how this project addresses the security requirement CKV2_OCI_6: "Ensure Kubernetes Engine Cluster pod security policy is enforced."

## Problem Statement

Traditional Pod Security Policies (PSPs) are deprecated in Kubernetes 1.21 and removed entirely in 1.25+. However, security scanners like Checkov still check for pod security enforcement mechanisms.

## Solution Implemented

This project implements modern pod security enforcement using:

1. **OPA Gatekeeper** - Enabled directly in the OCI Kubernetes cluster configuration
2. **Pod Security Standards** - Applied via post-deployment configuration

### Cluster Configuration

The cluster module enables OPA Gatekeeper via the `admission_controller_options` block:

```terraform
admission_controller_options {
  is_pod_security_policy_enabled = false  // Deprecated in K8s, removed in 1.25+
  is_opa_gatekeeper_enabled      = var.enable_pod_security_admission  // Modern replacement
}
```

### Deployment Configuration

After cluster creation, a `null_resource` deploys:

1. Gatekeeper components to the cluster
2. Basic security policies that prevent privileged containers
3. Enforcement constraints that apply these policies to all non-system namespaces

## Security Benefits

This approach provides:

- **Modern security standards**: Uses current best practices instead of deprecated mechanisms
- **Defense in depth**: Prevents high-risk configurations like privileged containers
- **Compatibility**: Works with all Kubernetes versions, including the latest releases
- **Compliance**: Directly addresses the CKV2_OCI_6 requirement

## How to Customize

The `enable_pod_security_admission` variable (default: true) controls this feature. Set it to false to disable pod security enforcement.

Additional policies can be added by modifying the script in the `null_resource.deploy_pod_security_standards` resource.

## Verification

To verify pod security enforcement is working:

1. Try to create a privileged pod (it should be denied):
   ```bash
   kubectl run --privileged -it test --image=busybox -- sh
   ```

2. Check that Gatekeeper is deployed:
   ```bash
   kubectl get pods -n gatekeeper-system
   ```

3. Examine the constraints:
   ```bash
   kubectl get constrainttemplates
   kubectl get K8sPSPPrivilegedContainer
   ```