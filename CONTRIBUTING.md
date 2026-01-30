# Contributing

Thanks for taking an interest in improving this project. This file explains how to contribute safely and effectively.

Reporting bugs
- Open an issue with a clear title and steps to reproduce. Include Terraform/Ansible versions and the platform you ran on.
- Provide minimal repro steps and any relevant logs (redact secrets).

Feature requests
- Open an issue describing the use-case and high-level design. Small, focused PRs are easier to review.

Pull requests
- Fork the repository and create topic branches per change.
- Keep PRs small and focused. Add tests when adding behavior (the repo uses pytest for Python tests).
- Run `make init` and `make plan` in `examples/terraform` to ensure Terraform changes are valid.
- Make sure the code is formatted; run `terraform fmt` for Terraform files.

Security
- Do NOT commit secrets or private keys to the repository. Use a secrets manager or repository secrets for CI.
- If you discover a security vulnerability, open a private issue and mark it as a security report.

Style and code
- Follow existing styles in the repo. Keep modules composable and avoid provider-specific assumptions in module code.

License
- Contributions will be licensed under the project's MIT license.

Thank you — maintainers will review and respond to PRs as time allows.
