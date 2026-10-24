---
name: setup-repo
description: Repo setup for the dev plugin. Records the Jira project key in the repo's CLAUDE.md, runs bd init when .beads/ is missing, and lays out GLOSSARY.md and docs/adr/. Use once per repo, after /dev:setup.
disable-model-invocation: true
---

# Setup repo

Repo setup, run once per repo from the repo's root. It follows
explore, present, confirm, write: nothing is written before the owner confirms the plan
in step 4.

1. **Check the machine setup.** Run `bash ${CLAUDE_PLUGIN_ROOT}/skills/setup/check-prereqs.sh`;
   it writes nothing. If any line starts `missing:`, stop and tell the owner to run
   `/dev:setup` first, then rerun this skill. A `confirm:` line (Atlassian) does not stop
   it.
2. **Explore.** Read, never write: whether `CLAUDE.md` exists and has a `## Agent skills`
   block with a `Jira project key:` line; whether `.beads/` exists; whether `GLOSSARY.md`
   and `docs/adr/` exist; `git config core.hooksPath`. Ask the owner for the Jira project
   key when the repo has none (a short uppercase key, such as `INFRA`).
3. **Present.** List what each write below would do and what is already in place and left
   alone. A repo that already has everything gets a report and no writes.
4. **Confirm.** Wait for the owner's explicit yes. On a no, change nothing.
5. **Write**, in this order, skipping what exists:
   - `CLAUDE.md`: create it if absent, and add or fix the `## Agent skills` block with the
     line `Jira project key: <KEY>.` Keep every other line of the file.
   - `.beads/`: if missing, run `bd init --non-interactive --agents-file CLAUDE.md`. It
     also generates `AGENTS.md`, `.codex/`, `.cursor/` and `.agents/` and makes a commit.
     Unless the repo uses those tools, `git rm -r` them and amend the init commit, keeping
     `.beads/`, `.claude/settings.json`, `CLAUDE.md` and the `.gitignore` additions (the
     tracker doc's "First time in a repo", `docs/agents/issue-tracker.md` in the plugin
     root). If `core.hooksPath` was already set, chain the old hook from the new one in
     `.beads/hooks/` (outside the beads markers) and check the old hook is executable.
   - `GLOSSARY.md`: if absent, a heading and a one-line note that terms are added as they
     are resolved (`/mattpocock-skills:domain-modeling`). Never overwrite one.
   - `docs/adr/`: if absent, create it with a `.gitkeep`. ADRs are numbered
     `NNNN-<slug>.md`.
6. **Report** what was written and what was left alone. Do not commit the CLAUDE.md,
   GLOSSARY.md or `docs/adr/` changes unless the owner asks.
