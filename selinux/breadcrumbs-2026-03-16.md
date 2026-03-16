# Breadcrumbs — 2026-03-16

## step: natural SELinux diagnostic flow
journalctl -u nginx → Permission denied → ls -l (dot = SELinux active) →
ls -Z → default_t on /data/web → semanage → restorecon → curl localhost → test

## key command: assign label to custom directory
semanage fcontext -a -t httpd_sys_content_t "/data/web(/.*)?"
restorecon -Rv /data/web

## trap: restorecon on custom directory without semanage first
policy does not know /data/web → restorecon assigns default_t → still blocked
semanage first teaches the policy what label belongs there

## decision: semanage vs restorecon
semanage → custom directory, policy does not know the path
restorecon → standard directory, policy already knows what label should be there

## trap: -mtime -1 vs -mtime 0
-mtime -1 → last 24 hours
-mtime 0  → today only (same calendar day)
under pressure used -mtime 0 when looking for last 24h

## trap: awk with pipe does not take file at the end
grep -i "error" file.log | awk -F: '{print $3}'            ← correct
grep -i "error" file.log | awk -F: '{print $3}' file.log   ← ignores pipe, processes all lines

## trap: dig vs nsswitch
dig bypasses nsswitch.conf → goes directly to nameserver
system applications use getaddrinfo → respect nsswitch order
if nsswitch only has "files" → app cannot resolve even if dig works fine