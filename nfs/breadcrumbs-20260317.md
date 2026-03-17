# NFS — Breadcrumbs 2026-03-17

## Traps
- Use exact IP, not subnet: `127.0.0.1` not `127.0.0.1/24` — /24 on loopback
  works by coincidence but authorizes unintended IPs
- `exportfs -r` vs `exportfs -a` — `-r` resyncs (removes stale exports),
  `-a` only adds. Always use `-r` after editing /etc/exports
- `no_root_squash` required for K8s PVs — kubelet mounts volumes as root,
  without this flag mount succeeds but writes fail

## Key commands
- `showmount -e <ip>` — show what server is currently exporting (live state)
- `exportfs -r` — reload exports without restarting the service
- `exportfs -v` — show active exports with all options
- `mount -t nfs <ip>:/path /mnt/point` — temporary mount

## Decision points
- `exportfs -r` vs `systemctl restart nfs-server`: use `-r` — hot reload,
  no disruption to active clients. Restart only if service is inconsistent
- dedicated vs shared server: NFS uses the full server disk — dedicated
  server with LVM is the production pattern

## Missed in solo lab
- persistent mount via fstab: `<ip>:/path  /mnt/point  nfs  defaults  0 0`

## K8s connection
- NFS-type PV = exactly this. ReadWriteMany = multiple pods mounting same export
- Without quotas, multiple pods can fill the server disk without knowing it