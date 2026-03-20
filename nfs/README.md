# NFS — Network File System

## Scenario

A shared storage server needs to export `/srv/shared` so that application
nodes can mount it and write logs centrally. The mount must survive reboots
and support multiple simultaneous clients.

Secondary requirement: the setup must be compatible with Kubernetes PersistentVolumes
(kubelet mounts as root — standard export options will silently break writes).

## Key Commands

```bash
# Server — verify what is currently exported (live state)
showmount -e <server-ip>

# Server — reload exports without restarting the service
exportfs -r

# Server — show active exports with all options
exportfs -v

# Client — mount an NFS share temporarily
mount -t nfs <server-ip>:/srv/shared /mnt/point

# Client — verify the mount is active
df -h /mnt/point
mount | grep nfs
```

## /etc/exports Configuration

```
/srv/shared  192.168.1.0/24(rw,sync,no_subtree_check,no_root_squash)
```

Key options:
- `rw` — read/write access
- `sync` — write to disk before acknowledging (safer than `async`)
- `no_subtree_check` — eliminates subtree permission check overhead; reduces errors on renames
- `no_root_squash` — required for K8s (see below)

## Persistent Mount (fstab)

```
<server-ip>:/srv/shared  /mnt/point  nfs  defaults  0 0
```

Add to `/etc/fstab` on each client. Without this, the mount is lost after reboot.
This was the missed step in the solo lab.

## Traps

### Use exact IP, not subnet on loopback

```
/srv/shared  127.0.0.1(rw,...)      # correct for loopback testing
/srv/shared  127.0.0.1/24(rw,...)   # authorizes unintended IPs — /24 on loopback
                                     # appears to work but is a security bug
```

### `exportfs -r` vs `exportfs -a`

| Command | Behavior |
|---|---|
| `exportfs -a` | Adds new exports from `/etc/exports` |
| `exportfs -r` | Re-syncs — adds new and removes stale exports |

Always use `exportfs -r` after editing `/etc/exports`. Using `-a` leaves
stale entries active from the previous configuration.

### `exportfs -r` vs `systemctl restart nfs-server`

Use `exportfs -r` — it's a hot reload with no disruption to active clients.
Only restart the service if the NFS daemon itself is in an inconsistent state.

### `no_root_squash` for Kubernetes PersistentVolumes

By default, NFS squashes root (`root_squash`): any request arriving as UID 0
is remapped to `nobody`. kubelet mounts volumes as root, so without
`no_root_squash`, the mount succeeds but all writes fail silently.

```bash
# Symptom: pod can see the mount but writes fail
# Fix: add no_root_squash to /etc/exports and reload
exportfs -r
```

## Decision Points

**Dedicated vs shared NFS server:** NFS uses the full server disk by default.
Without quotas, multiple pods can fill the server disk without knowing it.
Production pattern: dedicated server with LVM volumes and per-export quotas.

## K8s Connection

An NFS-type PersistentVolume is exactly this setup. `ReadWriteMany` access mode
means multiple pods can mount the same NFS export simultaneously — this is one
of the few storage backends that supports RWX natively.

```yaml
# PV definition maps directly to the NFS export
spec:
  nfs:
    server: 192.168.1.10
    path: /srv/shared
  accessModes:
    - ReadWriteMany
```

Without quotas and `no_root_squash` configured correctly at the NFS level,
K8s storage issues are invisible until the disk fills or writes silently fail.
