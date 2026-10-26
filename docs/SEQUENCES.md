# Sequence diagram

How a feature is implemented, drawn once: the loop every row runs. This page explains and
decides nothing. The rules are in `docs/agents/orchestration.md`: the loop and its table
(The loop), the two scoping rules (Scoping rules), the six trust rules (Trust rules), the
check gate and the review verdict (Review) and the frontier (Frontier). The why is in
`docs/adr/0014-one-loop-at-three-rows.md`, ADR 0006 and ADR 0011. When the diagram and those
texts disagree, the texts win and the diagram is the bug. Bold terms are defined in
`GLOSSARY.md`.

## The loop

The ticket, the story and the epic are one loop at three rows. The diagram draws the row
in general, with `O` the row's orchestrator and the unit a ticket, a story or an epic. Each
row's parameters are the model doc's table (`docs/agents/orchestration.md`, The loop): the
Fix-up column is where the rows differ most, and the diagram draws all three of its cases.

```mermaid
sequenceDiagram
    autonumber
    participant O as Orchestrator (the row's)
    participant BD as bd (the owner repo, the home database for the epic row)
    participant I as Builder (an implementer, or the orchestrators of the row below)
    participant V as Reviewer (review model, one tier up)
    participant F as Fix-up (per the row's Fix-up column)
    participant IN as Inbox (plain bd, home)
    participant U as Row above (or the human)

    Note over F: ticket row, a fresh implementer in the same worktree
    Note over F: story row, a fresh implementer in a fix-up worktree
    Note over F: epic row, no implementer, O files the findings as ready-for-agent tickets under the story and re-runs that story in add mode

    O->>BD: claim the unit, read its tier
    O->>I: spawn the builder (a worktree, or the row below)
    I-->>O: ready for review

    loop the checks, then the review on green, three fix-ups per unit (the epic row, three per story)
        O->>O: run the check command on the tip unless its tree has a record, and write the record (the epic row reads the forge's status on the PR tip)
        alt the checks are red
            O->>BD: note the failing command and its log
            O->>F: fix-up by pointer brief
            F-->>O: report, the loop starts over from the checks
        else checks green, the ticket row at low, no reviewer
            Note over O: the loop exits on green
        else checks green
            O->>V: spawn the review, the row's axes (the epic row, the spec axis only)
            V-->>O: findings tagged blocking or minor, last line the verdict
            O->>BD: note the review with the verdict line
            Note over O: the story row also records the reviewed tip in its notes
            alt verdict blocking
                O->>F: fix-up pointed at that note
                F-->>O: report, the loop starts over from the checks
            else verdict clean (minors or none)
                Note over O: no reviewer runs again, the loop exits
            end
        end
    end

    alt fourth failure, a red or a blocking verdict after the budget
        O-->>U: report failed with the reason
    else clean
        opt minors in scope
            O->>F: one last fix-up for the minors (unreviewed, no budget spent)
            F-->>O: report
            O->>O: the tip moved, rerun the check command, the gate exits on the moved tip once green
        end
        opt minors out of scope
            O->>IN: capture a retro item (needs-triage), never to a bead of the story
        end
        alt ticket row
            O->>O: wait on the owner checkout's lock
            O->>O: stray-commit check
            O->>O: merge onto the integration branch
            opt the merge conflicts
                O->>F: an implementer in the ticket worktree merges the integration tip in
                F-->>O: report, O runs the check command on the resolved tree, then fast-forwards
            end
            O->>BD: close the ticket's bead
        else story or epic row
            O->>O: stray-commit check
            O->>U: push (story, draft PR) or mark the PR ready (epic)
            Note over BD: the story and epic beads stay open, /dev:close-story and /dev:close-epic close them after the merge
        end
        O->>U: landed, one line
    end
```
