# Issue tracker: Jira (human interfacing) + beads (AI task tracking)

The dev plugin's default for every repo. The repo's CLAUDE.md supplies `<KEY>`, the Jira
project key; if it is missing, ask once and record it in the repo's `## Agent skills`
block. The human-facing runbook for the whole flow is `../WORKFLOW.md` (`/dev:workflow` in
a session).

Issues live in two places with distinct roles:

- **Jira** at https://micelabs.atlassian.net, project `<KEY>` — the human-facing layer.
  A feature is one Jira **Epic** holding the spec. Triage, stakeholder comments, and
  status transitions happen here. Jira never sees individual implementation tickets.
- **beads** (`bd`, database in the repo's `.beads/`) — the AI task layer. Every feature
  is an **epic bead** linked to its Jira epic via `--external-ref <KEY>-<n>`. A feature
  has one **story** bead per PR, usually one per repo it changes, the parent of that PR's
  implementation tickets. Blocking edges inside a story are native beads deps, and `bd
  ready` lists the native-edge frontier; edges between stories are text blockers.

Jira access is through the Atlassian MCP tools (`createJiraIssue`, `getJiraIssue`,
`searchJiraIssuesUsingJql`, `editJiraIssue`, `addCommentToJiraIssue`, `transitionJiraIssue`);
there is no `jira` CLI installed. Cloud ID: `288d178c-1d1d-485a-83f6-4b8aaa46f1ef`.

Repos are checked out as siblings inside a **workspace** under `~/src/<org>/`, itself a
repo holding `repos.yaml`, the repo manifest. Which of the two sessions below a session
is depends only on where it starts.

**Session mode, the one test.** `<home>` is the session's repo, `git rev-parse
--show-toplevel`, and nothing above it is ever read (plain `bd` climbs to an ancestor's
database when `<home>/.beads` is missing, so the skills check it first). If
`<home>/repos.yaml` exists, the session is a **workspace session**: `<workspace>` is
`<home>`, the repo manifest routes (its header gives the resolution order), and a
manifest repo `<owner repo>` (the entry's name) is at `<owner>`,
`<workspace>/<owner repo>` or the entry's `path`. Otherwise it is a **repo session**:
`<home>` is the home repo and the only owner, `<owner>` is `<home>`, `<owner repo>` is
`<home name>`, `<workspace>` is undefined, and any workspace above is ignored. Either
way the **home** holds the feature's epic bead, the spec and the **inbox**;
`<home name>` is the basename of `<home>`. Every section below reads the mode from this
test. Why: ADR 0008 (`docs/adr/0008-session-mode-declared-by-where-it-starts.md` in the
plugin repo).

## Before the story quiz: one story per PR (`/dev:spec-to-stories`)

A spec is cut in two typed stages: the story cut, `/dev:spec-to-stories`, splits the spec into
stories; the ticket cut, `/dev:spec-to-tickets` (which drives `/dev:story-to-tickets` over each
story), splits each story into tickets. Apply this before the story cut's quiz.

A story is one PR (ADR 0011, `docs/adr/0011-a-story-is-one-pr-and-stories-form-a-dag.md`
in the plugin repo), so a feature has one story per PR, usually one per repo. Resolve
the spec to the repos it changes by the session mode (the one test above). In a workspace
session the repo manifest resolves them, and every manifest repo the spec changes gets a
story. The workspace root itself never owns a story: every workspace-session story is in
another database than the epic bead (ADR 0008), and the stories gather sweeps manifest
repos only. A change the spec makes to the root's own files (`repos.yaml`, a workspace
ADR) is named in the story quiz as done by hand at the root, not cut. In a repo session
every story is in the home repo; a spec that visibly changes another repo is refused, not
cut to a one-repo subset: `refused: the spec changes <what> outside <home>; start this at
the workspace root`. A story's repo is its **owner repo**, fixed here and never re-routed
later; every ticket is cut inside one story, so a ticket never spans repos.

The story cut proposes a second story in a repo by itself only when the spec describes a
deprecate-then-remove: the story that removes is split from the one that deprecates and
waits on the closure of the stories that migrate off it. The user may split a repo's story
at the quiz for any reason: two deliveries stacked on each other's closure, two
independent slices, a step that is not a publish, such as a deploy. On a split at such a
step, the later story waits on the earlier story's closure (a `<repo> <story-id>` blocker
line), the deploy being a `ready-for-human` ticket inside the earlier story
that `/dev:close-story` requires closed.

The stories and their text blockers form the **story DAG**: each story's `## Blocked by`
lines are its edges, each naming a **human gate ticket** (a `ready-for-human` ticket a
person closes; the publish ticket is one) or a story. Cycles are refused, whatever kind
of edge closes them: the story DAG has none, so a cut whose edges would close one stops
before creating anything and names the stories on the cycle. The story quiz shows, per
story: the owner repo, one paragraph of what that PR must deliver, and its blockers, so
the user sees the DAG. When the breakdown touches a dependency repo, it also shows each
publish ticket with the version it proposes and each dependent's bump ticket, so the user
can correct the version before approving. Read "When the breakdown touches a dependency
repo" below first: it says how to detect each dependency edge and how to propose the
version.

## First time in a repo

If the repo has no `.beads/`, run, with the repo's top level as the session's current directory:

```bash
bd init --non-interactive --agents-file CLAUDE.md
```

Run it from there alone, and never through `-C`, `BEADS_DIR`, `--db` or `--init-if-missing`:
from anywhere else, an ancestor directory's `.beads/` (the workspace's, for a repo checked
out inside it) is the database init finds, so it aborts with `Found existing Dolt database:
<path>`, or with `--init-if-missing` exits 0 having created nothing
(gastownhall/beads#7985). When the session's current directory is not the repo's top level,
the shell rule forbids `cd`, so give the user the exact command to run there. An abort
naming a `<path>` outside the repo is reported and the setup stops:
never retry with `--reinit-local`, `--force` or `--destroy-token`, which act on that other
database. After any init, `bd -C <repo> where` must print `<repo>/.beads` on its first
line; anything else is reported and the setup stops, since every later `bd` call there
would land on the other database.

It also generates `AGENTS.md`, `.codex/`, `.cursor/`, and `.agents/` and makes a commit.
Unless the repo uses those tools, `git rm -r` them and amend the init commit, keeping
`.beads/`, `.claude/settings.json`, `CLAUDE.md`, and the `.gitignore` additions. If the
repo already had `core.hooksPath` set, chain the old hook from the new one in
`.beads/hooks/` (outside the beads markers) and check the old hook is executable.

## Conventions

- Jira issue types vary per project; check with `getJiraProjectIssueTypesMetadata`.
  A feature spec is an Epic (or Feature). Standalone bugs reported by humans are Bugs.
- Specs are written as markdown in the Jira epic description. Long specs may also be
  checked in under `docs/specs/<feature-slug>.md` and linked from the epic. Specs are
  plans of work, not decision records: when a spec settles an architectural decision,
  extract it into a numbered ADR at `docs/adr/NNNN-<slug>.md` (see `domain.md`) and
  link the ADR from the spec. Never put specs in `docs/adr/`.
- Triage state is a Jira label on the epic (see `triage-labels.md`). Mirror it on the
  epic bead with `bd label add <id> <label>`.
- Every ticket carries exactly one `complexity:<tier>` label (see "Complexity labels").
- Human-facing comments and decisions go to the Jira epic (`addCommentToJiraIssue`);
  `bd note` is for agent-local progress that nobody else needs to read.
- Epic bead writes: of the cuts, only `/dev:spec-to-stories` writes on the epic bead, creating
  it when none exists and adding one `skipped: <repo> no beads database` note per skipped
  repo ("publish the stories" step 2), while `/dev:spec-to-tickets` only reads those notes and
  neither it nor `/dev:story-to-tickets` ever notes, updates or closes the epic bead.
- Purely agent-internal work (wayfinding, research spikes, refactor sub-steps) stays in
  beads only and never gets a Jira issue unless a human needs to see it.
- Commit messages are Conventional Commits, `type(scope): subject`: types feat, fix,
  refactor, test, docs, chore; scope optional; the subject imperative, lowercase, no
  trailing period, at most 72 characters. A body only when the why is not obvious from
  the diff, never a bullet list restating it. Every commit carries its provenance as
  trailers, `Bead: <bead-id>` when the work came from a bead and `Refs: <KEY>-<n>` for
  the Jira epic the bead's `--external-ref` points at (never a per-ticket Jira issue),
  both when both apply. Neither is inferable from a diff, so a commit without them loses
  the link for good. They go in the last paragraph with the attribution lines and no
  prose, since git parses only a last paragraph made of trailer lines as trailers. A
  machine may enforce the mechanical parts with a commit-msg hook (the `commit-lint.sh`
  the plugin ships in `skills/setup/`, when machine setup installed it); a commit it
  rejects is fixed and retried (`harness.md`, Commits).

## When a skill says "publish the spec to the issue tracker" (`/mattpocock-skills:to-spec`)

1. `createJiraIssue` in `<KEY>`: type Epic, summary = feature name, description = the
   spec, label `ready-for-agent` (or whatever the skill specifies). Report the key.
2. `bd create "<feature>" --type epic --external-ref <KEY>-<n> -d "<Jira URL>" -l ready-for-agent`
   so the beads side has an anchor for the tickets that follow. When the spec is also a
   file in `<home>` (`docs/specs/<slug>.md`), the description carries its `Spec:` line
   too, in the form "gather the epic bead" gives below.

## When a skill says "publish the stories" (`/dev:spec-to-stories`)

Run once the story quiz is approved, before any ticket is cut. `<home>`, `<owner>` and
`<owner repo>` are as the one test above defines them. Every `bd [-C <owner>]` below
takes `-C` when the owner is not `<home>`, which is every story in a workspace session.

If `/dev:spec-to-stories` is run without a prior `/mattpocock-skills:to-spec` (its key argument finds no epic
bead), create the epic bead first, carrying that key as its `--external-ref`; no Jira epic
is created, since the key names one. The key is taken as given: one Jira does not know
surfaces as `<KEY>-<n> is not in Jira` at the spec fetch or the ticket cut's comment. The
skill requires the key or a bead id ("gather the epic bead" below), so `/dev:spec-to-stories`
never creates an epic bead without a key; one made by hand or by the flat `/mattpocock-skills:to-tickets`
path can lack it, which step 1 catches.

1. In a workspace session the epic bead must carry an `--external-ref <KEY>-<n>`: every
   story is in another database than the epic bead, so that key is all that ties a story
   to the feature. If it has none (made by hand or by `/mattpocock-skills:to-tickets`), stop before creating
   anything and tell the user to publish the spec with `/mattpocock-skills:to-spec` (or add the key with
   `bd update <epic-id> --external-ref <KEY>-<n>`). In a repo session the key is not
   needed: every story there is the epic bead's child.
2. Check each owner repo for `.beads/` before creating anything, with `test -d
   <owner>/.beads`. Do not probe with `bd -C`: without its own database bd
   climbs to the workspace's and would file the story in the inbox. A repo without it is
   reported by name. Offer "First time in a repo" there and act only on the user's explicit
   yes. `bd init` runs only from `<owner>`'s top level ("First time in a repo" says why),
   so give the user the exact command to run in `<owner>`, and continue once
   `bd -C <owner> where` prints `<owner>/.beads` on its first line. On a
   no, create neither that repo's story nor its tickets, and still publish every other
   story. When the skipped repo is a dependency, its dependent story's text blocker is
   `<dep repo> publish <crate> <version> (not created: no beads database)`, in place of
   step 4's `(not created yet)` line. List the skipped stories in the report, and record
   each on the epic bead, `bd note <epic-id> "skipped: <repo> no beads database"`, one per
   skipped repo: a skipped repo has no story to carry it, so these notes are where the
   ticket cut reads skips from for its Jira comment. They are the only notes a cut writes
   there (the "epic bead writes" convention above).
3. Create the stories in the story DAG's topological order, each after every story it
   waits on, so a blocker line naming a story has its id (step 6 of "When the breakdown
   touches a dependency repo"):

   ```bash
   # repo session: every story
   bd create "<story title>" --type story --parent <epic-id> --no-inherit-labels \
     [--external-ref <KEY>-<n>] --body-file -
   # workspace session: every story
   bd -C <owner> create "<story title>" --type story \
     --external-ref <KEY>-<n> --body-file -
   ```

   `<KEY>-<n>` is the epic bead's external ref; a repo-session story carries it whenever
   the epic bead has one. Only repo-session stories have a parent: a parent cannot span
   databases. Every repo-session story, however many the home repo holds, is created
   with `--parent <epic-id>`, so the stories gather (`bd children <epic-id>`) finds them
   all. A story carries no labels. It has no `complexity:` tier (its review model is the
   highest among its tickets) and no triage label, and `--no-inherit-labels` keeps the
   epic bead's `ready-for-agent` off every repo-session story, so tickets created under a
   story inherit nothing.
4. The story body is never a copy of the spec. It holds, in order:

   ```markdown
   <one paragraph: what this repo must deliver for the feature>

   ## Test seams
   <the seams in this repo the story's tickets test at>

   ## Parent
   Home <home name>, epic bead <epic-id>, <KEY>-<n>

   ## Blocked by
   <repo> <story-id>
   <dep repo> publish <crate> <version> (not created yet)
   ```

   `## Blocked by` holds one **text blocker** line per edge of the story DAG, each naming
   a human gate ticket or a story, in any repo's database, the story's own included; a
   story may carry several, and the section is omitted when it has none. Write the edges
   minimally: the story's direct needs only, never one implied by a path through a gate
   ticket. A line naming a story clears when `/dev:close-story` closes it after its PR merges;
   one naming a human gate ticket clears when a person closes it. A blocker on a publish
   ticket names a ticket the ticket cut creates, so write that line as
   `<dep repo> publish <crate> <version> (not created yet)` now; "publish a story's
   tickets" fills in the id. A line with no id counts as open, so the story cannot start
   in between. The story cut creates no tickets, so it never knows a gate ticket's id: it
   writes a story line or a publish placeholder (step 2's `(not created: no beads
   database)` form included), never a line naming a gate ticket id.

## When a skill says "publish a story's tickets" (`/dev:spec-to-tickets`, `/dev:story-to-tickets`)

Under `/dev:spec-to-tickets` this runs after the one merged ticket quiz is approved;
`/dev:story-to-tickets` run alone quizzes the user on its one story first.

Tickets are beads, children of their story, in the story's owner repo. Publish in
dependency order (blockers first) so edges can reference real ids, and the stories in the
order of step 6 below:

```bash
bd [-C <owner>] create "<ticket title>" --parent <story-id> \
  -l complexity:<tier>,ready-for-agent \
  --deps blocked-by:<id>,blocked-by:<id> --body-file -   # body = the issue template
```

Omit `--deps` for tickets that can start immediately. A ticket has no `## Blocked by`:
native edges carry its blockers inside the story, and the story holds the text blockers.
The template's `## Parent` names the story and the feature, for example `Story lib-x2a in
lib; home mice-labs, epic bead mice-labs-abc, INFRA-26`, where the home is a workspace. Do not create Jira issues per
ticket.

A re-cut of one story (`/dev:story-to-tickets` run alone) keeps the story's publish ticket, if
it has one, and adds native edges from it to any new implementation ticket. The rest runs
per edge of the story DAG. As the dependency of an edge, a re-cut of a story that has no
publish ticket (the publish died before creating it) creates it as step 2 of "When the
breakdown touches a dependency repo" says, then fills in the blocker line of every
dependent that names it (step 3). As the dependent of an edge, a re-cut keeps that text
blocker line and its bump ticket; a publish blocker with no bump yet (a line the story
cut's add mode appended to the story body; ADR 0011) gets its own bump (step 4); and
every open ticket of the story that is not a bump, its publish ticket included, is blocked
natively on every bump: new ones with `--deps`, existing ones with
`bd [-C <owner>] dep add <ticket id> <bump id>`, so step 5 holds after the re-cut.

When a run has published any tickets, add one comment on the Jira epic, so a human
can see the plan without opening `bd`. It lists the tickets grouped by story: one heading
per story as `<repo> <story bead-id> <story title>`, the stories in dependency order
(step 6 below), each followed by its tickets as `<bead-id> <title>`, with the epic bead id, plus one `<repo> skipped: no
beads database` line per `skipped: <repo> no beads database` note on the epic bead (left
by "publish the stories" step 2). A `/dev:spec-to-tickets` run
adds one comment covering every story of the feature that has tickets, earlier runs'
included; a re-cut's comment covers its one story. No Jira epic, no comment.

### When the breakdown touches a dependency repo

Applies per edge of the story DAG: to each edge between stories in two repos where one
imports the other's package, and to a re-cut of a story that is already one side of such
an edge. For each edge, the story with a text blocker naming a publish ticket is the
dependent, the story with that publish ticket is the dependency. Which repo is the **dependency** is read from the dependent's `Cargo.toml` (or
`go.mod`); the repo that owns the crate is the manifest's `packages` entry for it
(resolution rule 3), since the manifest holds nodes only. In a cargo workspace the import is named in the member's manifest, or in the virtual root's `[workspace.dependencies]` when the member inherits it, and a `path =` dependency counts like a registry one; the version is read from the crate's own manifest or `[workspace.package]`, and the direction stays dependent → dependency, so the publish ticket still gates the dependent. Any other edge (a story waiting on
another story's closure, or on a human gate ticket that is not a publish) and two repos
with no import between them get no publish ticket and none of the below. A dependency
pinned by git tag (or ssh URL) is outside this rule (ADR 0003 covers registry versions
only, and a tagged dependency migrates to the registry first): stop and tell the user
rather than create a publish ticket.

Chains are in scope: a story may be the dependent of one edge and the dependency of
another (A depends on B depends on C), and a dependent may carry several publish
blockers, each with its own bump. Cycles are refused for every edge, this kind included
("Before the story quiz" above). A story has at most one publish ticket, since one PR publishes one version; a
dependency repo publishing several crates in one story stays outside this rule. A story
cut with a dependency edge runs in a workspace session, the only one with stories in two
repos. A re-cut of one side typed in its owner repo is a repo session with no
`<workspace>`, so step 3's fill-in of a story in another repo cannot run there: say so and
leave its line as it is.

1. Propose a version for each dependency's package from the change's semver impact (patch,
   minor, or major; for `0.x` a breaking change is a minor and an additive change proposes a patch bump). The user may correct it at
   the story quiz, and the publisher may correct it again at publish time.
2. Add one **publish ticket**, a human gate ticket, to each dependency story, titled
   `publish <crate> <version>`, created after that story's implementation tickets so it
   can name them; one per story, however many dependents name it:

   ```bash
   bd [-C <dep owner>] create "publish <crate> <version>" --parent <dep story-id> \
     --no-inherit-labels -l ready-for-human,complexity:low \
     --deps blocked-by:<dep ticket id>,blocked-by:<dep ticket id> --body-file -
   ```

   `<dep owner>` is the dependency repo's `<owner>` (the one test above). Every
   implementation ticket of the dependency's story is a native `blocked-by` edge, so
   `bd ready` there omits the publish ticket until they all close. Here the implementation
   tickets are every other ticket of the story, its bumps included when it is itself a
   dependent (step 6).
   `ready-for-human` is only a label (`bd ready` lists it like any other), so a person
   claims it, publishes, and closes it with the published version as the reason. The
   body is the issue template, `## Parent` as above.
3. Fill in each dependent story's text blocker for this edge: replace the `(not created
   yet)` line naming this publish with `<dep repo> <publish bead-id>` by rewriting the
   whole body with `bd [-C <dependent owner>] update <dependent story-id> --body-file -`,
   where `<dependent owner>` is the dependent repo's `<owner>` (the one test above). The
   dependent's other blocker lines stay as they are. A skipped dependency (no beads
   database) has no publish ticket, so its `(not created: no beads database)` line stays as
   it is.
4. The dependent story gets one bump ticket per publish blocker, a bump to that published
   version, titled with the proposed version, which is provisional: the publish ticket's
   close reason is authoritative. Create the bumps before the dependent story's other
   tickets, with no `--deps`; the story's text blockers hold them until every blocker
   closes. `bd ready` does not read text blockers, so it lists a bump as soon as its native
   edges allow; the frontier rule in `orchestration.md` holds it back.
5. Every other ticket of the dependent story takes a native `--deps blocked-by:<bump id>`
   on every bump, on top of its own edges, so the bumps are the dependent story's only
   tickets with no blocker inside the story.
6. The order is the story DAG's topological one. In the story cut, every story after each
   story it waits on. In the ticket cut, one topological pass over the stories: each
   story after every story it waits on, so every dependency it waits on already has its
   publish ticket. Per story, its text blocker fill-ins (step 3, one per publish blocker),
   then its bumps (step 4), then its other tickets (step 5), then, if it is a dependency,
   its own publish ticket, blocked natively on all of them (step 2). A story
   in the middle of a chain (B in A depends on B depends on C) is therefore cut after C's
   publish ticket, its own publish ticket last, and before A's fill-in.
7. The Jira comment lists each publish ticket, with its proposed version, under its
   dependency's story, and each bump under its dependent's.

## When a skill says "publish the tickets to the issue tracker" (`/mattpocock-skills:to-tickets`)

The plugin words this as "publish the tickets to the configured tracker". The plugin's
`/mattpocock-skills:to-tickets` is the flat path for a small change in the session's repo alone (the
runbook's small-bug variant): it has no stories, and its tickets are children of the epic
bead, created as in "publish a story's tickets" with `--parent <epic-id>`. It creates no
Jira epic; without a prior `/mattpocock-skills:to-spec`, create the epic bead first.
A breakdown with a slice in another repo belongs to `/dev:spec-to-stories` (then `/dev:spec-to-tickets`), typed at the workspace
root: stop and tell the user so.

## When a skill says "fetch the relevant ticket"

A `<KEY>-<n>` key → `getJiraIssue`, then `bd list --type epic --external-ref <KEY>-<n>` to
find the epic bead (a story carries the same ref). A bead id →
`bd show <id>`; follow its nearest external ref to Jira when the human context matters:
its own, else its parent's. A 404 from `getJiraIssue` means no such issue or no permission to see it; the skill reports which one it assumed.

Tickets sit two levels below the epic bead: epic → stories → tickets. `bd children
<epic-id>` lists one level, so it returns at most a repo session's home stories, never a
ticket. To reach tickets:

- **Stories**: `bd children <epic-id>` (every story in a repo session; empty in a
  workspace session), plus, in a workspace session only, every bead of type `story`
  carrying `<KEY>-<n>` in each of the manifest's repos with `.beads/` (`bd -C <repo> list
  --type story --external-ref <KEY>-<n> --all --json`). A workspace-session story has
  no parent; its external ref ties it to the feature. A repo session runs no sweep and
  says so. In a workspace session whose epic bead has no external ref, gather the epic's
  story children only and say the sweep was skipped, and why. A `bd -C` failing with
  `Operation not permitted` is "bd writes outside the session's repo" below. A sweep that
  fails any other way → report the error and stop, since that repo's story would go
  unseen.
- **Tickets of one story**: `bd -C <owner> children <story-id>` (plain `bd` in the
  owner repo), or `bd ready --parent <story-id>` for the frontier. `bd ready --parent`
  recurses through descendants and never crosses databases; with `<epic-id>` it would
  also list the open home stories, so name the story.

An epic bead whose direct children include a non-story bead is the legacy flat shape; the
story-tier skills refuse it.

## When a skill says "fetch the spec" (`/dev:spec-to-stories`, `/dev:story-to-tickets`)

The skill names `<KEY>-<n>` (or none), how it reads the epic bead, its **last resort**,
and `<id>`, the prefix of its refusals (empty for `/dev:spec-to-stories`). The spec is the
first of these that applies:

1. The spec already in the conversation context.
2. With a key, the Jira epic, fetched with `getJiraIssue` (cloud ID above): its full
   description and comments. When Jira answers that no such issue exists (a fixture key
   such as `FIX-1`), say `<KEY>-<n> is not in Jira (a 404 can also be a permission
   denial)` and go to 3. Any other Jira failure (auth, network, the Atlassian tools
   unavailable) → `<id> refused: Jira fetch failed: <error>`, stop. No key → go to 3.
3. The file a `Spec: <path>` line in the epic bead's description names, read as
   `<home>/<path>` (the line has one form, given under "gather the epic bead" below).
   Read the description from `--json` (`.[0].description`): plain `show` wraps long
   lines, so a path can split. Once read, say `cutting from the Spec: file
   <home>/<path>`. No epic bead, no `Spec:` line, or an unreadable file → go to 4.
4. The skill's last resort.

The spec only explains the work; at the ticket cut the story body bounds it.

## When a skill says "gather the epic bead" (`/dev:spec-to-stories`, `/dev:spec-to-tickets`)

`<home>` is as the one test above defines it, and `<skill>` the skill running this. Both
skills require the argument and stop on their usage line without one; neither recovers the
epic from the conversation or from the open epics (chezmoi-nz0). Find the epic bead from
the argument:

- **A key `<KEY>-<n>`**: `bd list --type epic --external-ref <KEY>-<n> --all --json` in
  `<home>`, and in a workspace session only, in every manifest repo with `.beads/` (the
  guard of the "Stories" gather above). None → the skill says what that means; several →
  ask the user which one.
- **A bead id**: `bd show <id> --json` (an array; `.[0]`). When `<home>`'s database has no
  such bead and the session is a workspace session, run `bd -C <repo> show <id> --json` in
  every manifest repo with `.beads/` (the same guard): a bead found there that is not an
  epic gets the not-an-epic refusal below, and one that is an epic is an epic bead in
  another repo. Found nowhere → `<id> refused: no such bead in <home> or any manifest
  repo`; in a repo session, which searches `<home>` alone, the line ends at `<home>`.

**The `Spec:` line.** An epic bead names its spec file with one `Spec: <path>` line in
its description, `<path>` relative to the epic bead's repo, so the file is
`<home>/<path>` (a reader reaches the epic bead only in `<home>`'s database: the
other-repo refusal below, and `/dev:story-to-tickets` step 1). The path is the whole rest of
the line: an ADR or glossary pointer goes on a line of its own. Never an absolute path:
beads sync between machines, a checkout does not. Written when the spec is published
("publish the spec", step 2); read by "fetch the spec" fallback 3.

These reads touch only `.beads/` through `bd`, never a repo's files. Refuse with one line,
and create nothing and spawn nothing, when:

- the epic bead was found in a repo other than `<home>` → `<epic-id> refused: epic bead lives in <repo>; run <skill> there`
  (the feature was begun in a repo session; a skill to move its context to the workspace
  is the follow-up `chezmoi-bz8`);
- the bead is not an epic → `<id> refused: <id> is <type>, not an epic`;
- its `status` is `closed` → `<epic-id> refused: epic bead is closed`;
- it has a direct child (`bd list --parent <epic-id> --all --json`) whose `issue_type` is
  not `story` → `<id> refused: flat epic (tickets directly under the epic bead); the story skills do not handle it — the small-bug path does: /mattpocock-skills:implement <ticket-id> per ticket, then bd close <epic-id>`.

The skill adds its own refusals after these.

## When a skill says "start work on a ticket" (`/mattpocock-skills:implement`, `/dev:implement-story`)

1. `bd update <id> --claim` (the bead already exists from the ticket cut; if it doesn't,
   create it under the story, or under the epic bead when there is none, with a
   `complexity:<tier>` label first).
2. Pick the implementation model from the bead's `complexity` tier (table below).
3. Work it; `bd note <id>` for progress worth keeping across sessions.
4. Under `/dev:implement-story` every ticket passes the check gate before merge: the ticket
   orchestrator runs the checks, and only `medium` and `high` tickets add the review. It spawns
   a reviewer subagent at the tier's review model, briefed to run the
   `mattpocock-skills:code-review` skill on the ticket's branch since the integration tip; a
   red or a blocking verdict goes to a fresh implementer in the same worktree, never back to
   the first one by `SendMessage` (`orchestration.md`, Trust rules, rule 2). The implementer
   never calls the skill itself: it would run at the implementer's own model. Under
   `/mattpocock-skills:implement` there is no ticket orchestrator: the session is the
   implementer and runs the checks and then the ticket review itself. Why:
   `docs/adr/0014-one-loop-at-three-rows.md` in the plugin repo.
5. On completion `bd close <id>`. Do not touch the Jira epic per ticket.

Every `bd` call above runs in the ticket's owner repo (`-C <owner>` when that is not
the session's), and the commit's `Bead:` trailer is the id in that repo's database.
Branch and PR notes go on the story bead (next section).

## When a skill says "the spec is done" (end of `/dev:implement-story`, `/dev:implement-spec`)

When every child of a story is closed or carries `ready-for-human`, `needs-triage` or
`wontfix`, its orchestrator (`/dev:implement-story`) delivers it and leaves the story bead
**open**; it closes at `/dev:close-story`, after the PR
merges. Delivery records the link on the story bead only:
`bd -C <owner> note <story-id> "pr: <url>"` (or `pr: <branch> <tip SHA>` when there
is no forge; the `pr:` prefix is what `/dev:close-story` looks for). The integration branch
name goes on the same bead as `branch: <name>`. That makes it a **finished story**
(`GLOSSARY.md` in the plugin repo): a later run never touches it and only reports its
PR or branch.

The Jira side belongs to `/dev:implement-spec` alone; `/dev:implement-story` has no Jira step,
whoever runs it. `/dev:implement-spec` does it once, in the first invocation that ends with every
story finished (`ready-for-human` tickets aside): `addCommentToJiraIssue` on the Jira
epic listing every story's link once, with a one-paragraph summary, then
`transitionJiraIssue` to the project's in-review state — an In-Progress-category status
with `review` in its name; none → comment only. A run that starts with every story
finished first checks the Jira epic's status and comments, and skips both when either
shows they were made.

## When a skill says "close the epic" (`/dev:close-epic`, after the PRs merge)

The steps live in the skill; the rules it enforces are:

- **Per-story check**: every story, the home stories and the stories found by external ref
  in other repos, passes `/dev:close-story`. A story already `closed` is skipped.
  `retro`-labelled beads carrying the ref are not stories and are skipped.
- `/dev:close-story` refuses, with no override, unless every child of the story is
  closed or carries `needs-triage` or `wontfix` (the publish ticket is a ticket like any
  other; a child carrying one of those labels is a note, not a ticket, as the finished
  story above counts it, and it stays open for `/dev:triage`) and its `pr:` note exists and the forge state is `MERGED`
  (not merely `CLOSED`; no forge → ask for an explicit yes). The refusal names each open
  child with its status and triage label. Then it closes the story bead, with no Jira.
- `/dev:close-epic` refuses if any story refuses. Stories close before the epic bead. Then
  `bd close <epic-id>`, `addCommentToJiraIssue` with every story's PR link once, and
  `transitionJiraIssue` to the Done-category status — several candidates → ask.

## When a skill says "capture a retro item" (`/dev:retro`)

The **inbox** is the home's beads database (the one test above): the workspace's in a
workspace session, the home repo's in a repo session. `bd` runs plainly, in `<home>`.
When `<home>/.beads` is missing, stop: no skill initialises a database unattended. Every
surviving candidate becomes one bead there:

```bash
bd create "<title>" --type chore -l retro,needs-triage,<target label> \
  [--external-ref <KEY>-<n>] --body-file -
```

`<target label>` in a workspace session is `target:<repo>`, the manifest entry whose
repo owns the file the fix would change; `target:<home name>` when the workspace root
itself owns it (`repos.yaml`, workspace ADRs), and `target:unknown` when none matched. In
a repo session it is `target:<home name>` when that file is inside `<home>`, else
`retro:foreign`, with the intended location in the body. A file under the plugin root
(`<plugin root>`, the Plugin root rule in `orchestration.md`) counts as the plugin repo's
(`vangogh500/claude-dev-plugin`) under the rules above, wherever the plugin is installed,
and the body names its path relative to that root. A deployed file (one under
`~/.claude`, say) counts by its source when `chezmoi source-path <file>` maps it back:
the body names the source path, not the deployed one. When that command fails for any
reason (the file is not chezmoi-managed, chezmoi is absent, or the sandbox denies it its
config with `Operation not permitted`), the file counts as it stands, so outside `<home>`
it is `retro:foreign` with the deployed path in the body. `/dev:retro` can run unattended, so
it never reruns this outside the sandbox. `<KEY>-<n>` is
the Jira epic of the spec the session implemented, when there was one. The retro files;
`/dev:triage` decides. No Jira issue is created here.

## When a skill says "route a triaged item" (`/dev:triage`)

An accepted item becomes a bead in the repo that owns the change, using the issue
template, then its inbox bead closes pointing at it:

```bash
bd [-C <owner>] create "<title>" --type chore -l complexity:<tier>,retro,<ready label> \
  [--external-ref <KEY>-<n>] --acceptance "<criteria>" --body-file -
bd close <inbox-id> --reason "routed: <owner repo> <new-id>"
```

In a workspace session the owner is the manifest's repo, or `<home>` itself when the
file is the workspace's own or outside every manifest repo (then routed like
`retro:foreign`); `-C <owner>` only when the owner is not `<home>` (the one
test above). In a repo session it is always `<home>`: no `-C`, and `<owner repo>` is
`<home name>`. When owner and inbox are one database the shape is the same, a new bead
and the inbox bead closed, never a relabel in place.

`<ready label>` is `ready-for-agent`, or `ready-for-human` when the fix needs a person; a
`retro:foreign` item, or a workspace-session file outside the manifest, is always
`ready-for-human`, since a person carries it across. A rejected item gets `wontfix` and
closes with that reason. No Jira issue per item; in a workspace session whose manifest
names `triage.jira-epic`, one `addCommentToJiraIssue` per triage run lists what was routed
where. The closed inbox beads are the record of every item's fate:
`bd list -l retro,needs-triage --all` in the home (`-l` matches all its labels; a routed
bead carries `retro` but never `needs-triage`, and an inbox bead keeps `needs-triage`
when it closes).

### bd writes outside the session's repo

`bd -C <other repo>` writes to that repo's `.beads/`. With `~/src` in the sandbox's read
and write allowlists, a per-machine line the owner adds to their user settings by hand
(`/dev:setup`'s baseline leaves it out), any repo under a workspace is reachable from any
session with no prompt. A repo outside the allowlists fails with `Operation
not permitted`: that is the sandbox, so rerun that one command with the sandbox disabled;
it still passes the permission gate.

## Complexity labels (beads only)

Every ticket gets exactly one `complexity:<tier>` label when it is created; an epic bead,
a story, an inbox bead and a map bead carry none. The tier picks the model for
implementation and for review. Jira never carries this label; it is an agent-routing
concern.

| Label               | Looks like                                                                                                                              | Implement with | Review with |
| ------------------- | --------------------------------------------------------------------------------------------------------------------------------------- | -------------- | ----------- |
| `complexity:low`    | One file or mechanical change; spec fully determines the code; no design choices; existing tests cover it                               | `haiku`        | `sonnet`    |
| `complexity:medium` | Several files; some judgement on structure or naming; new tests needed; no concurrency, public-API, or persisted-format changes         | `sonnet`       | `opus`      |
| `complexity:high`   | Cross-cutting; touches concurrency, public API of a published crate, or persisted/wire formats; spec leaves real decisions open; a wrong answer is expensive to unwind | `opus` | `fable` |

Rules:

- The reviewer is always one tier of model above the implementer. A same-tier reviewer
  shares the implementer's blind spots; the step up is where review earns its cost.
- When unsure between two tiers, pick the higher one; downgrading later is cheap.
- Re-label if the work turns out harder than estimated (`bd label remove <id> complexity:<old>`
  then `bd label add <id> complexity:<new>`) and say so with `bd note`, so estimate-vs-actual
  stays visible.
- A story's tier is the max of its tickets'. The final two-axis review runs per story at
  that tier's review model, as `orchestration.md` "Complexity tier" says.

Applying it: when a skill spawns an implementation or review subagent, pass the mapped
model via the Agent tool's `model` parameter. When the session does the work itself, with
no subagent, state the bead's tier so the user can `/model` accordingly.

Queries: `bd list -l complexity:high` for work that needs the big model;
`bd ready -l complexity:low` for cheap, grabbable work.

## Wayfinding operations

Used by `/mattpocock-skills:wayfinder`. Wayfinding is agent-internal, so it lives in beads only; promote
a resolved decision to Jira with a comment on the originating `<KEY>-<n>` when it matters
to humans.

- **Map**: an epic bead (`bd create "<effort>" --type epic -l wayfinder:map`) whose
  description holds the Notes / Decisions-so-far / Fog body.
- **Child ticket**: `bd create "<question>" --parent <map-id> -l type:<research|prototype|grilling|task>`.
- **Blocking**: `--deps blocked-by:<id>` at creation, or `bd dep add` later.
- **Frontier**: `bd ready --parent <map-id>` — open, unblocked, unclaimed beads.
- **Claim**: `bd update <id> --claim` before any work.
- **Resolve**: `bd note <id> "<answer>"`, `bd close <id>`, then append a context pointer
  (gist + bead id) to the map bead's Decisions-so-far via `bd update <map-id> -d`.

## PRs as a request surface

Off. Pull requests are not a triage queue.
