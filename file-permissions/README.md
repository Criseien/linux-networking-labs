# File Permissions & ACLs

## Scenario
User `deployer` needs write access to `/srv/configs` without being added 
to the owner group. Security team blocked group membership changes.

## Solution
ACLs — granular permissions for specific users without touching group membership.

## Key commands
- `setfacl -m u:deployer:rwx /srv/configs` — give directory access
- `setfacl -m d:u:deployer:rwx /srv/configs` — inherit ACL on new files
- `getfacl /srv/configs` — verify ACL

## The trap
Applying `setfacl` with wildcard (`configs/*`) affects files inside,
not the directory itself. You need `x` on the directory to enter it.

## K8s connection
Volume mount permissions, runAsUser, security contexts — same model,
different abstraction layer.