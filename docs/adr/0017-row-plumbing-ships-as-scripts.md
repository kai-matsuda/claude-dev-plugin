---
status: accepted
---

# Row plumbing ships as scripts

Amended (dev-bveq, INFRA-44): the rule covers forge plumbing too, not only git. The Forge-check
wait was an inline compound shell call run with the sandbox disabled, which no narrow exemption
could match; as `scripts/forge-wait.sh` it is one plain command.

Amended (dev-21sr, INFRA-44): a script the sandbox exemption must match ships in the plugin's
`bin/` and is called by its bare name, not under `scripts/` by its exact installed path. The
exact path contained the plugin version, so the owner re-pasted the rule pair after every
plugin update, and old version directories are deleted 14 days after one. The script is now
`bin/forge-wait`, which resolves by its bare name where `skills/setup/SKILL.md` says it does
(Claude Code puts an enabled plugin's `bin/` on the Bash tool's `PATH`), and the setup pair is the
bare `forge-wait * * * * *`. What pinned the file moves from the exact
path to a condition: no sandbox-writable directory is on `PATH`, which a baseline that already
excludes `git push*` needs as well. Other scripts stay under `scripts/`.

Amended (dev-ekcl.1.2, INFRA-47): `bin/` holds a second script, `commit-trailers`, the trailer
hook, called by its bare name from a commit-msg hook in the owner's gitconfig. That hook command
skips (exits 0) when the name is not on `PATH`, so a machine without the plugin's `bin/` on `PATH`
commits as before. Hand-made commits get no further check: a hand-made commit has no
provenance trailer to demand, so the hook asks for none and only blocks a configured key that
git would not read as a trailer.

The orchestrators' plumbing was prose: each skill spelled out the git commands an agent
types, and the lint pinned their wording. A pin proves a phrase is there, not that the
commands work, and a step two skills share was written out in each. The landing's
owner-checkout guard was written four times across `/dev:implement-story` and
`/dev:implement-task`; its untracked-files fix landed once per skill (43264dc, 790de9b),
and the two skills' failure lines drifted apart.

## Decision

- **A step of row plumbing that runs git or a forge CLI (`gh`, `tea`) and decides from what
  it reads ships as a script** under `scripts/`, with a usage line, one-line outcomes and exit
  codes, and a test in `make check`: a git script's test runs it on a throwaway git repo; a
  forge script's test runs it against stub `gh` and `tea` on `PATH`, since no test may reach
  a live forge. The rules doc introduces each script once; the
  skills cite it by name and keep only what they do with each outcome.
- **What needs an agent stays in the skills**: spawning, briefing, counting retries, bead
  notes and closes. A script touches only git, the forge CLI and its own records.
- **The lint pins that the skills cite each script and bans inline copies of its
  commands**; what the script does is proven by its test.

Examples: `scripts/check.sh`, the Check record script (881626a), and `scripts/land.sh`, the
Land script, with `scripts/stray-commit.sh`, the stray-commit check that the landing and
Delivery share, and `bin/forge-wait`, the forge-check wait of Delivery step 4, the
first forge script, tested with stub CLIs.

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
