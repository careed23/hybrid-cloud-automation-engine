Release: v1.0.0

Hybrid-Cloud Automation Engine — initial public PoC release

What's included
- Terraform modules for AWS and OCI (VCN/VPC) and an example root that provisions small compute instances.
- Ansible automation to install and configure WireGuard on cloud instances, with an automated public-key exchange playbook.
- A health-check script with unit tests to validate tunnel connectivity.
- CI workflows for tests and a safe Terraform plan on PRs.
- Docs: architecture diagram (draw.io, SVG/PNG) and a short demo GIF.

Notes
- This release is intended as a PoC and demo. The project demonstrates patterns and automation; adapt and harden for production (secret management, least-privilege, monitoring, and cost controls).

How to get started
1) Follow the Quickstart in README.md
2) Provision the example resources with Terraform and run Ansible playbook
3) Use the included scripts to generate inventory and run the health-check

Changelog
- v1.0.0 (2026-01-29): Initial PoC release: modules, examples, Ansible, CI, docs, and publish helper script.
