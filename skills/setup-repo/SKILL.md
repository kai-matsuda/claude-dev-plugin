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
   it writes nothing. It also prints a CLAUDE.md stub and a settings snippet; only its
   `missing:` and `confirm:` lines matter here. If any line starts `missing:`, stop and
   tell the owner to run `/dev:setup` first, then rerun this skill. A `confirm:` line
   (Atlassian) does not stop it.
2. **Explore.** Read, never write: whether `CLAUDE.md` exists and has a `## Agent skills`
   block with a `Jira project key:` line; whether `.beads/` exists; whether `GLOSSARY.md`
   and `docs/adr/` exist, and whether the repo is multi-context (a `GLOSSARY-MAP.md`);
   `git config core.hooksPath`; and, if `.beads/` is missing, `git status --porcelain`,
   because `bd init` commits and the later `git rm -r` and amend must not sweep up the
   owner's staged or modified files. Ask the owner for the Jira project key when the repo
   has none (a short uppercase key, such as `INFRA`).
3. **Present.** List what each write below would do and what is already in place and left
   alone. If `bd init` will run, say it makes a commit and that the pruning amends it, and
   name any staged or modified files from the explore step: stop, or ask the owner to
   commit or stash them, before `bd init`. If the repo already has a `Jira project key:`
   line that would change, name the old and new value. A repo that already has everything
   gets a report and no writes.
4. **Confirm.** Wait for the owner's explicit yes. On a no, change nothing.
5. **Write**, in this order, skipping what exists:
   - `.beads/`: if missing, run `bd init --non-interactive --agents-file CLAUDE.md`. It
     also generates `AGENTS.md`, `.codex/`, `.cursor/` and `.agents/` and makes a commit.
     Unless the repo uses those tools, `git rm -r` them and amend the init commit, keeping
     `.beads/`, `.claude/settings.json`, `CLAUDE.md` and the `.gitignore` additions (the
     tracker doc's "First time in a repo",
     `${CLAUDE_PLUGIN_ROOT}/docs/agents/issue-tracker.md`). If `core.hooksPath` was
     already set, chain the old hook from the new one in `.beads/hooks/` (outside the
     beads markers) and check the old hook is executable. It runs first so the init
     commit never holds the Jira key edit below.
   - `CLAUDE.md`: create it if absent, and add the `## Agent skills` block or its key
     line, as the line `Jira project key: <KEY>.` Change an existing key line only if the owner confirmed
     that change in step 4. Keep every other line of the file.
   - `GLOSSARY.md`: if absent, a heading and a one-line note that terms are added as they
     are resolved (`/mattpocock-skills:domain-modeling`). Never overwrite one. In a
     multi-context repo (`GLOSSARY-MAP.md` exists) leave it alone: each context owns its
     own glossary.
   - `docs/adr/`: if absent, create it with a `.gitkeep`. ADRs are numbered
     `NNNN-<slug>.md`.
6. **Report** what was written and what was left alone, and, if `core.hooksPath` was
   already set, whether the old hook was chained. Do not commit the CLAUDE.md,
   GLOSSARY.md or `docs/adr/` changes unless the owner asks; the `bd init` commit is the
   one exception.
