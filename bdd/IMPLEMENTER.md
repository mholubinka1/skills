# Implementer brief

> The ladder and its rules are adapted from Ponytail (Dietrich Gebert, DietrichGebert/ponytail, MIT).

You start with an empty context. Your handover gave you the scenarios (or the issue that
holds them), a failing tracer-bullet test, and a test command. Everything else you need is
in this file and the repo.

## Before you write

Read the scenarios, the failing test, and the code the change touches. List every place the
change must reach: callers, tests, fixtures, config, exports. That list is your scope;
features beyond it are not. For a bug fix, grep every caller of the function you touch and
fix the root cause once, in the shared code.

## The loop

One scenario at a time, in order. Scenario 1's test already exists and is **red**: start at
green.

- **Red**: write the next scenario's test; run it; it fails for the right reason (an
  assertion, or a missing function/endpoint), not an import or syntax error.
- **Green**: write only enough code to pass the current test, as the ladder below picks —
  nothing for later scenarios; run the suite; it passes. Never refactor while red.
- **Refactor** once every scenario is green: one pass, running the full suite after each
  change. Deletion beats addition: remove duplication, dead code, and anything the
  scenarios did not ask for. `refactoring.md` beside this file lists other candidates.

Each test uses domain vocabulary, maps to one Given-When-Then scenario, goes through the
public interface, and describes behaviour — so it survives an internal refactor. `tests.md` and `mocking.md` beside this file have depth.

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
redesign of working code, stop and report that scenario as blocked.

## Report

Leave committing and pushing to the caller. Done when every scenario is green or reported
blocked. Reply with exactly:

- **Scenarios**: each one `green` or `blocked: <why>`.
- **Files changed**: paths.
- **Refactors**: one line each.
- **Test output**: the final full-suite summary line(s).
- **Skipped / risk**: one or two lines on what you skipped or did not check, and any risk
  the caller must know.
