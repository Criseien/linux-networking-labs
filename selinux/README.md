# SELinux

## Scenario

nginx is running but returning permission errors when serving content from
a custom directory `/data/web`. The directory exists, ownership looks correct,
and standard Unix permissions are fine — but requests fail.

Your job: diagnose the SELinux label mismatch and restore access without
disabling SELinux or switching to permissive mode.

## Diagnosis Flow

```
journalctl -u nginx          # Permission denied in logs
→ ls -l /data/web            # trailing dot (.) = SELinux is active and has a label
→ ls -Z /data/web            # inspect the SELinux context
→ compare to /var/www/html   # reference directory with correct label
```

The dot `.` at the end of `ls -l` output is the indicator that SELinux has
a label on the file. Without it, SELinux is either disabled or the label is
the default unconfined type.

## Root Cause

`/data/web` was created manually and received `default_t` — a label SELinux
does not associate with any policy allowing nginx to read from it.
nginx's policy only permits reads from directories labeled `httpd_sys_content_t`.

## Fix

```bash
# 1. Teach the SELinux policy that /data/web should be httpd_sys_content_t
semanage fcontext -a -t httpd_sys_content_t "/data/web(/.*)?"

# 2. Apply the label to all existing files
restorecon -Rv /data/web

# 3. Verify
ls -Z /data/web
curl localhost
```

## The Critical Trap: Order Matters

Running `restorecon` **without** `semanage` first assigns `default_t` —
because the policy doesn't know what `/data/web` should be.
`restorecon` applies whatever the policy says is correct for that path.
For a custom path not in the policy, that means `default_t` — still broken.

**Always `semanage` first, then `restorecon`.**

## Decision: `semanage` vs `restorecon`

| Tool | Use when |
|---|---|
| `semanage fcontext` | Custom directory the policy doesn't know about |
| `restorecon` | Standard directory — policy already knows the correct label |

For anything under `/var/www/`, `/etc/nginx/`, or other well-known paths,
`restorecon` alone is sufficient. For custom paths like `/data/web` or
`/srv/app/`, always start with `semanage`.

## Additional Traps from This Lab

### `dig` vs system DNS resolution

```bash
dig app.internal            # bypasses nsswitch.conf → goes directly to nameserver
getent hosts app.internal   # uses nsswitch.conf → respects /etc/hosts order
```

If `dig` resolves but the application cannot, check `nsswitch.conf`.
If `nsswitch.conf` only has `files` (no `dns`), applications using
`getaddrinfo` will never reach the DNS server even if dig works fine.

### `awk` pipe rule

```bash
grep -i "error" file.log | awk -F: '{print $3}'           # correct — pipe to stdin
grep -i "error" file.log | awk -F: '{print $3}' file.log  # wrong — ignores pipe
```

When awk receives a filename argument after a pipe, it ignores stdin
entirely and processes all lines of the file instead.

## Key Commands

```bash
# Check SELinux status
getenforce
sestatus

# Inspect file labels
ls -Z /data/web
ls -Z /var/www/html          # reference for correct label

# Set policy for a custom path
semanage fcontext -a -t httpd_sys_content_t "/data/web(/.*)?"

# Apply labels
restorecon -Rv /data/web

# View all custom fcontext entries
semanage fcontext -l | grep /data

# Check SELinux denials in real time
ausearch -m avc -ts recent
journalctl -t setroubleshoot
```

## K8s Connection

Kubernetes `securityContext` fields (`runAsUser`, `fsGroup`, `seLinuxOptions`)
map directly to the SELinux label enforcement practiced here. When a pod is
denied access to a volume mount despite correct Unix permissions, the root cause
is often an SELinux label mismatch between the container's policy and the
host directory — the same failure mode and the same diagnostic flow.
