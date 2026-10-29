---
name: close-story
description: "Close one repo's story bead after its PR merges. Use when a story's PR has merged, or when /dev:close-epic checks each story."
---

Closes one **story** (${CLAUDE_PLUGIN_ROOT}/GLOSSARY.md): the part of a feature that lands in one repo, whose children are
**tasks**. Takes a story bead id, and optionally the path of the repo that owns it. With
a path, every `bd` call below is `bd -C <path> ...` and every forge command names that
repo (`git -C <path> remote get-url origin`, `gh -R <owner/repo>`, `tea` run with
`--repo`). When a `bd -C` fails with `Operation not permitted`, the
tracker doc's "bd writes outside the session's repo" says what to do. The rules this enforces are
in `${CLAUDE_PLUGIN_ROOT}/docs/agents/issue-tracker.md`, under "When a skill says 'close the epic'";
the `pr:` note format is under "When a skill says 'the spec is done'" there.

## Outcome lines

The skill ends on exactly one line, starting with the story id, so a calling skill
(`/dev:close-epic`) can tell the outcomes apart:

- `<id> closed: <pr value>`
- `<id> already closed`
- `<id> refused: <reason>`

A refusal has no override: the remedy is a visible action the user takes first. Jira is out
of scope; this skill never calls it.

## 1. It is a story

`bd show <id> --json` returns an array; read `.[0]`. `issue_type` is `story` → go on. Then:

- `status` already `closed` → `<id> already closed`, stop.
- Any other type → `<id> refused: <id> is <type>, not a story`.

## 2. Every task is closed

```bash
bd list --parent <id> --all --json | jq -r '.[] | "\(.id) \(.status) \(
  [.labels // [] | .[] | select(IN("needs-triage","needs-info","ready-for-agent","ready-for-human","wontfix"))]
  | join(",") | if . == "" then "-" else . end)"'
```

One line per child: id, status, triage label (`-` when it has none). The `--all` is
load-bearing: `bd list` hides closed beads, so a fully closed story reads as childless.
The publish task is a task like any other. A child that is not `closed` but
carries `needs-triage` or `wontfix` is not a task: it is a note an earlier run left
under the story (a review deferral filed before deferrals went to the inbox), with nothing
to implement, and it holds back neither the PR nor this close, as **finished story**
(${CLAUDE_PLUGIN_ROOT}/GLOSSARY.md) counts it; it stays open for `/dev:triage` in the repo session, where
`bd list -l needs-triage -s open` finds it whatever its parent's status. Any other child
not `closed` → `<id> refused: open tasks <child> <status> <label>, ...`, each as the
line above prints it. No children → `<id> refused: no tasks to verify`.

## 3. The `pr:` note exists

`.[0].notes` holds lines `pr: <url>`, or `pr: <branch> <tip SHA>` when delivery had no forge
(a `pr:` value that is not a URL is the branch form). `bd note` appends, so a re-delivery
leaves several: the last `pr:` line wins, and only its value is used below. None →
`<id> refused: no pr: note`.

## 4. The forge shows MERGED

Detect the forge from the repo's `origin` remote. `github.com` → `gh pr view <url> --json
state`, require `MERGED`. A Forgejo/Gitea host →
`tea api --repo <path> repos/{owner}/{repo}/pulls/<n>` (`--repo` names the story's repo, as
the intro says every forge command does, `.` when no path was given; without it `tea` reads
whichever repo the shell sits in), require `"merged": true` (its `state` reads `closed` for
merged and unmerged alike). Open or closed unmerged → `<id> refused: PR is <state>`.

Forge CLIs keep their tokens outside the sandbox and fail inside it with a config error
that is not a missing login, so run the one forge command with the sandbox disabled. A
`no available login` outside the sandbox is real. A failing forge command is an error:
report it as `<id> refused: forge check failed: <error>`, never as "no forge".

"No forge" means the origin host is neither GitHub nor Forgejo/Gitea, or there is no
origin; a branch-form `pr:` value has no PR to query and is treated the same. The merge
cannot be verified, so ask the user for an explicit yes (AskUserQuestion or a direct
question). The question always goes to the user, never answered by a calling skill. Any
answer but a yes, or a decline → `<id> refused: no explicit yes`.

## 5. Close

`bd close <id> --reason "<pr value>"`, then `<id> closed: <pr value>`.
