#!/usr/bin/env python3
"""
Simple health check for VPN tunnel connectivity.
Usage:
  python scripts/health_check.py --host 10.100.0.2 --port 22 --timeout 5 --webhook https://hooks.example.com/...

The script attempts a TCP connect to the target host:port to validate the tunnel path.
It can be run as a cron job or adapted for Lambda (use environment variables for configuration).
"""

import argparse
import socket
import sys
import time
import json

try:
    import requests
except Exception:
    requests = None


def check_tcp_connect(host: str, port: int, timeout: float = 5.0) -> bool:
    """Attempt a TCP connection to host:port within timeout seconds.
    Returns True if connection succeeded, False otherwise.
    """
    try:
        with socket.create_connection((host, port), timeout=timeout) as s:
            return True
    except Exception:
        return False


def send_alert(webhook: str, message: str):
    if not webhook:
        print('ALERT:', message)
        return
    if requests is None:
        print('requests not installed; cannot send webhook. ALERT:', message)
        return
    payload = {"text": message}
    try:
        r = requests.post(webhook, json=payload, timeout=5)
        r.raise_for_status()
        print('Sent alert to webhook')
    except Exception as e:
        print('Failed to send webhook alert:', e)


def main():
    parser = argparse.ArgumentParser(description='VPN tunnel health check')
    parser.add_argument('--host', required=True, help='Target host/IP to test (internal endpoint over tunnel)')
    parser.add_argument('--port', type=int, default=22, help='TCP port to test (default 22)')
    parser.add_argument('--timeout', type=float, default=5.0, help='Connection timeout in seconds')
    parser.add_argument('--retries', type=int, default=2, help='Number of retries before alert')
    parser.add_argument('--webhook', default='', help='Optional webhook URL to post alerts')
    args = parser.parse_args()

    success = False
    for attempt in range(args.retries + 1):
        ok = check_tcp_connect(args.host, args.port, timeout=args.timeout)
        print(f'Attempt {attempt+1}/{args.retries+1}: connect to {args.host}:{args.port} -> {ok}')
        if ok:
            success = True
            break
        time.sleep(1)

    if not success:
        msg = f'VPN health check failed to reach {args.host}:{args.port} after {args.retries+1} attempts'
        send_alert(args.webhook, msg)
        sys.exit(2)
    else:
        print('VPN health check OK')
        sys.exit(0)


if __name__ == '__main__':
    main()
