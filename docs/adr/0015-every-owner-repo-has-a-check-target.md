---
status: accepted
---

> Amends ADR 0014 (`docs/adr/0014-one-loop-at-three-rows.md`): its "a repo opts in by adding
> the target" and the review-only gate that followed from it, with the dev-5e4 and dev-2p5
> amendments that patched that gate.

# Every owner repo has a check target

ADR 0014 made the check command `make check` when a repo's Makefile has a `check` target and
none otherwise, so a repo with no target got a review-only gate and adding the target was how
a repo opted in to checks. That fork cost more than it saved. Each place the gate met a commit
after the review had to say what a review-only gate does there: a `low` ticket had no review
and, with no check, landed ungated (dev-5e4 gave it a review); a minors fix-up or a conflict
resolution moved the tip after the clean review with nothing to rerun (dev-2p5 sent the minors
to the inbox and left the resolution to the story row). About 25 statements across the rules
doc, the skills, the glossary and the runbook, and about 60 lint pins and tests, kept the fork
alive, and each new rule about the moved tip would need its review-only twin.

## Decision

- **Every owner repo has a `check` target, and its check command is `make check`.**
  `/dev:setup-repo` always adds one: it wraps the repo's test and lint targets, or runs its
  tests and linters, or, in a repo with neither, the most useful check it can infer (a syntax
  check of its scripts, a build, a parse of its configs, a lint of its docs) or the one the
  owner names. Never an
  empty or `true` recipe, which would keep the fork under another name. With no `Makefile` it
  creates one; the `CLAUDE.md` note it wrote instead is gone.
- **A story run in a repo with no `check` target fails at once.** `/dev:implement-story`
  step 3 resolves the check command and, with no target, ends the run with
  `failed: no check target in <owner>; run /dev:setup-repo there, then re-run`, before any
  ticket orchestrator starts.
- **The gate has one shape.** Every tree is checked once, so a commit that moves the tip after
  the review (a minors fix-up, a conflict resolution) always reruns the checks. A `low`
  ticket's gate is the checks alone again, and a clean round's in-scope minors go to one last
  fix-up at the ticket and story rows whatever the repo.

## Considered options

- **Keep the review-only gate** and patch each moved-tip case as it appeared. Rejected: two
  patches in one week, each with its own lint pins, and the fork doubles every future rule
  about a commit after the review.
- **A `true` check target for repos with nothing to check.** Rejected: the gate would read
  green on every tree, a review-only gate that claims to be checked.
- **Fall back to a configured command** (a `Check command:` line in `CLAUDE.md` or the
  manifest). Rejected for the reason ADR 0014 gave: one convention, resolved one way, so the
  forge, the orchestrators and a person at the terminal run the same command.

## Consequences

- A repo in the manifest without a `check` target cannot run `/dev:implement-story` until
  `/dev:setup-repo` adds one there; dev-1j6 surveys the manifest and files a bead in each
  such repo to add it.
- The docs and skills name no review-only gate and no gate without a check command; the lint
  sweeps both phrases.
- ADR 0014 keeps its text and points here.
