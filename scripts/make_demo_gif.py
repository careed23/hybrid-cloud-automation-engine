#!/usr/bin/env python3
"""
Create a simple animated GIF that demonstrates the PoC workflow as a short sequence of textual frames.
This is useful as a quick visual for the README without recording the screen.
"""
from PIL import Image, ImageDraw, ImageFont
from pathlib import Path

OUT = Path(__file__).resolve().parents[1] / 'docs' / 'demo.gif'
FRAMES = []
W, H = 900, 240
BG = (250, 250, 250)
TEXT_COLOR = (20, 20, 20)

lines_list = [
    ["hybrid-cloud-automation-engine", "PoC workflow demo"],
    ["1) terraform init && terraform apply", "Creates VPC/VCN and instances"],
    ["2) Generate inventory", "scripts/generate_inventory.py -> ansible/inventory.tf.ini"],
    ["3) ansible-playbook ansible/site.yml", "Installs WireGuard and exchanges keys"],
    ["4) scripts/health_check.py", "Run as cron or Lambda to watch tunnel health"],
]

font = None
try:
    # Try to load a reasonably present font
    font = ImageFont.truetype("DejaVuSans-Bold.ttf", 20)
except Exception:
    font = ImageFont.load_default()

for lines in lines_list:
    img = Image.new('RGB', (W, H), BG)
    draw = ImageDraw.Draw(img)
    # Title
    draw.text((24, 18), lines[0], fill=TEXT_COLOR, font=font)
    # Subtitle / detail
    draw.text((24, 70), lines[1], fill=TEXT_COLOR, font=font)
    FRAMES.append(img)

# Save as animated GIF
OUT.parent.mkdir(parents=True, exist_ok=True)
FRAMES[0].save(OUT, save_all=True, append_images=FRAMES[1:], duration=1200, loop=0)
print(f'Wrote demo GIF to: {OUT}')
