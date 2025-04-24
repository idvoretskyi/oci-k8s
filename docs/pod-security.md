# Pod Security Standards for OCI Kubernetes

This document explains how pod security is enforced in this OCI Kubernetes cluster implementation. The infrastructure uses modern pod security best practices to address security requirements like CKV2_OCI_6 (Ensure Kubernetes Engine Cluster pod security policy is enforced).

## Overview of Implementation

This project implements pod security at multiple levels:

1. **OPA Gatekeeper** - Enabled at the cluster level through OCI's `is_opa_gatekeeper_enabled` option
2. **Kubernetes Pod Security Standards** - Applied via namespace labels
3. **Custom security constraints** - Enforced through Gatekeeper rules

## How It Works

### 1. Cluster Configuration

The cluster is created with OPA Gatekeeper enabled, which provides the framework for policy enforcement:

```terraform
admission_controller_options {
  is_pod_security_policy_enabled = false  # Deprecated feature
  is_opa_gatekeeper_enabled = true        # Modern replacement
}
```

### 2. Pod Security Standards

After cluster creation, we apply the Kubernetes Pod Security Standards configuration:

- **Baseline** enforcement level for all namespaces
- **Restricted** audit and warning levels to help identify non-compliant workloads
- Exemptions for system namespaces (`kube-system`, `kube-public`, `kube-node-lease`)

We apply these standards using namespace labels:

```yaml
pod-security.kubernetes.io/enforce: baseline
pod-security.kubernetes.io/audit: restricted
pod-security.kubernetes.io/warn: restricted
```

### 3. OPA Gatekeeper Constraints

Additionally, we deploy specific Gatekeeper constraints that enforce security rules:

- No privileged containers
- No host paths or host namespaces
- No capabilities beyond a restricted set
- No privilege escalation

## Security Levels Explained

1. **Baseline** - Minimal security features that prevent known privilege escalations
2. **Restricted** - Heavily restricted pod configuration following security best practices

## Compliance and Security Benefits

This implementation directly addresses security finding CKV2_OCI_6 by:

- Replacing deprecated Pod Security Policies with modern alternatives
- Enforcing consistent pod security across the cluster
- Implementing defense-in-depth through multiple mechanisms
- Auditing and warning about non-compliant configurations

## Customizing Pod Security

You can customize the security posture by modifying:

1. The `enable_pod_security_admission` variable (default: true)
2. Adding custom OPA constraints in the pod_security_standards resource
3. Adjusting enforcement levels for specific namespaces

## Verification

To verify the Pod Security Standards are working:

```bash
# Check for OPA Gatekeeper deployment
kubectl get deployments -n gatekeeper-system

# Verify namespace labels
kubectl get ns default -o yaml | grep pod-security

# Test by deploying a privileged container (should be rejected)
kubectl run privileged-pod --image=nginx --privileged
```