# Sequence diagram

How a feature is implemented, drawn once: the loop every row runs. This page explains and
decides nothing. The rules are in `docs/agents/orchestration.md`: the loop and its table
(The loop), the two scoping rules (Scoping rules), the six trust rules (Trust rules), the
check gate and the review verdict (Review) and the frontier (Frontier). The why is in
`docs/adr/0001-two-stage-review.md`, ADR 0006 and ADR 0011. When the diagram and those
texts disagree, the texts win and the diagram is the bug. Bold terms are defined in
`GLOSSARY.md`.

## The loop

The ticket, the story and the epic are one loop at three rows. The diagram draws the row
in general, with `O` the row's orchestrator and the unit a ticket, a story or an epic. The
table in the model doc gives each row its parameters, and they are the words in the
diagram's notes.

| Parameter | Ticket row | Story row | Epic row |
|---|---|---|---|
| Orchestrator | ticket orchestrator | story orchestrator | epic orchestrator |
| Builds | one implementer in a worktree | ticket orchestrators in parallel over the frontier | story orchestrators in parallel over the frontier |
| Checks | the check command | the check command | the check command as the forge runs it |
| Reviewer | both axes, at the ticket's review model, none at `low` | both axes, at the review model of the story's max tier | the spec axis only, at the review model of the epic's max tier |
| Lands by | merge onto the integration branch | push, the PR staying a draft | the PR marked ready, the human merges |
| Exits when | the checks green on the tip the review called clean | the checks green on the tip the review called clean | the checks green on the tip the review called clean |
| Budget | three fix-ups | three fix-ups | three per story |

```mermaid
sequenceDiagram
    autonumber
    participant O as Orchestrator (the row's)
    participant BD as bd -C owner
    participant I as Implementer (impl model)
    participant V as Reviewer (review model, one tier up)
    participant F as Fix-up implementer (impl model, same worktree)
    participant IN as Inbox (plain bd, home)
    participant U as Row above (or the human)

    O->>BD: claim the unit, read its tier
    O->>I: spawn the builder (a worktree, or the row below)
    I-->>O: ready for review

    loop the checks, then the review on green, reds and blocking verdicts share three fix-ups
        O->>O: run the check command on the tip, write the check record
        alt the checks are red
            O->>BD: note the failing command and its log
            O->>F: spawn a fresh fix-up with a pointer brief
            F-->>O: report, the loop starts over from the checks
        else checks green, no reviewer at this row or tier
            Note over O: the loop exits on green
        else checks green
            O->>V: spawn the review, spec axis and standards axis
            V-->>O: findings tagged blocking or minor, last line the verdict
            O->>BD: note the review with the verdict line
            alt verdict blocking
                O->>F: spawn a fresh fix-up pointed at that note
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
        end
        opt minors out of scope
            O->>IN: capture a retro item (needs-triage), never a bead of the unit
        end
        O->>O: stray-commit check, then land the unit
        O->>U: landed, one line
    end
```
