## Proactively Suggest Git Commit Checkpoints

When working in a git repo, proactively notice when a unit of work has reached a natural commit checkpoint and offer to commit it. Don't wait to be asked — surface the suggestion yourself.

### What counts as a good checkpoint

- A **logical unit of work is complete**: a feature, a bug fix, a self-contained refactor step — not a half-finished change.
- The code is in a **buildable / green state**: it compiles, and (where tests exist for the affected path) the relevant tests pass. A commit should be a safe point to return to.
- **Before** starting a distinct next unit of work, or before a large / risky change that's worth having a rollback point in front of.

### What this rule is NOT

- **Not a license to commit.** The actual `git commit` still requires explicit per-operation consent — see `git-write-consent.md`. The checkpoint suggestion you raise *is* that consent ask: phrase it specifically, e.g. *"This is a good checkpoint — the X refactor is done and `dotnet build` is green. Want me to commit it as `<one-line summary>`?"*
- **Not a nag after every edit.** Offer at meaningful boundaries, not on every file write. If several small edits add up to one unit of work, wait for the unit, then offer once.

### Why

Frequent, build-green commits keep history bisectable and give cheap rollback points before risky work. Tom owns the commit decision (per `git-write-consent.md`), so the most useful thing I can do is notice the checkpoint and offer — turning a later *"I should have committed back there"* into a prompt at the right moment.

### How to apply

- **Only in git repos.** Confirm it's a repo, and not mid-rebase / detached-HEAD, before offering.
- **Tie the offer to a concrete, verified state**: name the unit of work that's done and the build/test signal that's green. If you haven't actually verified the build, say so rather than implying it's green.
- **One offer per checkpoint.** If Tom declines or says "later," don't re-ask for the same unit — wait for the next checkpoint.
