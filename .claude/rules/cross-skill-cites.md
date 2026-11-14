---
paths:
  - "skills/**/SKILL.md"
  - "references/*.md"
---

# Another skill's rule is cited in one form

A sentence in a reference doc (`references/*.md`) or a skill's `SKILL.md` that cites a rule
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
outside this rule, so a lead-in that another skill or a reference doc cites takes the period
inside the bold and is cited in bold. A heading cited bare (`/dev:task-orchestrator`'s
Two entries), a heading cited in bold, or a step name cited in quotes is a cite in the wrong form. A cite of a
reference doc's own sections, or of a skill's own steps and headings, is not a cross-skill
cite and is outside this rule.

A cite names the skill in backticks (`/dev:close-story`), never bare (/dev:close-story's
"The forge shows MERGED"); a backtick at one end of the skill
only, or one that swallows its possessive (`/dev:close-story's`), leaves it bare. A cited
step or heading is marked only by bold or quotes, one of the two and not both: a name inside
a pair of backticks is a cite in the wrong form, whether the pair stands inside the mark
(**`Story gate`**), around it (`**Story gate**`) or alone (`Story gate`), and whether or not
the skill is in backticks. A backtick that is part of a name stays in it: the step **`git`
rule** of `/dev:task-orchestrator` is cited in bold, its backticks included. A skill named
bare in prose that cites none of its rules ("run /dev:close-story", "/dev:close-story's Jira
key") is outside this rule. A name that is both a step and a heading takes either mark. Bare
prose that spells a name beside a skill is wrong too; the fix is a reword.

The section 18 comment of `scripts/lint-skill-docs.sh` lists the shapes the lint reads and the
shapes it leaves open; any shape it does not read is outside the lint, and a reader still
writes the one right form.
