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
- **Unvalidated numeric input**: flag a numeric value read from external input, or computed from already-validated inputs, that is cached or used downstream without checking it is finite and in range — a malformed payload or an extreme-but-valid input can silently produce `NaN` or infinity. Validate the value itself, not just its inputs.
- **Inconsistent safeguards across sibling call sites**: flag a guard — a lockfile-strict flag, a null check, a fail-fast lookup — applied at some call sites for a resource but not others in the same file. Every call site touching the same resource should fail the same way.
- **Unreleased resource on the error path**: flag a teardown that calls several release steps with no guard on each — one step raising skips the rest and leaks whatever it would have released. The same applies to a stream left open when a write fails; abort it before the error propagates.
- **Trusted 200 with an unchecked error envelope**: flag code that indexes into a parsed response without first checking an API's own success/error field — an application-level failure arriving as HTTP 200 raises an unhandled error instead of going through the handling built for transport failures.
- **Borrowed exception type**: flag code that raises a dependency's own exception class to signal an application-level failure — it conflates a genuine transport fault with a business error under any handler written for the dependency's type. Raise the repo's own exception type instead.
- **Watermark advanced before completion**: flag a cursor or last-seen value advanced before the guarded operation is confirmed to have completed. An early return after committing it makes an unprocessed input look already handled, silently suppressing the retry that return was meant to allow.
- **Timestamp captured after a moved `await`**: flag a refactor that relocates a timestamp capture into code now running after an `await` that used to happen after it — a slow awaited call can shift which records pass a since-timestamp filter with no visible logic change in the diff.
- **Permissive unknown keys after a rename**: flag a config or schema model without strict unknown-key rejection when a field has been renamed or moved — a leftover key from before the rename is dropped silently instead of failing loudly. Match any sibling model that already rejects unknown keys.
- **Incomplete exception taxonomy in a parser**: when a loader promises to turn every malformed input into one domain error type, check it catches every exception its conversion helpers can raise — attribute, type, key, and value errors — not just the common one.
- **Non-deterministic collection order**: flag a function returning a list assembled from a dict, set, or JSON object with no explicit sort — output order must not depend on input key or insertion order.
- **Falsy-default coalescing**: flag `x or default` used to substitute a default for an optional argument — it silently discards a falsy-but-valid value such as an empty collection or `0`. Use `x if x is None else default` instead.
- **Unvalidated bounded constructor argument**: flag a class whose `__init__` stores a range-limited parameter without rejecting out-of-range values there — a caller that already validates does not stop the class being constructed directly elsewhere.

## Code Quality

- **Type annotations**: all functions and classes must be meaningfully annotated. Types should be honest and specific — not `dict`, `list`, or `Any`. API responses must use Pydantic models.
- **Readability over elegance**: flag nested list comprehensions where a `for` loop would be clearer. Do not enforce Pythonic style at the expense of clarity.
- **Imports at the top**: imports must appear at the top of the file (linters enforce this). **Exception**: heavy imports (`pandas`, `boto3`, `torch`) used only in a single execution branch should be moved inside the function to speed up module loading.
- **Circular imports**: check for circular imports, particularly in FastAPI and FastMCP, that are papered over with local imports inside functions.
- **Mutation and I/O hygiene**: functions must not mutate their arguments. `__init__` must not perform I/O. Default arguments must not be mutable.
- **Observability**: new code paths must have required logging and tests and meet existing observability non-functional requirements.
- **Claims that outrun the code**: flag a comment, docstring, or doc line promising a stronger guarantee than the code delivers — "exactly one", "in place", "atomic", "idempotent", "always", "never". Resolve by tightening the code or correcting the claim.
- **Ambiguous log line from a shared dispatch point**: flag a warning or error log emitted from a helper that now serves more than one operation when the message names neither the operation nor a discriminator — a reader cannot tell which path produced it.
- **Linear scan in a repeated-lookup path**: flag a `.index()` call or equivalent scan used as a sort key or evaluated on every comparison — precompute a dict mapping once instead of scanning per call.

## Security and Performance

- **Secrets exposure**: verify no secrets are inadvertently exposed. Do not rely solely on linting tools — check manually too. Local secrets must be in uncommitted, gitignored `.env` files.
- **Personal data in logs**: logging must not expose personal information. Remove statements that risk exposing user data.
- **Input sanitisation**: confirm inputs are appropriately sanitised, particularly anything from a request that flows into a query or LLM prompt.
- **Dependencies**: review new dependencies — confirm they are necessary, actively maintained, and pinned. New packages that pull in large transitive dependency trees may introduce supply-chain risk.
- **Performance bottlenecks**: flag infinite loops, database locks, large objects unnecessarily loaded into memory, and regexes compiled on every call.
- **Unsafe fallback**: flag code that, when its preferred resource is missing, silently does something materially riskier instead of failing — installing into system/global scope when a virtualenv is absent, using an unpinned version when the pinned one is unavailable, writing to a world-writable or predictable path when a private one cannot be created. Failing with a clear message is usually the safer default.
- **Predictable temp paths**: flag temp files or directories named from a fixed string, the PID (`$$`), or another guessable pattern instead of `mktemp` or the language's secure equivalent — they collide across concurrent runs and enable symlink attacks — and flag temp files left behind on the error path.
- **Prototype-pollution-prone key iteration**: flag a loop over `Object.keys()` of parsed or untrusted input that gates each write with a truthiness check — a key like `__proto__` passes through the prototype chain and pollutes it. Gate on `hasOwnProperty` or an explicit allowed-key set instead.
- **Expiry check with no safety margin**: flag a cached token or credential whose validity check uses the server-reported expiry exactly — clock skew or request latency can race it. Apply a margin against the nominal lifetime instead.
- **Non-root runtime without writable paths**: flag a container image that drops to a non-root user and then runs a tool reading or writing a cache, home, or state directory, without making that directory writable or disabling the access explicitly.

## Testing

- **Meaningful assertions**: tests should test behaviour, not the shape of the code. Assertions must provide information on failure. Flag tests that catch exceptions and assert nothing about them.
- **Mock only at system boundaries**: do not mock code that can be controlled — only mock external systems (databases, APIs, queues).
- **Coverage target**: there is an 80% code coverage requirement enforced at the pipeline level. Flag new code paths lacking test coverage.
- **Single test for a branch with several triggers**: flag a catch-all exception or shared branch documented to have more than one cause when only one is exercised by a test. Add one test per distinct triggering path, not one test for the branch as a whole.
- **Fixture that bypasses the mechanism under test**: flag a test fixture that supplies a value directly from a closure or literal when the fix under test changes how that value is looked up — such a fixture can pass identically against the unfixed code.
- **Indistinguishable conversion test values**: flag a test for a unit conversion whose input and expected values are far enough apart that skipping the conversion entirely would not change the pass/fail outcome. Pick a value where the converted and unconverted results diverge.

## Documentation

- **READMEs and runbooks**: check that READMEs, runbooks, wikis, and architecture docs are not outdated because of this PR. Authors must document their changes.
- **Environment variables and configuration**: new environment variables or configuration values must be documented.
- **Restated-fact sweep**: when the diff changes or removes something that is stated in more than one place, find the other copies and flag any left contradicting the new code. Two kinds: (a) a design-rationale or invariant comment — why something works a certain way, not what it does — paraphrased in a class comment, an inline comment, a test comment, or a spec; (b) a concrete value, order, or enumeration — a fallback sequence, a set of supported types, a default, a threshold — also written out in a README, a config comment, a spec, or another doc. Both are usually reworded rather than repeated verbatim, so match on meaning.
