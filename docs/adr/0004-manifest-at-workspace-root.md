---
status: accepted, amended by ADR 0008
---

> Amended by `0008-session-mode-declared-by-where-it-starts.md`: skills no longer find
> the manifest by walking up from a checkout. A session routes through it only when the
> session's own repo root holds `repos.yaml` (a workspace session); a session inside a
> checkout ignores any workspace above it. The manifest's location, contents and
> resolution order are unchanged.

# Agent skills route work through one repo manifest at the workspace root

Agent skills sometimes find that a change belongs in a different repo from the one the
session runs in: a `/dev:retro` candidate aimed at a dependency crate, or an `/dev:implement-spec`
ticket that needs a library change. Issue tracking (`bd`) is per repo, so something must
map a file, crate, or module to the repo and `.beads/` that own it. That map is
`repos.yaml`, at the root of the workspace. The workspace is a repo of its own that holds
the other repos' checkouts as gitignored sibling directories, so the file is versioned
with the workspace and not with any one of them. Skills find it by walking up from any
checkout inside the workspace.

The manifest lists nodes only: which repos exist, where each is checked out, and which
crate or module names each publishes. It does not record which repo depends on which; each
repo's own build manifest already holds that, and a copy would drift.

The resolution order in the manifest header is the contract. Skills apply its rules in
order and stop at the first hit. A miss does not drop the item: it is filed in the current
repo, labelled as foreign, with the intended target in the body. A repo with no `.beads/`
is a finding of its own, to be initialised before anything is routed into it.

Facts specific to one workspace (its registry, its clone location, its repo list) live in
that workspace's own ADR at its root.

## Considered options

- **A monorepo or single build spanning the packages.** Removes the routing problem
  entirely. Rejected when the packages ship separately and are consumed by version;
  folding them together is a bigger move than a tracking fix justifies.
- **A sibling-checkout convention and no file.** A package name resolves to `../<name>`.
  Rejected because package names do not always match repo names, so the convention fails
  on exactly the lookups that matter.
- **One declaration per consumer repo (`bd repo add`).** Puts the knowledge next to the
  dependency it mirrors. Rejected because it is one file per repo with machine-specific
  paths that drift separately, and `bd repo add` exists for hydrating several databases
  into one view, not for routing.
- **One file in the user's dotfiles.** Rejected because only where the workspace sits on
  one machine is a machine fact. The repo list and what each repo publishes describe the
  workspace, and a teammate cannot clone someone else's dotfiles to get them.

## Consequences

- Every new repo in a workspace gets one entry. A missing entry fails loudly: the
  resolution falls through to its last rule and the item lands in the current repo
  labelled `retro:foreign`, which is the prompt to add the entry.
- Decisions that span repos go in the workspace's `docs/adr/`; decisions about one repo
  stay in that repo's own `docs/adr/`.
- A repo that receives routed items needs its own `.beads/`. Run `bd init` there on the
  first routed item, not up front.
- Skills must be able to read the workspace root from a session running inside a checkout.
  Allowing that read path is a sandbox setting each workspace owns; it is not part of this
  rule. Amended by ADR 0008: a session inside a checkout never reads above its own repo,
  so no such read path is needed. The sandbox setting a workspace owns is the other way
  round: a session at the workspace root reaching into its checkouts with `bd -C`.
