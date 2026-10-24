## Agent skills (user-level defaults)

Apply in every repo unless the repo's own CLAUDE.md overrides a section.

The feature workflow comes from the `dev` plugin; its rules docs live under `docs/agents/`
in the plugin and its skills read them, so none is restated here.

- Jira is for humans (one Epic per feature, holding the spec); beads (`bd`) is for AI task
  tracking. The repo's CLAUDE.md names its Jira project key; run `/dev:setup-repo` in a
  repo that lacks one.
- Commit messages are Conventional Commits, `type(scope): subject`, imperative, lowercase,
  at most 72 characters, with `Bead:` and `Refs:` trailers when the work came from a bead.
- For context around a match, or any `{m,n}` repeat, use `command grep`, not `grep`.
- Never prefix a command with `cd <repo> && ...`; use the command's own flag
  (`git -C <dir>`, `make -C <dir>`) or an absolute path.
- Agent scratch space goes in repo-relative, gitignored paths, never under `/tmp`.
