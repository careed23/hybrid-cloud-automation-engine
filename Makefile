# Makefile for common tasks
TF_DIR=examples/terraform
PYTHON=python

.PHONY: help init plan apply destroy gen-inventory deploy

help:
	@echo "Makefile targets:"
	@echo "  init           - terraform init in $(TF_DIR)"
	@echo "  plan           - terraform plan in $(TF_DIR) (writes plan.tfplan)"
	@echo "  apply          - terraform apply (requires plan.tfplan or uses -auto-approve)"
	@echo "  destroy        - terraform destroy in $(TF_DIR)"
	@echo "  gen-inventory  - run scripts/generate_inventory.py against $(TF_DIR)"
	@echo "  deploy         - run scripts/deploy_and_inventory.ps1 on Windows or run deploy locally"

init:
	cd $(TF_DIR) && terraform init

plan:
	cd $(TF_DIR) && terraform plan -out=plan.tfplan

apply:
	cd $(TF_DIR) && terraform apply -auto-approve

destroy:
	cd $(TF_DIR) && terraform destroy -auto-approve

gen-inventory:
	$(PYTHON) ./scripts/generate_inventory.py --tfdir $(TF_DIR) --out ansible/inventory.tf.ini

deploy:
	@echo "Use scripts/deploy_and_inventory.ps1 on Windows, or run 'make init && make apply && make gen-inventory'"
	@echo "This target is a reminder; do not run automated apply in CI without reviewing costs and credentials."

demo:
	@echo "Generating demo GIF (scripts/make_demo_gif.py)"
	$(PYTHON) ./scripts/make_demo_gif.py || (echo "Failed to create demo GIF. Ensure Pillow is installed (pip install -r requirements.txt)" && exit 1)
	@echo "Demo GIF created at docs/demo.gif"
