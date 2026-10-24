---
status: superseded
---

# One repo manifest in the dotfiles, nodes only

Superseded by `docs/adr/0004-manifest-at-workspace-root.md` in this repo. The manifest
moved to the workspace root because only the checkout root is a machine fact; the repo
list, URL template, registry, and crate names describe the organisation and must be
clonable by a teammate. The dotfiles keep only a pointer to where workspaces live. The
text below is the decision as originally taken.

Skills that file work into beads sometimes find that the fix belongs in a different
repo from the one the session runs in: a `/dev:retro` candidate aimed at a dependency crate,
or an `/dev:implement-spec` ticket that needs a library change. beads is per-repo, so
something must map a file, crate, or module to the repo and `.beads/` that own it.
That map is one file, `repos.yaml`, kept with the rules docs and deployed per machine. It lists which repos exist, where each is checked
out, and which crate or module names each publishes. It does not record which repo
depends on which; `Cargo.toml` and `go.mod` already hold that and would be duplicated.

## Considered options

- **A monorepo or cargo workspace spanning the crates.** Removes the routing problem
  entirely. Rejected for now because the crates ship separately through the private
  `lynx` registry and are consumed by version; folding them together is a bigger move
  than a tracking fix justifies.
- **A sibling-checkout convention and no file.** Package name resolves to
  `../<name>`. Rejected because crate names here do not match repo names
  (`chain-decoder` publishes `decode-core`; `chain-types` publishes `chain-position`),
  so the convention fails on exactly the lookups that matter.
- **Per-repo declarations in each consumer's `.beads/config.yaml` (`bd repo add`).**
  Puts the knowledge next to the dependency it mirrors. Rejected because it is N files
  instead of one, each holding machine-specific paths that drift separately, and
  `bd repo add` exists for hydration into one view, not for routing.

## Consequences

- Every new internal repo needs one entry here. A missing entry fails loudly: the
  resolution falls through to its last rule and the item lands in the current repo
  labelled `retro:foreign`, which is the prompt to add the entry.
- The manifest lives in chezmoi because "where are my repos checked out" is a
  machine-setup fact, like the rest of the dotfiles. It doubles as the bootstrap list
  for a new machine.
- Skills read the manifest; nothing else does. The retro and implement-spec forks are
  the intended consumers, and until they reference it the file is documentation only.
- A repo that receives a routed item must have `.beads/`; most of the listed repos do
  not yet. Initialising each is a one-time `bd init` done on first routed item, not up
  front.
