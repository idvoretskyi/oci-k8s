# Pod Security Standards for OCI Kubernetes

This document provides guidance for implementing Pod Security Standards in your OCI Kubernetes cluster.

## Background

**Pod Security Policies (PSP)** have been deprecated in Kubernetes v1.21 and removed entirely in v1.25+. The `is_pod_security_policy_enabled` parameter in the OCI terraform provider no longer works with current Kubernetes versions.

## Recommended Alternatives

### 1. Pod Security Standards (PSS)

Kubernetes 1.25+ natively supports Pod Security Standards through the built-in Pod Security Admission Controller.

#### Implementation Steps

1. **Update the OKE cluster** with the following admission controller configuration:

```yaml
apiVersion: apiserver.config.k8s.io/v1
kind: AdmissionConfiguration
plugins:
  - name: PodSecurity
    configuration:
      apiVersion: pod-security.admission.config.k8s.io/v1
      kind: PodSecurityConfiguration
      defaults:
        enforce: "baseline"
        enforce-version: "latest"
        audit: "restricted"
        audit-version: "latest"
        warn: "restricted"
        warn-version: "latest"
      exemptions:
        usernames: []
        runtimeClasses: []
        namespaces: [kube-system]
```

2. **Apply per-namespace security standards** by adding labels:

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: my-namespace
  labels:
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/audit: restricted
    pod-security.kubernetes.io/warn: restricted
```

### 2. OPA/Gatekeeper

For more flexible policy enforcement, consider implementing [OPA Gatekeeper](https://open-policy-agent.github.io/gatekeeper/website/docs/).

#### Implementation Steps

1. **Install Gatekeeper**:

```bash
kubectl apply -f https://raw.githubusercontent.com/open-policy-agent/gatekeeper/release-3.10/deploy/gatekeeper.yaml
```

2. **Define constraint templates** for your security policies:

```yaml
apiVersion: templates.gatekeeper.sh/v1
kind: ConstraintTemplate
metadata:
  name: k8spsprivilegedcontainer
spec:
  crd:
    spec:
      names:
        kind: K8sPSPPrivilegedContainer
  targets:
    - target: admission.k8s.gatekeeper.sh
      rego: |
        package k8spsprivileged
        violation[{"msg": msg}] {
          c := input_containers[_]
          c.securityContext.privileged
          msg := "Privileged containers are not allowed"
        }
        input_containers[c] {
          c := input.review.object.spec.containers[_]
        }
        input_containers[c] {
          c := input.review.object.spec.initContainers[_]
        }
```

3. **Apply constraints** to enforce policies:

```yaml
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: K8sPSPPrivilegedContainer
metadata:
  name: no-privileged-containers
spec:
  match:
    kinds:
      - apiGroups: [""]
        kinds: ["Pod"]
    excludedNamespaces: ["kube-system"]
```

### 3. Kyverno

[Kyverno](https://kyverno.io/) is another policy engine specifically designed for Kubernetes.

#### Implementation Steps

1. **Install Kyverno**:

```bash
kubectl create -f https://github.com/kyverno/kyverno/releases/download/v1.8.0/install.yaml
```

2. **Create policies**:

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: no-privileged
spec:
  validationFailureAction: enforce
  rules:
  - name: no-privileged-containers
    match:
      resources:
        kinds:
        - Pod
    validate:
      message: "Privileged containers are not allowed"
      pattern:
        spec:
          containers:
          - =(securityContext):
              =(privileged): "false"
```

## Security Considerations

When implementing Pod Security:

1. Start with audit mode to understand impact
2. Apply stricter policies to critical namespaces
3. Create exemptions for system workloads
4. Combine with network policies for defense-in-depth

## References

- [Kubernetes Pod Security Standards](https://kubernetes.io/docs/concepts/security/pod-security-standards/)
- [OPA Gatekeeper](https://open-policy-agent.github.io/gatekeeper/website/docs/)
- [Kyverno](https://kyverno.io/docs/)