# Coding standards (the dev plugin's defaults)

Rules the **reviewer** applies to every diff, in every repo: the Standards axis of
`mattpocock-skills:code-review` in `/dev:implement-story`'s **Story gate**. A repo's own
`CODING_STANDARDS.md` adds to these and wins where they conflict. Anything a linter,
type checker, test or hook can enforce belongs in that tool, not here.

Rules are judgement calls unless their heading is tagged *hard*. Report each breach with
the rule's heading, the file and line, and the concrete reader who would be misled or
broken.

## Doc claims carry their conditions

A doc comment, README or changelog line that describes behaviour states the conditions
it holds under, rather than an unconditional guarantee. When the behaviour depends on
the runtime (current-thread vs multi-thread), scheduling, platform, configuration or a
dependency's internals, the sentence names that dependency, says what happens outside
it, and points at the knob that controls it.

- Unconditional: "a sink that never yields can't starve the producer".
- Conditioned: "on a multi-thread runtime, a sink that never yields can't starve the
  producer; on a current-thread runtime the two tasks take turns".

Check every changed sentence that promises timing, ordering, batching, fairness,
"never" or "always". The rule covers descriptions, not instructions: in an agent doc,
"never say bare `/code-review`" is an instruction and passes, while "the built-in skill
runs at whatever model invokes it" describes behaviour and is checked.

## Docs change with the behaviour they describe

When a diff changes behaviour that a README, runbook, skill or doc comment describes,
that text changes in the same change. Where the previous rule checks the sentences a
diff touches, this one checks for the sentences it should have touched: search the repo
for prose naming the changed command, flag, step or default, and flag each one left
describing the old behaviour.

## Breaking changes include bounds and auto-traits (Rust; hard)

In a library crate with callers outside its workspace (published to crates.io or
consumed as a git dependency), these break callers as surely as a removed item:

- a new trait bound on a public type, function or method, including a `where` clause
  on a struct, which every generic user of the type must then restate;
- a field change that alters an auto-trait (`Send`, `Sync`, `Unpin`), such as wrapping
  a field in `Arc<T>`, which makes `Send` require `T: Sync`.

Each one belongs in the changelog's breaking section and, when there is one, the spec's
API-change table. `cargo semver-checks` misses both, so review is the only gate. A raised
dependency floor or MSRV is not breaking under Cargo's resolver, but it still gets a
changelog line. Binaries and workspace-internal crates are out of scope: there the
compiler catches the break in the same change.

## New concepts enter the glossary in the same change

When a diff introduces a domain term (a new type, state or verb that callers must
understand), `GLOSSARY.md` gains its entry in the same change, using the format the
glossary already has. Prose uses the glossary's term, not a synonym it lists under
"avoid". Applies only when the repo already has a `GLOSSARY.md` or `GLOSSARY-MAP.md`;
a missing glossary is never flagged. See `domain.md` for where glossaries live.

## Contradicting an ADR amends it in the same change

When a diff contradicts an `accepted` ADR, the same change either amends that ADR or
adds a new one that supersedes it (marking the old one `superseded`). Applies only
when the repo has a `docs/adr/` directory; see `domain.md` for where ADRs live.
