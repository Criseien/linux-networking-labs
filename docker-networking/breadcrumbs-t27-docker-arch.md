# T27 Docker Internals — Breadcrumbs (Mar 26 2026)

## concept: none mode
- `--network none` = network namespace with no veth pair. Only `lo` inside.
- When to use: workloads that only read/write files (compilers, image processors).
  It's a **security** decision, not a generic testing default.
- When NOT to use: any app that serves traffic.

## concept: Docker architecture
- Full chain: `docker CLI → dockerd → containerd → containerd-shim → runc → kernel`
- dockerd = general manager (images, networks, volumes). Never touches kernel directly.
- containerd = container lifecycle. Pulls image, prepares filesystem, starts/stops.
- containerd-shim = stays alive per container. That's why `systemctl stop docker`
  does NOT kill running containers.
- runc = only layer that talks to the kernel. Creates namespaces + cgroups. Exits after.

## trap: stopping docker does not kill running containers
- runc exits after creating the container.
- containerd-shim keeps the process alive.
- You can restart dockerd in production without downtime.

## trap: "not found in PATH" is not always a PATH problem
- If binary exists and is in PATH but still not found → check permissions first.
- `ls -la /usr/bin/runc` before touching PATH.
- Correct fix: `chmod 755 /usr/bin/runc` — minimal and surgical.
- Wrong fix: reinstalling containerd.io when the binary just has bad permissions.

## key commands: broken chain diagnosis
```bash
journalctl -xeu docker.service   # high-level error
journalctl -u containerd          # go deeper if needed
crictl ps                         # talks directly to containerd, bypasses dockerd
ls -la /usr/bin/runc              # verify binary permissions
```

## decision: crictl vs docker
- `docker ps` → goes through dockerd → containerd
- `crictl ps` → goes directly to containerd (what K8s uses)
- On a K8s node without Docker: only crictl exists. kubelet talks to containerd via CRI.

## decision: chmod vs reinstall runc
- chmod: surgical fix, seconds. Use when binary exists but has wrong permissions.
- reinstall containerd.io: use when binary is corrupted.

## status: T27 partial — pending subtopics
- overlay/VXLAN (awareness, read docs.docker.com)
- Dockerfile basics (solo lab)
- Registries (terminal practice)
