# The feature workflow ships as the dev plugin

## Problem Statement

The feature workflow lives in Kai's chezmoi dotfiles and reaches a machine with
`make apply`. That reaches a second personal machine in one command, but not a work
machine, where a personal dotfiles repo (shell, ssh, git identity) has no business, and
not a coworker, who has nothing to install. The skills address each other by bare names
and the rules docs by absolute home paths, so they cannot be lifted out as they are.

## Solution

The workflow moves into this repo as the Claude Code plugin `dev`, and this repo is also
its marketplace. Every machine, Kai's included, installs it from the marketplace. Skills
are addressed as `/dev:<skill>`; the rules docs live under the plugin root. Two setup
skills cover what a plugin cannot carry: `/dev:setup` once per machine hands the owner
the user-level `CLAUDE.md` stub and the baseline settings snippet; `/dev:setup-repo` once
per repo records the Jira project key, the one configuration point. Decisions are in
ADR 0013; vocabulary in `GLOSSARY.md` (Dev plugin, Machine setup, Repo setup, Baseline
settings).

## User Stories

1. As Kai on a work machine, I want to install the workflow from a marketplace, so that
   work gets the skills and none of my personal dotfiles.
2. As Kai on the mac mini, I want the same install path as everywhere else, so that no
   machine runs a copy that drifts from the published version.
3. As a coworker, I want a README that says what the plugin is, what it needs and how to
   install it, so that I can adopt it without asking Kai.
4. As a coworker on a fresh machine, I want `/dev:setup` to tell me which prerequisites
   are missing (`bd`, `gh` or `tea`, mattpocock-skills, the Atlassian MCP), so that the
   first feature skill I type does not fail halfway.
5. As a machine owner, I want `/dev:setup` to hand me the `CLAUDE.md` stub and the
   baseline settings to paste, so that I review what lands in my user-level config.
6. As a machine owner, I want the baseline settings to hold nothing org-specific, so
   that they are right at work on day one and my toolchain and forge lines stay mine.
7. As Kai on a chezmoi-managed machine, I want `/dev:setup` to report everything present
   and change nothing, so that chezmoi stays authoritative there.
8. As a repo owner, I want `/dev:setup-repo` to record the Jira project key in the
   repo's `CLAUDE.md`, initialise beads, and lay out `GLOSSARY.md` and `docs/adr/`, so
   that a work repo and a personal repo differ in one line.
9. As a repo owner on an unconfigured machine, I want `/dev:setup-repo` to point me at
   `/dev:setup` first, so that I do not debug a repo problem that is a machine problem.
10. As a user typing `/dev:implement-spec`, I want every skill it calls resolved as
    `dev:<skill>`, so that the chain never stops on an unknown skill.
11. As a subagent briefed by a story orchestrator, I want the rules docs at a path that
    exists on this machine, so that a brief written on one machine reads on another.
12. As a user on any machine, I want the `guard-rm` and `bd prime` hooks to come with the
    plugin, so that I do not edit settings to get them.
13. As a user, I want `/dev:workflow` to show the runbook with every command in its
    namespaced form, so that what I read is what I type.
14. As a user of a repo whose `CLAUDE.md` names no Jira key, I want the feature skills to
    refuse with one line, so that nothing is created against the wrong project.
15. As a reader, I want the glossary and ADRs 0001 to 0013 in this repo, so that the
    plugin explains itself without the dotfiles history.
16. As a maintainer, I want the skill-doc lint to refuse a bare or foreign skill
    namespace, so that the rewrite cannot regress.
17. As a maintainer, I want the lint to refuse a change under `skills/` or `docs/` that
    leaves the plugin version alone, so that installed machines see every change.
18. As a maintainer, I want GitHub Actions to run the lint and the guard-rm test on every
    push, so that a coworker's PR is checked the same way as mine.
19. As a maintainer, I want the fixture tests to run locally against this repo's skills,
    so that the stage boundaries keep their coverage after the move.
20. As a reader of the first commit, I want it to cite the dotfiles repo and commit the
    content came from, so that the old history is one hop away.
21. As a user of mattpocock-skills, I want the plugin to call the installed
    `code-review`, `pr` and `tdd` rather than forks, so that I get their updates.
22. As the owner of the `repos.yaml` rename bead, I want it moved to this repo's beads
    and closed in dotfiles pointing here, so that it is found where it will be done.

## Implementation Decisions

