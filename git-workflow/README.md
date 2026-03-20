# Git Workflow

## Scenario

A health check script needs to be added to the repository without
pushing directly to `main`. The change must go through a feature branch
and be merged via Pull Request — replicating a standard GitOps review cycle.

## Workflow Practiced

```
git checkout -b feature/health-check     # create and switch to feature branch
# make changes
git add <files>
git commit -m "add health check script"
git push origin feature/health-check     # push branch to remote
# open PR via GitHub UI
# review + merge
git checkout main && git pull            # sync local main after merge
```

## The Trap

Pushed to `main` directly instead of the feature branch on the first attempt.
This is caught before merge by verifying the current branch before pushing:

```bash
git branch          # shows current branch with *
git status          # also shows branch name in the first line
```

Fix: switch to the correct branch and push there instead.

```bash
git checkout -b feature/health-check
git push origin feature/health-check
```

## Key Commands

```bash
# Create and switch to a new branch
git checkout -b feature/health-check

# Verify current branch
git branch
git status

# Stage specific files (avoid staging unintended changes)
git add <file>

# Push branch to remote
git push origin feature/health-check

# Sync local main after a merge
git checkout main
git pull origin main

# Resolve a merge conflict
git pull origin main    # triggers conflict markers in files
# edit conflict markers manually
git add <resolved-files>
git commit
```

## Concepts

**Branch per feature:** Each change lives in an isolated branch. main stays
stable. The PR is the gate between work-in-progress and production state.

**Staging area:** The index is a deliberate control point. `git add <file>`
means choosing exactly what goes into the next commit — not just "save all".
This matters when a working session touched multiple files but only one
change is ready to ship.

**Merge conflicts:** When two branches modify the same line, git cannot
auto-merge. Conflict markers (`<<<<<<<`, `=======`, `>>>>>>>`) appear in
the file. Resolution: edit the file to the correct final state, remove
the markers, `git add`, and commit.

## K8s Connection

GitOps workflows (ArgoCD, Flux) monitor a Git branch — typically `main` —
and apply whatever is in that branch to the cluster. The branch-per-feature +
PR-before-main pattern is not just a code hygiene practice: in GitOps, a
direct push to `main` is a direct deployment to production. The PR is
the cluster's change management gate.
