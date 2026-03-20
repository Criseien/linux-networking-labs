# Network Namespaces

## Scenario

A network namespace (`app-ns`) is configured with a veth pair and a route to the host.
The namespace can reach the host, but traffic to the internet fails silently.

Your job: diagnose why `app-ns` cannot reach the internet despite the host having connectivity,
and fix the issue without rebuilding the namespace.

## Diagnosis Flow

```
ip netns list
→ ip -br a                  # verify interface state inside namespace
→ ping host ↔ namespace     # isolate the failure layer
→ ip r                      # check routing table inside namespace
→ sysctl net.ipv4.ip_forward  # check host forwarding
→ iptables -L FORWARD       # check for blocking rules
```

## Root Cause

A DROP rule in the FORWARD chain was blocking egress from `10.10.0.0/24`.
Traffic could reach the host (INPUT chain, unaffected) but could not cross
the veth interface boundary (FORWARD chain).

## Fix

```bash
iptables -D FORWARD 1      # delete rule by position
iptables -L FORWARD -n --line-numbers  # verify rule was removed
```

## The Trap

`iptables -D` syntax takes either a rule position (`-D FORWARD 1`) or
the full rule spec (`-D FORWARD -s 10.10.0.0/24 -j DROP`).
Using `-D FORWARD DROP` alone is not valid syntax — it took 4 attempts
to land on the correct command under pressure.

## Key Insight: FORWARD vs INPUT

| Chain | Processes traffic... |
|---|---|
| `INPUT` | Destined for the host itself |
| `FORWARD` | Crossing the host between interfaces (namespace ↔ internet) |

Namespace egress fails at FORWARD, not INPUT. This distinction is the root
of most namespace connectivity issues and maps directly to how kube-proxy
manages pod traffic routing.

## Separate Layers: firewalld vs iptables

`firewall-cmd --zone=public --query-masquerade` returning `no` does **not**
mean there is no MASQUERADE rule in the system. firewalld and raw iptables
rules are separate layers. A MASQUERADE rule inserted via `iptables -t nat`
persists independently of firewalld's state.

Always check both layers:
```bash
firewall-cmd --list-all           # firewalld state
iptables -t nat -L -n -v          # raw NAT table
```

## Key Commands

```bash
# Namespace inspection
ip netns list
ip netns exec app-ns ip -br a
ip netns exec app-ns ip r
ip netns exec app-ns ping 8.8.8.8

# Host forwarding
sysctl net.ipv4.ip_forward
sysctl -w net.ipv4.ip_forward=1   # enable if missing

# iptables inspection
iptables -L FORWARD -n --line-numbers -v
iptables -t nat -L -n -v

# Delete a rule by position
iptables -D FORWARD 1
```

## K8s Connection

Every Kubernetes pod runs in its own network namespace — this is the exact
primitive that provides pod-level network isolation. When `kubectl exec` into
a pod and ping fails, the diagnosis flow is identical: check the FORWARD chain,
check ip_forward, check CNI-inserted rules. kube-proxy manages FORWARD and
NAT rules at scale using the same iptables primitives practiced here.
