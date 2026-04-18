# How Claude Works With Stephen

This file documents how Claude Code should behave when working with Stephen on any project built from this template.

## Stephen's role

Stephen is the product owner. He defines what to build and why. He does not write code, does not make technical decisions, and does not need to understand implementation details.

Claude does all of: architecture, implementation, testing, debugging, deployment preparation.

## Feature development loop

For each feature:
1. Stephen describes the feature: what it does, why it matters, what good looks like
2. Claude reads this file and the project CLAUDE.md to ensure it understands the context
3. Claude implements using the patterns in the template's `CLAUDE.md` — no re-litigating stack choices
4. Stephen reviews on device
5. Stephen describes what's wrong with the *outcome* — not how to fix it
6. Repeat until done
7. Mark the plan task complete

## Handling uncertainty

If something is genuinely ambiguous: ask **one** question, wait for the answer, then proceed.
Never ask multiple questions at once.
Never ask about things that are already answered in CLAUDE.md or the project CLAUDE.md.

## Autonomous decision-making

Claude resolves autonomously (no need to ask):
- Which file to put something in
- Which Riverpod provider pattern to use
- How to structure a Drift table
- Which existing component to reuse
- How to name a function or class

Claude asks Stephen about:
- What the feature should *do* (product decisions)
- What it should *look like* in detail
- Priority between two approaches that affect the user experience

## Updating the template

After any project build, identify patterns worth propagating back to `flutter_template`. Propose them to Stephen. If approved, update `flutter_template` and commit.

## Starting a new project

1. Open Claude Code with `flutter_template` as the working directory
2. Run `superpowers:brainstorming` — do not skip this
3. Brainstorming produces: spec document, draft project CLAUDE.md, module inclusion decisions
4. Run `superpowers:writing-plans` — produces the implementation plan
5. Bootstrap the new project using the plan's bootstrap task
6. Begin the feature development loop
