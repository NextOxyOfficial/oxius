"""Read-only/admin SSH command runner for the adsyclub server.

No secrets are stored in this file. Credentials come from environment:
  SRV_HOST, SRV_USER, SRV_PASS
The command to run is passed as the first CLI argument (or via stdin).
"""
import os
import sys
import paramiko

sys.stdout.reconfigure(encoding="utf-8", errors="replace")

HOST = os.environ["SRV_HOST"]
USER = os.environ["SRV_USER"]
PASS = os.environ["SRV_PASS"]

if len(sys.argv) > 1:
    cmd = sys.argv[1]
else:
    cmd = sys.stdin.read()

cli = paramiko.SSHClient()
cli.set_missing_host_key_policy(paramiko.AutoAddPolicy())
cli.connect(HOST, username=USER, password=PASS, timeout=30,
            look_for_keys=False, allow_agent=False)
_in, out, err = cli.exec_command(cmd, timeout=180)
o = out.read().decode("utf-8", "ignore")
e = err.read().decode("utf-8", "ignore")
sys.stdout.write(o)
if e.strip() and "password for" not in e.lower():
    sys.stdout.write("\n[stderr]\n" + e)
cli.close()
