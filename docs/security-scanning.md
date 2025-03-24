# Security Scanning for Terraform/OpenTofu Code

This project uses automated security scanning to identify potential security issues in the Terraform/OpenTofu code.

## Automated Scanning with GitHub Actions

Each push and pull request triggers security scans using:

- **TFSec**: Analyzes code against best practices for security
- **Checkov**: Detects security and compliance misconfigurations
- **Terrascan**: Identifies violations of security best practices

Results are automatically uploaded to the GitHub Security tab as SARIF files.

### Enhanced TFSec Scanning

Our TFSec scanning includes:

- Custom rule checks specific to OCI resources
- Variable value evaluation via tfvars
- HTML reports for better visualization
- PR comments with scan summaries
- Configurable severity thresholds (currently set to show MEDIUM and above)
- Detailed SARIF reports in GitHub Security tab

## Viewing Scan Results

1. In your GitHub repository, go to the "Security" tab
2. Select "Code scanning alerts" from the left sidebar
3. Review identified issues by severity and tool

## Running Scans Locally

### Pre-commit Hooks (Recommended)

Install pre-commit hooks to scan automatically before committing:

```bash
# Install pre-commit
pip install pre-commit

# Install git hooks
pre-commit install
```

### Manual Scanning

Run scanning tools directly:

```bash
# Install TFSec
brew install tfsec  # macOS
# Or
curl -L "$(curl -s https://api.github.com/repos/aquasecurity/tfsec/releases/latest | grep -o -E "https://.+?_Linux_x86_64.tar.gz")" | tar xz -C /tmp && sudo mv /tmp/tfsec /usr/local/bin/

# Run TFSec
tfsec .

# Install Checkov
pip install checkov

# Run Checkov
checkov -d .

# Install Terrascan
brew install terrascan  # macOS
# Or
curl -L "$(curl -s https://api.github.com/repos/tenable/terrascan/releases/latest | grep -o -E "https://.+?_Linux_x86_64.tar.gz")" > terrascan.tar.gz && tar -xf terrascan.tar.gz terrascan && sudo mv terrascan /usr/local/bin/

# Run Terrascan
terrascan scan -d .
```

## Security Best Practices

When developing Terraform/OpenTofu code for this project:

1. Avoid hardcoding sensitive data (passwords, tokens)
2. Use minimal IAM permissions (principle of least privilege)
3. Encrypt data at rest and in transit
4. Enable logging and monitoring for all resources
5. Restrict network access to resources
