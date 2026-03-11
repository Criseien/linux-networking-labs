# T21 Package Management

## Key Commands
- `rpm -qi <pkg>`        → Version + Metadata (Audit).
- `dnf history info <ID>` → Origin Repository (Source of Trust).
- `rpm -V <pkg>`         → Binary Integrity (Verification).
- `rpm -ql <pkg>`        → Installed Files (Path Inventory).

## Trap
- `dnf repoquery --installed` → Returns `@System` (Unreliable for source tracking).
- `dnf history info`          → Actual source of truth for the repository.

## Scenario
**Vulnerability Response:** Use `rpm -qi` to validate the installed version and `dnf history info` to trace the originating repository.