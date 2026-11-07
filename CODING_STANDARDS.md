# Coding standards

Rules the reviewer applies to every diff in this repo, in addition to the dev plugin's
defaults (`docs/agents/coding-standards.md`): the Standards axis of
`mattpocock-skills:code-review` reads this file. Anything a linter, test or hook can
enforce belongs in that tool, not here. Rules are judgement calls unless their heading
is tagged *hard*.

## A verified value is the value every later step uses

In a shipped script, once a guard verifies a value (a SHA, a path, a branch state), every
later step acts on that verified value, never on the name it was resolved from. A name
can move between the check and the use, so the guard then vouched for something the step
never touched.

Reason: `scripts/land.sh` checked that `refs/heads/<task branch>` was at
`<tip>`, then merged by branch name. The branch could move in between, so the merge could
take commits the guard and the stray-commit check never saw. The gap passed the task
review and the story review, and only an outside security review caught it (dev-fb36, INFRA-42).

- Wrong: `[ "$(git rev-parse "refs/heads/$task")" = "$tip" ] || refuse; git merge "$task"`
- Right: `[ "$(git rev-parse "refs/heads/$task")" = "$tip" ] || refuse; git merge "$tip"`

Check every script change that reads a ref, path or state to guard on, and flag each
later step that re-resolves the same name instead of using the value checked.
