---
status: accepted
---

# Row plumbing that runs git ships as scripts

The orchestrators' plumbing was prose: each skill spelled out the git commands an agent
types, and the lint pinned their wording. A pin proves a phrase is there, not that the
commands work, and a step two skills share was written out in each. The landing's
owner-checkout guard was written four times across `/dev:implement-story` and
`/dev:implement-task`; its untracked-files fix landed once per skill (43264dc, 790de9b),
and the two skills' failure lines drifted apart.

## Decision

- **A step of row plumbing that runs git and decides from what it reads ships as a script**
  under `scripts/`, with a usage line, one-line outcomes and exit codes, and a test that runs
  it on a throwaway git repo in `make check`. The rules doc introduces each script once; the
  skills cite it by name and keep only what they do with each outcome.
- **What needs an agent stays in the skills**: spawning, briefing, counting retries, bead
  notes and closes. A script touches only git and its own records.
- **The lint pins that the skills cite each script and bans inline copies of its
  commands**; what the script does is proven by its test.

Examples: `scripts/check.sh`, the Check record script (881626a), and `scripts/land.sh`, the
Land script, with `scripts/stray-commits.sh`, the stray-commit check that the landing and
Delivery share.

## Considered options

- **Keep the prose and pin it.** Rejected: every fix lands once per skill, and a pin cannot
  catch a command that reads well and does the wrong thing.
- **One plumbing script with subcommands.** Rejected for now: each script has its own
  callers and its own test, and nothing yet varies across them that a shared interface would
  hide.

## Consequences

- An agent finds a script through the rules doc's Plugin root rule, as it finds `check.sh`.
- Plumbing that is still prose (the Cut-off probe, the Clean up sweep) is a candidate for a
  script under this rule, not a precedent against it.
