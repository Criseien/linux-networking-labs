### What this is
A Bash utility for automated log triage. Scans `*.log` files in a target directory, reports total line counts, and surfaces error frequency — useful for quick health checks on nodes or services that don't export metrics natively.

### Why it matters for Platform Engineering
When a node goes `NotReady` or a legacy service degrades silently, you need fast triage before reaching for Datadog or Loki. This script replicates the core of what those tools do at the file level:

- Audit `/var/log/pods/` or `/var/log/containers/` on bare metal nodes
- Wrap into a CronJob or recovery sidecar for services without native metric export
- Baseline for MTTR automation in constrained environments

### Concepts demonstrated

- Defensive scripting: `set -e` fail-fast + semantic exit codes
- stdin redirection (`< file`) vs argument passing — avoids filename noise in output
- `grep -c` for direct match counting — eliminates unnecessary `wc -l` pipe
- Modular design: functions + single-loop iteration for maintainability

### Usage
Requires elevated permissions to read system logs:
```
bashchmod +x log-counter.sh
sudo ./log-counter.sh  # scans /var/log/*.log by default
```
Expected output: one line per file showing total lines and error count.