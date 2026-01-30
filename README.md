<div align="center">🌐 hybrid-cloud-automation-engine 🌐Cloud-Native Multi-Cloud VPN GatewayA reproducible, IaC-first reference for connecting an on-prem (Raspberry Pi / VM) network to OCI and AWS using Terraform and Ansible.</div>📢 ReleaseThis repository contains the initial public PoC (v1.0.0). See RELEASE.md for the release notes and changelog. Use the included scripts/publish_repo.ps1 helper to push and configure repository settings once you've authenticated gh locally.💡 Why This Project?Infrastructure as Code: Terraform modules for OCI (VCN) and AWS (VPC) show reusable infra code.Hybrid Networking: Demonstrates cross-cloud connectivity using WireGuard/OpenVPN and automated instance configuration via Ansible.Security-First: Emphasis on encrypted VPN tunnels, least-privilege security groups, and minimal public surface.🏗️ ArchitectureEditable Source: docs/architecture.drawio (Open in draw.io).Exports: docs/architecture.svg and docs/architecture.png.🎥 Demo🎨 Why This Design?Hybrid Connectivity: An on-prem gateway (Raspberry Pi/VM) establishes encrypted tunnels to cloud peers. This keeps control of routing and security while extending internal networks.Separation of Concerns: Terraform defines network constructs; Ansible handles node-level configuration (WireGuard keys/config).Modern Encryption: WireGuard provides lightweight, state-of-the-art encryption with minimal overhead.💰 Cost Analysis (PoC)ProviderResourceEstimated CostAWS1x t3.micro EC2 + 8GB gp3$0 – $10/mo (Free Tier eligible)OCIVM.Standard.E2.1.Micro$0 – $10/mo (Always Free eligible)DataEgress / Health Checks< $1/mo (Low-traffic PoC)Optimization Tip: Use free-tier shapes, destroy resources after demos, and keep bulk data local to avoid egress fees.🚀 Quickstart1. Environment SetupPowerShellgit clone https://github.com/careed23/hybrid-cloud-automation-engine.git
cd hybrid-cloud-automation-engine
2. ConfigurationCopy examples/terraform/terraform.tfvars.example to examples/terraform/terraform.tfvars and fill in your OCI/AWS credentials and OCIDs.3. DeploymentUsing Makefile:PowerShellmake init
make plan
make apply
make gen-inventory
ansible-playbook -i ansible/inventory.tf.ini ansible/site.yml
Using Windows PowerShell Wrapper:PowerShell.\scripts\deploy_and_inventory.ps1 -AutoApprove
ansible-playbook -i ansible/inventory.tf.ini ansible/site.yml
🧪 Testing & CITo run unit tests locally:PowerShell# Install dependencies
python -m pip install -r requirements.txt

# Run pytest
python -m pytest -q
The .github/workflows/ci.yml automatically validates Terraform formatting and runs tests on every push.🔒 Security NoteThis PoC is minimal. For production:Integrate a Secrets Manager (Vault/AWS/OCI) for WireGuard private keys.Restrict CIDRs in security groups.Use least-privilege IAM roles.
