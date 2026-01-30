<div align="center">

# 🌐 hybrid-cloud-automation-engine 🌐

### **Cloud-Native Multi-Cloud VPN Gateway**
*A reproducible, IaC-first reference for connecting an on-prem (Raspberry Pi / VM) network to OCI and AWS using Terraform and Ansible.*

<p align="center">
  <img src="https://img.shields.io/badge/License-MIT-yellow.svg" alt="License">
  <img src="https://github.com/careed23/hybrid-cloud-automation-engine/actions/workflows/ci.yml/badge.svg" alt="CI">
  <img src="https://github.com/careed23/hybrid-cloud-automation-engine/actions/workflows/terraform-plan.yml/badge.svg" alt="Terraform Plan">
</p>

---

</div>

<h2 align="center">📢 Release</h2>

This repository contains the initial public PoC (**v1.0.0**). See `RELEASE.md` for the release notes and changelog. Use the included `scripts/publish_repo.ps1` helper to push and configure repository settings once you've authenticated `gh` locally.

<h2 align="center">💡 Why This Project?</h2>

* **Infrastructure as Code:** Terraform modules for OCI (VCN) and AWS (VPC) show reusable infra code.
* **Hybrid Networking:** Demonstrates cross-cloud connectivity using WireGuard/OpenVPN and automated instance configuration via Ansible.
* **Security-First:** Emphasis on encrypted VPN tunnels, least-privilege security groups, and minimal public surface.

<h2 align="center">🏗️ Architecture</h2>

<p align="center">
  <img src="docs/architecture.svg" alt="Architecture diagram" width="800">
</p>

* **Editable Source:** `docs/architecture.drawio` (Open in [draw.io](https://app.diagrams.net/)).
* **Exports:** `docs/architecture.svg` and `docs/architecture.png`.

<h2 align="center">🎥 Demo</h2>

<p align="center">
  <img src="docs/demo.gif" alt="Demo placeholder">
</p>

<h2 align="center">🎨 Why This Design?</h2>

* **Hybrid Connectivity:** An on-prem gateway (Raspberry Pi/VM) establishes encrypted tunnels to cloud peers. This keeps control of routing and security while extending internal networks.
* **Separation of Concerns:** Terraform defines network constructs; Ansible handles node-level configuration (WireGuard keys/config).
* **Modern Encryption:** WireGuard provides lightweight, state-of-the-art encryption with minimal overhead.

<h2 align="center">💰 Cost Analysis (PoC)</h2>

<div align="center">

| Provider | Resource | Estimated Cost |
| :--- | :--- | :--- |
| **AWS** | 1x t3.micro EC2 + 8GB gp3 | $0 – $10/mo (Free Tier eligible) |
| **OCI** | VM.Standard.E2.1.Micro | $0 – $10/mo (Always Free eligible) |
| **Data** | Egress / Health Checks | < $1/mo (Low-traffic PoC) |

</div>

> **Optimization Tip:** Use free-tier shapes, destroy resources after demos, and keep bulk data local to avoid egress fees.

---

<h2 align="center">🚀 Quickstart</h2>

### 1. Environment Setup
```powershell
git clone [https://github.com/careed23/hybrid-cloud-automation-engine.git](https://github.com/careed23/hybrid-cloud-automation-engine.git)
cd hybrid-cloud-automation-engine
2. Configuration
Copy examples/terraform/terraform.tfvars.example to examples/terraform/terraform.tfvars and fill in your OCI/AWS credentials and OCIDs.

3. Deployment
Using Makefile:

PowerShell
make init
make plan
make apply
make gen-inventory
ansible-playbook -i ansible/inventory.tf.ini ansible/site.yml
<h2 align="center">🧪 Testing & CI</h2>

To run unit tests locally:

PowerShell
# Install dependencies
python -m pip install -r requirements.txt

# Run pytest
python -m pytest -q
The .github/workflows/ci.yml automatically validates Terraform formatting and runs tests on every push.

<h2 align="center">🔒 Security Note</h2>

This PoC is minimal. For production:

Integrate a Secrets Manager (Vault/AWS/OCI) for WireGuard private keys.

Restrict CIDRs in security groups.

Use least-privilege IAM roles.

<p align="center"><b>Author:</b> Architect-friendly reference. Use and adapt freely for demos or PoCs.</p>
