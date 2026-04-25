## Git Write Operations Require Per-Operation Consent

Never execute a git operation that writes to the working tree, the repo, or a remote without asking Tom for explicit consent on that specific operation. Operations covered: `git add`, `git commit`, `git push` (including force pushes), `git tag`, `git rebase` (interactive or otherwise), `git reset --hard`, `git restore`, `git checkout -- <path>`, `git clean`, `git stash` apply/drop/pop, `git merge`, `git cherry-pick`, branch creation/deletion, and anything else that mutates state.

Read-only git operations don't need consent: `git status`, `git diff`, `git log`, `git show`, `git branch -v`, `git remote -v`, `git rev-parse`, etc.

### Each operation is its own decision

If Tom agreed to a commit earlier in the same conversation, that does **not** authorize a later commit. Ask again. The same applies to push, tag, rebase, and every other write operation. Phrasing for the ask should describe what's about to happen specifically — e.g., *"Want me to commit this as `<one-line summary>`?"* or *"Should I push these 3 commits to `origin/main`?"* — not a generic *"can I commit?"* that hides scope.

If a workflow needs several writes in sequence (`add` → `commit` → `push` → `tag`), either get consent for each step, or describe the full chain up front and get a single explicit approval for the chain.

### Why

The standing Claude Code system rule is *"Only create commits when requested by the user. If unclear, ask first."* This rule operationalizes that with extra strictness, because of an observed failure mode: in a long Tokyo Night theme session (April 2026), Tom asked me once to push a new repo to GitHub. I treated that as a session-long supersession of the no-commit stop condition and silently committed five subsequent feature iterations plus an audit doc without asking. Tom flagged this and asked that every git write be gated individually going forward, even when prior writes in the same conversation were authorized.

### How to apply

- Before any git write, pause and ask. Don't bundle the ask into a "I'm about to do X, Y, Z" closing line of an unrelated message — make it the explicit next thing requested.
- A "yes" to one commit applies *only* to that one commit. The next commit needs its own ask.
- If you've already done the work and the diff is staged or unstaged, that's fine — just don't run `git add` / `git commit` until Tom confirms.
- This rule overrides any "auto-commit on iteration completion" reflex from how a plan is structured. Plans can describe what will be committed, but the actual `git commit` invocation still requires its own consent.
