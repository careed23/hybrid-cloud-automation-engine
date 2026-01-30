import threading
import socket
import time
import subprocess
import sys
from pathlib import Path

import pytest


def _start_tcp_server(port, ready_event):
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    s.bind(('127.0.0.1', port))
    s.listen(1)
    ready_event.set()
    try:
        conn, _ = s.accept()
        conn.close()
    finally:
        s.close()


def test_health_check_connects(tmp_path):
    # Start a temporary TCP server
    port = 22022
    ready = threading.Event()
    t = threading.Thread(target=_start_tcp_server, args=(port, ready), daemon=True)
    t.start()
    ready.wait(timeout=5)
    assert ready.is_set(), "Server did not start"

    script = Path(__file__).resolve().parents[1] / 'scripts' / 'health_check.py'
    assert script.exists(), 'health_check.py not found'

    # Run the health check script against the temp server
    cmd = [sys.executable, str(script), '--host', '127.0.0.1', '--port', str(port), '--timeout', '2', '--retries', '0']
    proc = subprocess.run(cmd, capture_output=True, text=True)
    print(proc.stdout)
    print(proc.stderr)
    assert proc.returncode == 0, f'health_check failed: {proc.stderr}'
