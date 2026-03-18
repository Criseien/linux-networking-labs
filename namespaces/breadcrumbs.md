## Integration Lab #1 — namespace-forward-drop

- Symptom: app-ns could not reach internet, but host was reachable from namespace
- Diagnosis: ip netns list → ip -br a → ping host↔ns → ip r → ip_forward → iptables -L
- Root cause: DROP rule in FORWARD chain blocking 10.10.0.0/24 egress
- Fix: iptables -D FORWARD 1
- Gap: iptables -D syntax — 4 attempts before correct command
- Key insight: firewalld masquerade:no ≠ no MASQUERADE in the system. They are separate layers.
- FORWARD processes traffic crossing interfaces. INPUT processes traffic destined to the host. That distinction is the root of this lab.
```