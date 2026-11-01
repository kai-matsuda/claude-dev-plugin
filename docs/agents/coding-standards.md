# Coding standards (the dev plugin's defaults)

Rules the **reviewer** applies to every diff, in every repo: the Standards axis of
`mattpocock-skills:code-review` in `/dev:implement-story`'s **Story gate**. A repo's
own `CODING_STANDARDS.md` adds to these and wins where they conflict. Anything a
linter, type checker, test or hook can enforce belongs in that tool, not here.

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

## Bead ids cite provenance in parentheses

A sentence in a rules doc (`docs/agents/*.md`, a skill's `SKILL.md`) or a comment in a lint
script that records why a rule exists names the bead behind it as a **provenance cite**: the
bare id inside parentheses that close the clause it justifies, as in "a flaky red never
sticks to its tree (dev-6qi)". The same form serves prose and lint comments. The parentheses
may hold a short qualifier beside the id, set off by a comma or a space ("(chezmoi-cdf,
ADR 0010)", "(dev-b8d.1 story review 1)"), never a semicolon or a clause; a longer
explanation goes outside the parentheses. A cite is never a bare id woven into the
sentence, a possessive ("dev-6qi's run") or a footnote.

A bead named as the subject of a sentence rather than as the reason for it (a worked
example, an id the text matches or builds) is not a cite: it stays in backticks
("`dev-b8d.1` does not match `dev-b8d.1.4`").

Flag a cite outside parentheses, or a cited id woven into the sentence or possessive.

## Another skill's rule is cited in one form

A sentence in a rules doc (`docs/agents/*.md`) or a skill's `SKILL.md` that cites a rule
another skill owns names the skill and cites the rule in the form of the rule's own marking.
A rule the skill's `SKILL.md` marks with a bold step name is cited in bold
(`/dev:implement-story`'s **Story gate**, the **Clean up** sweep of `/dev:implement-story`);
a rule it marks with a heading is cited by the heading's words in quotes, the skill named
beside them (`/dev:close-story`'s "The forge shows MERGED", `/dev:story-to-tasks`'s "Gather
context"). A bold step name is a bold name that opens a line, after any indent or `- `
marker, opens on a letter or a backtick, and either opens a numbered item or ends on a
period inside the bold (`**Story gate.**`, `- **Stall.**`). A bold lead-in with no period
that opens no numbered item (`**Owner**`, `**Alone**:`) is a label, and a bold term inside
a sentence (the **story orchestrator**) is neither; a cite of a label or such a term is
outside this rule, so a lead-in that another skill or a rules doc cites takes the period
inside the bold and is cited in bold. A heading cited bare (`/dev:task-orchestrator`'s
Two entries) or a step name cited in quotes is a cite in the wrong form. A cite of the
rules doc's own sections, or of a skill's own steps and headings, is not a cross-skill
cite and is outside this rule.

A cite names the skill in backticks (`/dev:close-story`), never bare (/dev:close-story's
"The forge shows MERGED"), and never in bold or quotes; a backtick at one end of the skill
only, or one that swallows its possessive (`/dev:close-story's`), leaves it bare. A cited
step or heading is marked only by bold or quotes, one of the two and not both: a name inside
a pair of backticks is a cite in the wrong form, whether the pair stands inside the mark
(**`Story gate`**), around it (`**Story gate**`) or alone (`Story gate`), and whether or not
the skill is in backticks. A backtick that is part of a name stays in it: the step **`git`
rule** of `/dev:task-orchestrator` is cited in bold, its backticks included. A skill named
bare in prose that cites none of its rules ("run /dev:close-story", "/dev:close-story's Jira
key") is outside this rule.

The lint reads the shapes below and nothing more. It reads a skill beside a step or heading
name that skill's `SKILL.md` has, in three places: after the skill's possessive and an
optional "step" or "section"; straight after the skill, with an optional comma, colon or
semicolon or a spaced hyphen or em dash, and any of "the", "step" and "section"; and before
"of" or "in" the skill, at most two words of letters between. The skill is in backticks,
bare, or has a backtick at one end only or around its possessive; in the "of"/"in" order a
backtick before the skill leaves it backticked (see below), and only one after it is stray.
The marks are straight double quotes, `**` and backticks, around the name alone, with an
optional period, comma, colon or semicolon after the name inside the marks, right after them
or between two of them. Names match in any case, except a bare name straight after a skill,
which matches in its own case only ("/dev:implement-story story gate" passes). In those
places the lint fails a bare skill beside a name in the right mark; a name in the wrong mark
(a step in quotes, a heading in bold) or a bare heading; and a name inside backticks, alone
or with bold or quotes inside or around the pair, whatever the skill's form. A name that is
both a step and a heading takes either mark. Bare prose that spells a name in those places
fails too ("the steps of /dev:implement-story", "/dev:task-orchestrator's report", "run bd
story gate in /dev:implement-story", a lower-case spelling included); the fix is a reword. A
capital word after a backticked possessive fails whether it is a name or not
(`/dev:implement-story`'s Jira key).

Every other shape is outside what the lint reads, among them: curly quotes and apostrophes,
en dashes and an em dash with no space around it, a separator with no space, single quotes,
italics, double backticks, a name in both bold and quotes, a skill set in bold or quotes,
any other punctuation outside the marks, a one-sided mark (a bold or quote mark that opens a
name and is never closed, or closes one never opened), a stray backtick beside a right mark,
a backtick straight before a name that follows the skill or its possessive (with an optional
"step" or "section", comma, colon, semicolon or dash, and "the", "step" or "section"
between), a stray closing backtick after a bare name in the before-"of"/"in" place with no
space after it, a space before or after a name inside the backticks, or at both ends of it,
a bold lead-in with no period that opens no numbered item, a hyphenated word between a name
and "of" or "in", a link word other than "of" or "in", a name straight before the skill with
no link word, a parenthesis between the skill and the name or before the skill in the
"of"/"in" order (a parenthesis around the whole cite is read), any words beside a skill
other than those three places, and a backtick straight before the skill in the "of"/"in"
order, whatever follows the skill (arguments, a suffix, words, punctuation or nothing, a
closing backtick or none): it is a backticked skill, so the right mark beside it passes.

A bare, quoted, bold or backticked name before such a skill is still read and fails. A
backtick before a name in the "of"/"in" order, or straight after a bare name anywhere, is
read and fails, except the closing backtick after a bare name before "of"/"in" with no space
after it, which the list above leaves unread. The first paragraph above says which forms are
wrong; the lint fails them only in the shapes the paragraph that begins "The lint reads"
names, and any shape it does not read is outside the lint. A reader still writes the one
right form.
