# Review Criteria

All content here is passed verbatim to the Standards sub-agent. Two rule bindings apply throughout:

- **The repo overrides.** A documented repo standard always wins; where it endorses something that the smell baseline would flag, suppress the smell.
- **Always a judgement call.** Smells are labelled heuristics, not hard violations. Documented-standard breaches may be blocking; smells are always advisory. Skip anything tooling already enforces.

## Smell Baseline (Fowler, _Refactoring_ ch. 3 — via Matt Pocock)

Each smell: _what it is_ → _how to fix_:

- **Mysterious Name** — a function, variable, or type whose name doesn't reveal what it does. → Rename; if no honest name comes, the design is murky.
- **Duplicated Code** — the same logic shape appears in more than one hunk or file. → Extract the shared shape, call it from both.
- **Feature Envy** — a method reaches into another object's data more than its own. → Move the method onto the data it envies.
- **Data Clumps** — the same few fields or params keep travelling together. → Bundle them into one type.
- **Primitive Obsession** — a primitive or string standing in for a domain concept. → Give the concept its own small type.
- **Repeated Switches** — the same `switch`/`if`-cascade on the same type recurs across the change. → Replace with polymorphism or a shared map.
- **Shotgun Surgery** — one logical change forces scattered edits across many files. → Gather what changes together into one module.
- **Divergent Change** — one file is edited for several unrelated reasons. → Split so each module changes for one reason.
- **Speculative Generality** — abstraction or hooks added for needs the spec doesn't have. → Delete it; inline back until a real need shows.
- **Message Chains** — long `a.b().c().d()` navigation the caller shouldn't depend on. → Hide the walk behind one method on the first object.
- **Middle Man** — a class or function that mostly just delegates onward. → Cut it, call the real target directly.
- **Refused Bequest** — a subclass or implementer that ignores most of what it inherits. → Drop the inheritance, use composition.

## Code Correctness

- **Acceptance Criteria**: step through each criterion and find the lines that satisfy it. If you cannot locate them, raise a blocking finding — code looking reasonable is insufficient.
- **Edge cases**: look for missed edge cases (empty inputs, unhandled nulls, integer overflow, timezone mismatches, concurrent calls to the same endpoint).
- **Error handling**: code must not swallow errors silently. Check for bare exceptions or missing propagation. Equally, check for uncaught exceptions that crash execution.
- **Unguarded external commands**: when code shells out to `git`, a package manager, a network call, or toolchain/`venv` setup, check it guards the foreseeable failures — missing remote or auth, no network, wrong working directory, absent tool, half-built environment — and surfaces a cause the caller can act on rather than letting the raw downstream error escape. Flag an error message that names one cause ("history has diverged") when the same failure has several.
- **Edits to files the change does not own**: when the diff parses and rewrites a file owned by the user or another system (a shell rc file, another team's config or schema, a file a different service generates), a structure it does not recognise must make it stop and leave the file untouched — never a best-effort edit. Flag any such parser that can truncate, reorder, or drop unrelated content when its assumptions do not hold.
- **Partial checks for compound state**: flag a readiness or "already done" check that inspects one artefact when the state it gates has several parts — one of N git hooks, one of N config keys, one of N migrations, one file of a set written together. It must enumerate every part the operation needs.
- **Async and concurrency safety**: verify logic is async-safe, uses approved libraries, and synchronous I/O is not blocking an event loop.
- **Backwards compatibility**: check for breaking changes to response/request shapes or database column renames/removals. If other services need companion PRs, flag this explicitly.

## Code Quality

- **Type annotations**: all functions and classes must be meaningfully annotated. Types should be honest and specific — not `dict`, `list`, or `Any`. API responses must use Pydantic models.
- **Readability over elegance**: flag nested list comprehensions where a `for` loop would be clearer. Do not enforce Pythonic style at the expense of clarity.
- **Imports at the top**: imports must appear at the top of the file (linters enforce this). **Exception**: heavy imports (`pandas`, `boto3`, `torch`) used only in a single execution branch should be moved inside the function to speed up module loading.
- **Circular imports**: check for circular imports, particularly in FastAPI and FastMCP, that are papered over with local imports inside functions.
- **Mutation and I/O hygiene**: functions must not mutate their arguments. `__init__` must not perform I/O. Default arguments must not be mutable.
- **Observability**: new code paths must have required logging and tests and meet existing observability non-functional requirements.
- **Claims that outrun the code**: flag a comment, docstring, or doc line promising a stronger guarantee than the code delivers — "exactly one", "in place", "atomic", "idempotent", "always", "never". Resolve by tightening the code or correcting the claim.

## Security and Performance

- **Secrets exposure**: verify no secrets are inadvertently exposed. Do not rely solely on linting tools — check manually too. Local secrets must be in uncommitted, gitignored `.env` files.
- **Personal data in logs**: logging must not expose personal information. Remove statements that risk exposing user data.
- **Input sanitisation**: confirm inputs are appropriately sanitised, particularly anything from a request that flows into a query or LLM prompt.
- **Dependencies**: review new dependencies — confirm they are necessary, actively maintained, and pinned. New packages that pull in large transitive dependency trees may introduce supply-chain risk.
- **Performance bottlenecks**: flag infinite loops, database locks, large objects unnecessarily loaded into memory, and regexes compiled on every call.
- **Unsafe fallback**: flag code that, when its preferred resource is missing, silently does something materially riskier instead of failing — installing into system/global scope when a virtualenv is absent, using an unpinned version when the pinned one is unavailable, writing to a world-writable or predictable path when a private one cannot be created. Failing with a clear message is usually the safer default.
- **Predictable temp paths**: flag temp files or directories named from a fixed string, the PID (`$$`), or another guessable pattern instead of `mktemp` or the language's secure equivalent — they collide across concurrent runs and enable symlink attacks — and flag temp files left behind on the error path.

## Testing

- **Meaningful assertions**: tests should test behaviour, not the shape of the code. Assertions must provide information on failure. Flag tests that catch exceptions and assert nothing about them.
- **Mock only at system boundaries**: do not mock code that can be controlled — only mock external systems (databases, APIs, queues).
- **Coverage target**: there is an 80% code coverage requirement enforced at the pipeline level. Flag new code paths lacking test coverage.

## Documentation

- **READMEs and runbooks**: check that READMEs, runbooks, wikis, and architecture docs are not outdated because of this PR. Authors must document their changes.
- **Environment variables and configuration**: new environment variables or configuration values must be documented.
- **Restated-fact sweep**: when the diff changes or removes something that is stated in more than one place, find the other copies and flag any left contradicting the new code. Two kinds: (a) a design-rationale or invariant comment — why something works a certain way, not what it does — paraphrased in a class comment, an inline comment, a test comment, or a spec; (b) a concrete value, order, or enumeration — a fallback sequence, a set of supported types, a default, a threshold — also written out in a README, a config comment, a spec, or another doc. Both are usually reworded rather than repeated verbatim, so match on meaning.
