# Breadcrumbs — T26 Git Workflow — 2026-03-19

## Steps
- Cloned repo, created `feature/health-check` branch
- Opened PR via GitHub UI, merged successfully

## Trap
- Pushed to `main` instead of branch — caught before merge
- Fix: `git push origin feature/health-check`

## Key Commands
- `git checkout -b feature/health-check`
- `git push origin feature/health-check`

## Decisions
- Branch per feature = isolated changes + PR review before main
- Staging area = control over what goes in each commit

## Concepts
- Merge conflicts: `git pull origin main` → edit markers → commit