- The plugin is the repo root: `.claude-plugin/plugin.json` (name `dev`) and
  `.claude-plugin/marketplace.json` (one plugin, source `./`). Skills under `skills/`,
  rules docs under `docs/agents/`, the runbook at `docs/WORKFLOW.md`, hooks under
  `hooks/` with a `hooks.json`, glossary and ADRs at the root and `docs/adr/`, the lint
  and tests under `scripts/` with a `Makefile`.
- Every bare skill reference becomes `dev:<skill>`, in prose, in Skill tool calls and in
  briefs. References to mattpocock-skills keep their namespace. The lint's namespace rule
  allows `dev:` and `mattpocock-skills:` only.
- Rules docs are addressed through the plugin root. A skill resolves the plugin root once
  from the harness's plugin-root variable and spells the absolute path literally in every
  brief, as the TMPDIR line already does for worktrees, so a subagent never depends on an
  environment variable being inherited.
- The hooks file registers `guard-rm` on Bash tool calls and `bd prime --hook-json` on
  session start, the script addressed through the plugin root. The dotfiles settings lose
  both entries at the cutover (a separate feature).
- The user-level `CLAUDE.md` "Agent skills" section is folded into the rules docs it
  summarises; the only text left for a machine is the stub `/dev:setup` prints. The Jira
  instance URL is dropped: the Atlassian MCP connection fixes the instance and the repo's
  `CLAUDE.md` names the project key.
- `/dev:setup` is user-invoked (`disable-model-invocation`), runs anywhere, checks the
  prerequisites, prints the stub and the baseline settings for the owner to paste, and
  writes nothing outside the repo it runs in. The baseline: denies on secret files, asks
  on destructive git and `bd dolt push`, the `bd` allow, the sandbox enabled with the
  beads and Dolt directories writable and push and fetch excluded. Toolchain, registry
  and forge lines appear in the README as examples only.
- `/dev:setup-repo` is user-invoked, runs in a repo, checks the machine setup first,
  then records the Jira project key in the repo's `CLAUDE.md`, runs `bd init` if
  needed, and lays out `GLOSSARY.md` and `docs/adr/`, following the mattpocock setup
  skill's explore, present, confirm, write shape.
- The version in `plugin.json` is semver, bumped on every merge to main: patch for
  wording, minor for a new or renamed skill, major for a change to the beads or Jira
  contract. No git tags. Development runs Claude Code with the plugin directory flag.
- The lint finds mattpocock-skills through the existing override variable; CI checks out
  mattpocock/skills at a pinned tag and points the variable at it, installs `bd`, and
  runs the lint, its regression test and the guard-rm test. The fixture tests stay local.
- The first commit is a fresh start whose message cites `vangogh500/dotfiles` and the
  commit the content was taken from. The dotfiles `docs/adr/` keeps a pointer to ADR 0013
  at the cutover.
- Bead `chezmoi-69m` (rename `repos.yaml`) is recreated in this repo's beads and closed
  in dotfiles with a reason naming the new id. `chezmoi-gp9` stays in dotfiles.

## Testing Decisions

- A good test drives the lint and the skills from outside: exit codes and messages of
  the lint on fixture skill docs, and the fixture tests that run a stage against a
  throwaway beads database. No test reads a skill's prose for a phrase. A test may check
  a SKILL.md's frontmatter structure (its name, a description, the invocation flag),
  which is the plugin's contract with Claude Code, not prose a reword would break.
- One seam: `make lint` in this repo, which runs the skill-doc lint, its regression test,
  the guard-rm test and, last, the fixture tests. The lint gains two cases: a bare
  `/<skill>` reference fails with the namespace message, and a change under `skills/`
  or `docs/` without a version bump fails. Prior art: `scripts/test-lint-skill-docs.sh`,
  `scripts/test-guard-rm.sh`, `scripts/test-fixture-*.sh`.
- GitHub Actions runs the same target minus the fixture tests.
- The install from the marketplace on this machine is checked by hand and is the
  acceptance of the dotfiles cutover feature, not of this one.

## Out of Scope

- The dotfiles cutover: deleting the skills, docs, hook and tests from the chezmoi repo
  and enabling the plugin there. A second feature in that repo.
- Vendoring the mattpocock-skills forks. Prerequisite for now (ADR 0013).
- Running the fixture tests in CI.
- Submitting to the official marketplace.
- Neutralising `INFRA` and `mice-labs` in the docs' examples.
- Any plugin-level or machine-level Jira configuration.

## Further Notes

The grill that produced this spec ran in the dotfiles repo on 2026-10-24; its ADR 0013 and
glossary terms were committed there and move here with the content.
