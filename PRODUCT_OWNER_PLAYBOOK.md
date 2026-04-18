# Product Owner Playbook

Your guide to building apps efficiently with Claude Code and the Flutter App Factory system. Read this when starting a new project and when you notice the process feels slow or frustrating.

---

## Your role

**You own:** what to build, why it matters, what good looks like, what the MVP includes, iteration feedback.

**Claude owns:** all technical decisions, all implementation, all testing, all debugging.

The boundary is clear: if it's about the user experience or the product value, that's yours. If it's about how to build it, that's Claude's.

---

## Starting a new project

Always in this order:

1. **Open Claude Code with `flutter_template` as the working directory**
2. **Run the brainstorming session** — describe your app idea. Claude will interview you. Don't skip this.
3. **Review and approve the spec** before implementation starts
4. **Review and approve the implementation plan** before building starts
5. **Let Claude bootstrap** — the new repo, Firebase setup, theme, modules
6. **Start iterating on features** using the feature development loop

Never jump to "just build X" without going through brainstorming first. The brainstorm is where scope gets bounded. Skipping it is where projects get slow.

---

## Briefing a feature

Tell Claude:
- **What** the feature does (in user terms — "a user can add a meal by taking a photo")
- **Why** it matters (what problem it solves)
- **What good looks like** (how you'll know it's done)

Do not tell Claude:
- How to implement it
- Which files to change
- Which packages to use

If you find yourself describing implementation steps, stop. You're crossing the boundary.

---

## Giving feedback

Describe what's wrong with the **outcome**, not how to fix it.

Good: "When I tap Add, nothing happens."
Good: "The list looks cluttered — the spacing feels too tight."
Good: "This doesn't match how I described the feature — I wanted X, not Y."

Not good: "Change the padding to 16."
Not good: "Use a different widget here."
Not good: "Put the button on the left instead."

Claude will figure out how to fix it. Your job is to describe the gap between what you see and what you want.

---

## Scoping an MVP

When deciding what's in the MVP, use this forcing question for each feature:

> "If this feature isn't in the first version, will users be unable to get core value from the app?"

If yes → it's in MVP.
If no → it's post-MVP.

Be ruthless. Every feature you add to MVP delays launch and increases build cost.

---

## What not to do

**Don't jump ahead.** If you think of a new feature mid-build, note it down. Don't ask Claude to add it until the current feature is complete and committed.

**Don't give technical instructions.** "Use X package", "change this to Y" — these are Claude's decisions. If you're unhappy with the outcome, describe the outcome problem.

**Don't re-explain what's in CLAUDE.md.** The project CLAUDE.md exists so you don't have to repeat yourself. If Claude is doing something wrong that contradicts CLAUDE.md, point that out — but don't re-explain things that should already be known.

**Don't approve work you haven't tested.** When Claude says a feature is done, test it on device before moving on. Problems compound when not caught early.

**Don't skip the spec.** If you skip brainstorming and go straight to building, you'll either build the wrong thing or find yourself mid-build making decisions that should have been made upfront.

---

## When to push back on Claude

Push back when:
- The implementation seems more complex than the problem warrants
- Claude is proposing a feature you didn't ask for
- Something Claude is doing contradicts the product intent (even if it's technically correct)
- The spec said one thing and the build is doing something else

Don't push back on:
- Technical implementation choices (package selection, architecture patterns, file structure)
- How Claude organises or names things internally
- Performance or code quality decisions

---

## Keeping the system healthy

After each project, spend 15 minutes with Claude reviewing what was learned. Ask: "What patterns from this build should we add to flutter_template?" Anything worth keeping gets back-ported and committed. This is how the system compounds.
