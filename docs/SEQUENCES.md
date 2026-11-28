# Sequence diagram

How a feature is implemented, drawn once: the loop every tier runs. This page explains and
decides nothing. The rules are in `references/orchestration.md`: the loop and its table
(The loop), the two scoping rules (Scoping rules), the six trust rules (Trust rules), the
tier gates and the review verdict (Review) and the frontier (Frontier). The why is in
`docs/adr/0014-one-loop-at-three-rows.md`, ADR 0006 and ADR 0011. When the diagram and those
texts disagree, the texts win and the diagram is the bug. Bold terms are defined in
`GLOSSARY.md`.

## The loop

The task, the story and the epic are one loop at three tiers. The diagram draws the tier
in general, with `O` the tier's orchestrator and the unit a task, a story or an epic. Each
tier's parameters are the orchestration doc's table (`references/orchestration.md`, The loop): the
Fix-up column is where the tiers differ most, and the diagram draws all three of its cases.

```mermaid
sequenceDiagram
    autonumber
    participant O as Orchestrator (the tier's)
    participant BD as bd (the owner repo, the home database for the epic tier)
    participant I as Builder (an implementer, or the orchestrators of the tier below)
    participant V as Reviewer (review model, on the next model up)
    participant F as Fix-up (per the tier's Fix-up column)
    participant IN as Inbox (plain bd, home)
    participant U as Tier above (or the human)

    Note over F: task tier, a fresh implementer in the same worktree
    Note over F: story tier, a fresh implementer in a fix-up worktree
    Note over F: epic tier, no implementer, O files the findings as ready-for-agent tasks under the story and re-runs that story in add mode

    O->>BD: claim the unit, read its complexity
    O->>I: spawn the builder (a worktree, or the tier below)
    I-->>O: ready for review

    loop the checks, then the review on green, three fix-ups per unit (the epic tier, three per story)
        O->>O: run the check command on the tip unless its tree has a green record, and write the record (the epic tier reads the forge's status on the PR tip)
        opt task tier, the diff adds or changes a fixture case
            O->>O: seed the case, one subagent follows the seed's brief, assert it and keep the assert record (a failing assert is a red)
        end
        alt the checks are red
            O->>BD: note the failing command and its log
            O->>F: fix-up by pointer brief
            F-->>O: report, the loop starts over from the checks
        else checks green, the task tier at low with no comment, doc, skill text or test header describing behaviour in its diff, no reviewer
            Note over O: the loop exits on green
        else checks green, any other tier or complexity
            O->>V: spawn the review, the tier's axes (the epic tier, the spec axis only, a low task the standards axis alone)
            V-->>O: findings tagged blocking or minor, last line the verdict
            O->>BD: note the review with the verdict line
            Note over O: the story tier also records the reviewed tip in its notes
            alt verdict blocking
                O->>F: fix-up pointed at that note, its blockers and its in-scope minors (the rest, and every minor at the epic tier, to the inbox at once)
                F-->>O: report, the loop starts over from the checks
            else verdict clean (minors or none)
                Note over O: no reviewer runs again, the loop exits
            end
        end
    end

    alt fourth failure, a red or a blocking verdict after the budget
        O->>IN: capture every minor no fix-up report names as fixed, never at the epic tier (needs-triage)
        O-->>U: report failed with the reason
    else clean
        opt minors in scope, never at the epic tier
            O->>F: one last fix-up for the minors (unreviewed, no budget spent)
            F-->>O: report
            O->>O: the tip moved, rerun the check command, the gate exits on the moved tip once green
        end
        opt minors out of scope, a minor a fix-up reported as left unfixed or reported fixed with its named file and line untouched by the diff, and every minor at the epic tier
            O->>IN: capture a retro item (needs-triage), never to a bead of the story
        end
        alt task tier, the owner checkout untouched
            O->>U: reviewed, one line with the task branch, its worktree and its tip
            Note over U: the story tier lands it, serially, one landing per report, no lock
            U->>U: stray-commit check
            U->>U: merge onto the integration branch
            opt the merge conflicts, at most three resolutions per landing (the fourth fails the task)
                U->>F: an implementer in the task worktree merges the integration tip in
                F-->>U: report, U runs the check command on the resolved tree, then fast-forwards
                Note over U: a red there fails the landing, and the task's retry enters at the gate on the resolved branch
            end
            U->>BD: close the task's bead
        else story or epic tier
            O->>O: stray-commit check
            O->>U: push (story, draft PR) or mark the PR ready (epic)
            Note over BD: the story and epic beads stay open, /dev:close-story and /dev:close-epic close them after the merge
            O->>U: landed, one line
        end
    end
```
