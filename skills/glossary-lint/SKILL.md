---
name: glossary-lint
description: "Lint a repo's prose against the _Avoid_ terms in its GLOSSARY.md files, triage the hits, and wire the check into the repo's gates."
disable-model-invocation: true
---

`glossary-lint.sh` in this skill's directory is the check. It reads every tracked
`GLOSSARY.md`, applies each to the files under its own directory, and flags prose
(Markdown and doc comments, minus code) that uses a word the glossary lists under
`_Avoid_:`. Repos opt in by calling this one copy from their gates (step 3); a repo adds
a `.glossary-allow` only for words it cannot reword.
The script's header comment is the reference for scope, allowlist format and exit
codes.

## 1. Run it

From the repo: `sh ${CLAUDE_PLUGIN_ROOT}/skills/glossary-lint/glossary-lint.sh`. No `GLOSSARY.md`
→ it says so and exits 0; report that and stop.

## 2. Triage every hit

Read each flagged line in context and fix it with the first of these that fits:

1. **Code span**: the word is a library or API name (tokio's `abort()`, axum's
   `with_graceful_shutdown`). Put it in backticks; the check skips code, and the docs
   read better for it.
2. **Reword**: everything else, whether a slip into the glossary's concept (use the
   term the message suggests) or an unrelated sense (an OS process being killed, a
   person "reading" the docs, an English "maps"). Pick a phrasing without the word.
3. **Allowlist**: only when neither works, such as a product name in plain prose. Add a
   `.glossary-allow` line, `<path> <term>  # reason`. It covers the term everywhere in
   that file and hides later slips too, which is why it comes last.

Done when the script exits 0, with any `.glossary-allow` line carrying a reason.

## 3. Wire it into the gates (when setting a repo up)

Each repo opts in. Hook the check into the command the repo's pre-push hook already
runs. For a Makefile, add a target and make the repo's lint target depend on it:

```make
GLOSSARY_LINT := <plugin root>/skills/glossary-lint/glossary-lint.sh
glossary:
	@if [ -f "$(GLOSSARY_LINT)" ]; then sh "$(GLOSSARY_LINT)"; \
	else echo "glossary-lint not installed; skipping"; fi
```

The plugin-root path is versioned, so it goes stale when the plugin upgrades; the `[ -f ]`
guard then skips the check silently until the path is updated.

The guard keeps the gate passing on machines without this skill. Commit the target with
the step 2 fixes, so the gate starts green.
