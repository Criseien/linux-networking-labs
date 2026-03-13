# linux-networking-labs

Hands-on labs documenting my journey from Linux networking primitives
to Kubernetes networking internals.

Every lab here connects to a real Platform Engineering scenario —
not exercises for the sake of exercises.

## Why this exists

Most engineers know `kubectl apply`. Few can debug traffic between pods
at the iptables/CNI level when things break in production.

These labs are building that second skill set.

## Labs

### ✅ Completed

| Topic | Lab | K8s Connection |
| --- | --- | --- |
| Network Namespaces | [namespaces/](namespaces/) *(docs pending)* | How pods are isolated |
| iptables Chains | [iptables/](iptables/) *(docs pending)* | kube-proxy under the hood |
| firewalld / nftables | [firewalld/](firewalld/) *(docs pending)* | Node firewall vs NetworkPolicies |
| DNS Resolution | [dns/](dns/) *(docs pending)* | CoreDNS, pod DNS policy |
| NAT & Masquerading | [nat/](nat/) *(docs pending)* | Pod-to-internet, NodePort DNAT |
| File Permissions & ACLs | [file-permissions/](file-permissions/) | Volume permissions, security contexts |
| SSH Hardening | [ssh-hardening/](ssh-hardening/) | Node access, bastion hosts |
| Scheduled Jobs (cron + systemd timers) | [scheduled-jobs/](scheduled-jobs/) | CronJobs, cert rotation timers |
| Bash Scripting | [bash-scripting/](bash-scripting/) | Node triage automation, CronJob scripts |
| Package Management (dnf/rpm) | [package-management/](package-management/) | Installing CNI plugins, kubelet, containerd |
| find & Text Processing | [find-text-processing/](find-text-processing/) | Log analysis, config file grep |

### 🔄 In Progress

| Topic | Status |
| --- | --- |
| SELinux | Lab pending — returning after warm-up degradation |
| Boot Process & GRUB | Lab pending (UTM console setup) |

### 📋 Roadmap

| Topic | Phase |
| --- | --- |
| Container internals (no Docker) | F1.5 |
| Docker networking internals | F2 |
| K8s networking model | F2 |
| CNI plugins (Flannel, Calico, Cilium) | F3 |
| kube-proxy iptables mode | F3 |
| Network Policies | F3 |
| Cilium + eBPF deep dive | F4 |

## Stack

- AlmaLinux 9 on Proxmox (Intel N100)
- Tools: tcpdump, iptables, ip, ss, nsenter, firewall-cmd, bash

## Blog

Deep-dive articles on everything here: [icris.me](https://icris.me)

---

*Building K8s Networking expertise from the ground up.*  
*Platform Engineer specializing in networking & troubleshooting.*
```

---
