---
status: accepted, amended by ADR 0006, ADR 0007, ADR 0008, ADR 0010 and ADR 0011
---

> Amended by `0006-one-story-per-repo.md`: a repo's slice of a feature is a **story** bead
> that parents its tickets, the text blocker sits on the dependent story rather than on
> each ticket, and `pr:` notes live on the story. The sequencing rule below is unchanged.

> Amended by `0008-session-mode-declared-by-where-it-starts.md`: ADR 0007's note under
> Consequences no longer holds. The cut stages no longer check the workspace root; a
> cross-repo feature is typed at the workspace root, so every owner repo is inside the
> primary working directory. "The home repo" below is the home of a workspace session,
> the workspace root: it holds the epic bead, `/dev:implement-spec` runs there, and it owns
> neither the dependency nor the dependent, so "either role may be the home repo" and
> "`bd ready` in the home repo" now read as the owner repos'.

> Amended by `0011-a-story-is-one-pr-and-stories-form-a-dag.md`: the two-publish refactor
> and the point release this ADR allows are now cut as separate stories in the dependency
> repo, so a feature's stories form a DAG with chains allowed and more than one text
> blocker. The "beads external dependencies" option below was revisited on bd 1.3.1 and
> rejected again, on behaviour.

# A feature spanning repos stays one epic; the dependency publishes before dependents migrate

A feature sometimes changes more than one repo in a workspace: a library change that
forces its consumers to migrate, or a consumer feature that needs something new from a
library. It stays one feature. There is one Jira Epic and one epic bead, in the **home
repo**; every other repo the feature touches holds **cross-repo tickets**, beads carrying
the epic's Jira key as their external ref. Which repo owns a slice is fixed when the spec
is cut into tickets, by the repo manifest, and never re-routed during implementation. Each
repo touched gets its own integration branch and its own PR; the Jira key is the hub, and
each PR body names its sibling PRs. Build and merge rules are stated by dependency
direction, and either role may be the home repo: the **dependency** (the repo whose package
the other imports) is implemented first, its PR merges, and its package is published to the
registry. Only then do the **dependent**'s tickets start, each from the published version.
The publish is itself a ticket, the **publish ticket**: a bead in the dependency repo,
blocked on that repo's implementation tickets, closed with the published version as the
reason; every dependent ticket names it as a blocker in text, since beads edges do not
cross databases. One orchestrator in the home repo drives tickets in every repo; the split
is in time, not place, so a feature whose publish step is a person's takes two or more
`/dev:implement-spec` runs from the home repo. Only packages consumed by registry version are
covered; a repo that depends on siblings by git tag migrates to the registry first.

Workspace-specific facts (which registry, who publishes, which repos are excluded) live in
that workspace's own ADR; for mice-labs, `~/src/mice-labs/docs/adr/0003-*.md`.

## Considered options

- **One epic per repo, with its own Jira Epic.** Simplest to tool. Rejected because it
  doubles the Jira surface for every library change, and `/dev:close-epic` already sweeps the
  workspace by Jira key, so one epic costs nothing extra to close.
- **A `[patch]` path override so dependents migrate before the publish.** The dependent's
  integration branch points at the sibling checkout, migration tickets run unattended, and
  a final ticket swaps the patch for the published version. Rejected: the branch builds
  only on a machine with the right checkout beside it, tests run against the checkout
  rather than the package as published, and the patch has to be stripped before merge.
  The price of sequencing instead is one extra point release when a migration exposes a
  flaw in the library API.
- **A prerelease publish from the library branch.** Rejected wherever publishing is a
  person's step; agents do not publish.
- **beads external dependencies** (`bd dep add <id> external:<project>:<capability>`,
  unblocked by `bd ship` in the target repo). A native edge that `bd ready` honours.
  Rejected for now: the `external_projects` config it needs is undocumented, it is a
  per-repo setup step, and `bd ready` cannot show or hide externally blocked work.
  Revisit when the config is documented; the text blocker is the fallback until then.
- **Hydrating every repo into one view with `bd repo sync`.** One `bd ready` across the
  workspace but no blocking edge. A view, not a substitute for the rule.
- **Generalising "publish" to cover git-tag dependencies.** Rejected: a tag can move, so
  the version is not immutable, and fetching it needs network access the sandbox does not
  grant.

## Consequences

- A run ends when the frontier holds only human tickets, and its report names what to
  publish and that the same command resumes the feature afterwards. The dependent's first
  ticket is always a version bump against a published package; no `[patch]` ever lands on
  a branch.
- An expand-migrate-contract refactor across repos needs two publishes (after expand,
  after contract); a straight breaking change needs one. The count is decided per feature
  at `/mattpocock-skills:to-tickets`; the rule fixes only that every cross-repo migration starts from a
  published version.
- Subagents edit with the Edit and Write tools only inside the session's working
  directories, so `/dev:implement-spec` refuses up front unless every repo its tickets touch
  is one, and names the `/add-dir` to run. The alternative, adding the whole workspace to
  `additionalDirectories`, would auto-accept edits to any repo from any session.
  Amended by ADR 0007, and that amendment since reversed by ADR 0008 (see the note at
  the top): the two cut stages also ask for the workspace root, by a
  session-scoped `/add-dir`, because the story cut resolves owner repos from `repos.yaml`
  before it knows which repos to ask for, and `Read` is refused outside the working
  directories. The first human run of `/dev:spec-to-stories` worked only once the root was
  added. That makes every repo under the root a working directory for that one session;
  accepted, because the user types it visibly, it never persists to settings, and the cut
  stages write only beads, `.spec-notes` and one `.gitignore` line; ADR 0010 since narrows
  that to beads alone. The persistent `additionalDirectories` entry stays rejected.
- `bd ready` in the home repo over-reports: a dependent ticket whose text blocker is still
  open looks ready. The orchestrator checks `bd -C <repo> show <id>` before starting it.
  `/dev:close-epic` is unchanged: it sweeps by Jira key and verifies each repo's PR merged.
- Every repo that receives a cross-repo ticket needs its own `.beads/`.
