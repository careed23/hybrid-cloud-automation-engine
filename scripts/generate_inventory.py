#!/usr/bin/env python3
"""
Generate an Ansible inventory file from Terraform outputs.

Usage:
  python scripts/generate_inventory.py --tfdir examples/terraform --out ansible/inventory.tf.ini

The script expects the Terraform root to have outputs named:
  - aws_instance_public_ip
  - oci_instance_public_ip

It will create an inventory with a `[vpn_hosts]` group and sensible `ansible_user` per provider.
"""

import argparse
import json
import subprocess
import sys
from pathlib import Path


def run_terraform_output(tfdir: Path):
    cmd = ["terraform", "output", "-json"]
    try:
        proc = subprocess.run(cmd, cwd=str(tfdir), capture_output=True, text=True, check=True)
    except subprocess.CalledProcessError as e:
        print(f"Error running {' '.join(cmd)} in {tfdir}: {e}\n{e.stdout}\n{e.stderr}")
        sys.exit(2)
    try:
        return json.loads(proc.stdout)
    except Exception as e:
        print("Failed to parse terraform output -json:", e)
        print(proc.stdout)
        sys.exit(3)


def extract_ip(outputs, key):
    # terraform output -json returns objects where value is nested under 'value'
    if key not in outputs:
        return ""
    v = outputs[key].get('value')
    if v is None:
        return ""
    # allow lists, maps, or scalar
    if isinstance(v, list) and len(v) > 0:
        return v[0]
    if isinstance(v, str):
        return v
    return str(v)


def build_inventory(tfdir: Path, outputs):
    aws_ip = extract_ip(outputs, 'aws_instance_public_ip')
    oci_ip = extract_ip(outputs, 'oci_instance_public_ip')

    lines = []
    lines.append('[vpn_hosts]')
    if aws_ip:
        lines.append(f"aws-vpn-host ansible_host={aws_ip} ansible_user=ubuntu")
    else:
        print('Warning: aws_instance_public_ip not found in terraform outputs or empty')
    if oci_ip:
        lines.append(f"oci-vpn-host ansible_host={oci_ip} ansible_user=opc")
    else:
        print('Warning: oci_instance_public_ip not found in terraform outputs or empty')

    lines.append('\n[all:vars]')
    lines.append('ansible_python_interpreter=/usr/bin/python3')
    return '\n'.join(lines) + '\n'


def main():
    parser = argparse.ArgumentParser(description='Generate Ansible inventory from Terraform outputs')
    parser.add_argument('--tfdir', type=str, default='examples/terraform', help='Path to Terraform root')
    parser.add_argument('--out', type=str, default='ansible/inventory.tf.ini', help='Output inventory file')
    args = parser.parse_args()

    tfdir = Path(args.tfdir).resolve()
    if not tfdir.exists():
        print('Terraform directory does not exist:', tfdir)
        sys.exit(1)

    outputs = run_terraform_output(tfdir)
    inv = build_inventory(tfdir, outputs)

    out_path = Path(args.out)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(inv)
    print(f'Wrote inventory to {out_path}\n')
    print(inv)


if __name__ == '__main__':
    main()
