# breadcrumbs — find & text processing (12 Mar 2026)

## key command
find /var/log -type f -mtime -1 -exec grep -i "error" {} + > /tmp/errores.txt

## traps
- awk: condition goes BEFORE the block → awk '$3 > 1000 {print $1, $3}'
  if placed inside → '$3 > 1000' is interpreted as output redirection
- -mtime 0 = since midnight (not real 24h) → use -mtime -1 in incidents
- find -exec grep -l → file names only
  find -exec grep    → full matching lines (no -l flag)

## decision
find = filesystem metadata (name, time, size, permissions)
grep = content inside the file
never the other way around