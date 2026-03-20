# iptables Chains & Rules

## Scenario

A network namespace is running a 3-backend DNAT load balancer. Traffic is flowing
from the namespace to the internet but the FORWARD chain is silently dropping
packets under specific conditions. tcpdump shows packets leaving the source
but never arriving at the destination.

Your job: use tcpdump to pinpoint at which hop the packet is lost, identify
the iptables rule responsible, and restore connectivity without flushing the
entire ruleset.

## Tables & Chains — The Mental Model

iptables has three main tables. Each table contains specific chains.

| Table | Purpose | Chains |
|---|---|---|
| `filter` | Allow/deny traffic (**default table**) | INPUT, FORWARD, OUTPUT |
| `nat` | Rewrite source/destination addresses | PREROUTING, POSTROUTING, OUTPUT |
| `mangle` | Modify packet headers (TTL, DSCP) | All chains |

**Chain traversal depends on traffic direction:**

```
Incoming packet → PREROUTING (nat) → routing decision
  ├─ for this host   → INPUT (filter) → local process
  └─ for forwarding  → FORWARD (filter) → POSTROUTING (nat) → out

Outgoing packet → OUTPUT (filter/nat) → POSTROUTING (nat) → out
```

The critical distinction: **FORWARD processes traffic crossing between
interfaces** (namespace ↔ internet, container ↔ host). INPUT only processes
traffic destined for the host itself.

## Diagnosis Flow

```bash
# 1. Capture on the outgoing interface — see if packets leave the host
tcpdump -i eth0 host 10.10.0.2

# 2. Capture inside the namespace — see if packets arrive at the source
ip netns exec app-ns tcpdump -i veth0

# 3. If packets leave but don't arrive — FORWARD chain is blocking
iptables -L FORWARD -n -v --line-numbers

# 4. Check NAT rules
iptables -t nat -L -n -v
```

## Rule Management

```bash
# Add rule (append to end of chain)
iptables -A FORWARD -s 10.10.0.0/24 -j ACCEPT

# Insert rule (at specific position)
iptables -I FORWARD 1 -s 10.10.0.0/24 -j ACCEPT

# Delete rule by position
iptables -D FORWARD 1

# Delete rule by full spec
iptables -D FORWARD -s 10.10.0.0/24 -j ACCEPT

# List with line numbers (critical for -D by position)
iptables -L FORWARD -n --line-numbers
```

## Custom Chains & Logging

Custom chains keep ruleset organized and enable reusable logic:

```bash
# Create a custom chain
iptables -N LOG-AND-DROP

# Add rules to it
iptables -A LOG-AND-DROP -j LOG --log-prefix "DROPPED: " --log-level 4
iptables -A LOG-AND-DROP -j DROP

# Jump to custom chain from a main chain
iptables -A FORWARD -s 10.10.0.0/24 -j LOG-AND-DROP
```

Log output appears in `journalctl -k` (kernel log).

## DNAT Load Balancing

DNAT in PREROUTING distributes traffic across backends using statistic module:

```bash
# 3-backend load balancer (decreasing fractions)
iptables -t nat -A PREROUTING -p tcp --dport 80 \
  -m statistic --mode random --probability 0.33 -j DNAT --to-destination 10.10.0.2:80

iptables -t nat -A PREROUTING -p tcp --dport 80 \
  -m statistic --mode random --probability 0.50 -j DNAT --to-destination 10.10.0.3:80

iptables -t nat -A PREROUTING -p tcp --dport 80 \
  -j DNAT --to-destination 10.10.0.4:80
```

The probabilities are decreasing fractions — not equal thirds — because each
rule only applies to packets not already matched by previous rules.

## The Trap: `-D` Syntax

`iptables -D` requires either the exact rule spec or the line number:

```bash
iptables -D FORWARD 1                      # delete by position — correct
iptables -D FORWARD -s 10.0.0.0/24 -j DROP  # delete by spec — correct
iptables -D FORWARD DROP                   # invalid — not valid syntax
```

Attempting `iptables -D FORWARD DROP` fails silently or with a confusing error.
Always use `iptables -L --line-numbers` first to confirm position before deleting.

## MASQUERADE vs SNAT

| | MASQUERADE | SNAT |
|---|---|---|
| **Use when** | Dynamic IP (DHCP, cloud) | Static IP |
| **Flag** | `-j MASQUERADE` | `-j SNAT --to-source <ip>` |
| **Performance** | Slightly slower (looks up IP per packet) | Faster (IP hardcoded) |

```bash
# MASQUERADE (dynamic — IP resolved per packet)
iptables -t nat -A POSTROUTING -s 10.10.0.0/24 -o eth0 -j MASQUERADE

# SNAT (static — IP hardcoded)
iptables -t nat -A POSTROUTING -s 10.10.0.0/24 -o eth0 -j SNAT --to-source 192.168.1.10
```

## Key Commands

```bash
# Inspect all tables
iptables -L -n -v                         # filter table (default)
iptables -t nat -L -n -v                  # nat table
iptables -t mangle -L -n -v              # mangle table

# Save and restore rules
iptables-save > /etc/iptables/rules.v4
iptables-restore < /etc/iptables/rules.v4

# Flush a specific chain (careful in production)
iptables -F FORWARD

# Check ip_forward (required for FORWARD to work)
sysctl net.ipv4.ip_forward
sysctl -w net.ipv4.ip_forward=1
```

## K8s Connection

kube-proxy (iptables mode) creates hundreds of rules in `filter` and `nat` tables
using the exact same primitives practiced here. Each Kubernetes Service becomes:

- A custom chain in `nat`: `KUBE-SVC-<hash>` — the load balancer
- Per-endpoint chains: `KUBE-SEP-<hash>` — the DNAT targets
- PREROUTING and OUTPUT rules jumping to `KUBE-SERVICES`

When a pod can't reach a Service, the debugging path is identical:
`iptables -t nat -L -n -v | grep <service-ip>` to trace whether the DNAT
rules exist and are matching. The FORWARD chain gap from this lab is the same
gap that causes cross-node pod communication failures when ip_forward is disabled.
