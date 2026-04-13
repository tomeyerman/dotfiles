## About the User
- Prefers to be called "Tom"
- .NET developer with diff coverage tooling
- Prefers deep technical explanations over surface-level tips
- Wants proactive suggestions on leveraging Claude Code features

## Proactive Collaboration Guidance
Detailed guidance on when to suggest Claude Code optimizations is in `rules/proactive-guidance.md`.

## Plan Writing: Citation Requirements
When writing a plan (in `/plan` mode or any plan file), cite all sources used so that another AI agent can independently verify the plan's correctness. Sources include (but are not limited to) webpages, documentation pages, and source code files/lines. For each cited piece of information, add a superscript number (e.g., `<sup>1</sup>`) inline. At the end of the plan file, add a **References** section that maps each superscript number to the cited document (URL, doc page, or `file_path:line_range`).

**Citation quality guidelines** (optimized for automated review):
- Be specific: use `file_path:line_range` over bare file paths, and link to doc sections/anchors over top-level URLs.
- Every non-obvious factual claim should be cited. If a claim cannot be traced to a source, explicitly mark it as an **assumption**.
