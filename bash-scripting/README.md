# bash-scripting

## log-counter.sh

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
bash chmod +x log-counter.sh
sudo ./log-counter.sh  # scans /var/log/*.log by default
```
Expected output: one line per file showing total lines and error count.

## triage.sh

### What this is

A defensive Bash utility for automated log triage. It receives a target directory and a search pattern, scanning all *.log files to report total lines and pattern matches. Crucially, it handles file permission constraints safely, using semantic exit codes to explicitly warn operators when a log file is inaccessible, preventing incomplete data analysis.

### Why it matters for Platform Engineering

During an incident, silent failures are dangerous. If multiple nodes are facing errors and an operator (or automated triage sidecar) runs a diagnostic script, silently skipping unreadable logs (e.g., due to strict 000 permissions) creates false confidence. This script guarantees that if you don't have the full picture, the tool warns you explicitly and exits with code 2, preventing false negatives in high-SLA environments.

### Concepts demonstrated

- **Argument Validation:** Enforces required parameters (<log_path> and <pattern>) and validates directory existence before execution.

- **Negative Flow Handling:** Validates file read permissions (-r) before attempting to process, avoiding silent standard errors.

- **Semantic Exit Codes:** Returns 0 for a fully processed run, 1 for bad inputs, and 2 if the report is incomplete due to permission limitations.

### Usage

Requires two parameters to run:

```Bash
chmod +x triage.sh
./triage.sh <log_path> <pattern>

# Example:
./triage.sh /var/log/appservice ERROR
```