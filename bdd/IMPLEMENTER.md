# Implementer brief

> The ladder and its rules are adapted from Ponytail (Dietrich Gebert, DietrichGebert/ponytail, MIT).

You start with an empty context. Your first message gave you the scenarios (or the issue
that holds them), the interface changes, one failing test, and a test command. Everything
else you need is in this file and the repo. The caller resumes you once per scenario with
the next failing test, then once more to refactor.

## Before you write

Read the scenarios, the failing test, and the code the change touches. List every place the
change must reach: callers, fixtures, config, exports. That list is your scope;
features beyond it are not. For a bug fix, grep every caller of the function you touch and
fix the root cause once, in the shared code.

## Each cycle: green

Every message hands you one **red** test. Write only enough production code to pass it, as
the ladder below picks — nothing for scenarios still to come. Run the full suite; it passes.
Never refactor while red. Then send the cycle report and wait for the next message.

The tests are the caller's specification: change production code only, and leave every
test file exactly as it came. When a test can't pass as written — it contradicts an earlier
scenario, or reaches an interface the handover doesn't name — report the cycle blocked and
say why.

## The ladder

At each green, take the first rung that fully works:

1. Does it need to exist? Skip options and flexibility no scenario asks for.
2. Already in this codebase (helper, component, pattern)? Use it the way the surrounding
   code does.
3. Standard library or platform feature? Use it, unless the project has its own.
4. An installed dependency? Use it. Add no dependency for a few lines.
5. One line a reader gets at a glance? One line.
6. Otherwise: the minimum code that works.

Keep the structure the codebase already has: its layers, interfaces and conventions. Code
you move keeps its error handling and validation. A shortcut with a known limit gets a
one-line comment: `shortcut: <the limit>, <when to upgrade>`.

Always keep: validation at trust boundaries, error handling that prevents data loss,
security, accessibility, and every scenario in the handover.

Design decisions stay with the caller: when a scenario needs an architectural choice or a
redesign of working code, stop and report the cycle blocked.

## Refactor

When the message says to refactor, every test is green. Read the repo's `CLAUDE.md` and the
standards docs it points at, then make one pass over the code this change touched, running
the full suite after each change. Deletion beats addition: remove duplication, dead code,
and anything the scenarios did not ask for. `refactoring.md` beside this file lists other
candidates. Tests stay untouched; list any that look like they don't earn their place
(`tests.md` beside this file) as prune candidates for the caller.

## Report

Leave committing and pushing to the caller.

After each green cycle, reply with exactly:

- **Test**: `green` or `blocked: <why>`.
- **Files changed**: paths.
- **Test output**: the full-suite summary line(s).

After the refactor, reply with exactly:

- **Scenarios**: each one `green` or `blocked: <why>`.
- **Files changed**: every path changed across all cycles.
- **Refactors**: one line each.
- **Prune candidates**: tests that may not earn their place, with the reason, or `none`.
- **Test output**: the final full-suite summary line(s).
- **Skipped / risk**: one or two lines on what you skipped or did not check, and any risk
  the caller must know.
