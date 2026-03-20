# find & Text Processing

## Scenario

A service has been degrading since last night. You need to surface all error
lines from log files modified in the last 24 hours across `/var/log`,
and identify which files are generating the most noise — without reading
every file manually.

## The Core Command

```bash
find /var/log -type f -mtime -1 -exec grep -i "error" {} + > /tmp/errores.txt
```

Breaks down as:
- `find /var/log -type f` — files only, skip directories
- `-mtime -1` — modified in the last 24 hours
- `-exec grep -i "error" {} +` — run grep across all found files in one invocation
- `> /tmp/errores.txt` — capture output for further analysis

## Decision: find vs grep

| Tool | Use for |
|---|---|
| `find` | Filesystem metadata — name, modification time, size, permissions |
| `grep` | Content inside files |

Never use `find` to match content, and never use `grep` to filter by file age.
They are complementary tools with non-overlapping responsibilities.

## Traps

### `-mtime -1` vs `-mtime 0`

| Flag | Matches |
|---|---|
| `-mtime 0` | Today only (since midnight of the current calendar day) |
| `-mtime -1` | Truly the last 24 hours |

Under incident pressure, `-mtime 0` can miss files modified before midnight.
Default to `-mtime -1` for incident triage.

### `-exec grep -l` vs `-exec grep`

```bash
find /var/log -type f -exec grep -l "error" {}  # returns filenames only
find /var/log -type f -exec grep    "error" {}  # returns matching lines
```

`-l` surfaces which files contain the pattern — useful for scoping.
Without `-l`, you get the actual lines — useful for triage.

### awk condition placement

The condition goes **before** the action block:

```bash
awk '$3 > 1000 {print $1, $3}'   # correct
awk '{$3 > 1000 print $1, $3}'   # wrong — syntax error
```

Placing the condition inside `{}` causes awk to interpret it as a
redirection attempt (`$3 > 1000` → redirect stdout to file named `1000`).

### awk with a pipe

```bash
grep -i "error" file.log | awk -F: '{print $3}'              # correct
grep -i "error" file.log | awk -F: '{print $3}' file.log     # wrong
```

When awk receives both stdin (via pipe) and a filename argument, it ignores
stdin and processes the file instead — producing unexpected results.
Never pass a filename to awk when using it at the end of a pipe.

## Key Commands

```bash
# Find files modified in the last 24h
find /var/log -type f -mtime -1

# Surface errors across recent files
find /var/log -type f -mtime -1 -exec grep -i "error" {} + > /tmp/errores.txt

# Which files contain errors (names only)
find /var/log -type f -mtime -1 -exec grep -l "error" {} +

# Count errors per file
find /var/log -type f -mtime -1 -exec grep -ic "error" {} + | sort -t: -k2 -rn

# Filter log lines by field value
awk '$3 > 1000 {print $1, $3}' access.log

# Extract specific field from grep output
grep -i "error" app.log | awk -F: '{print $3}'
```

## K8s Connection

This exact pattern applies to Kubernetes node troubleshooting:
`/var/log/pods/` and `/var/log/containers/` are the targets when a pod
is evicted or a node goes `NotReady`. The `find -mtime -1 -exec grep`
pattern is also the foundation for log-scraping sidecars and CronJob
triage scripts in environments without centralized logging (Loki, Datadog).
