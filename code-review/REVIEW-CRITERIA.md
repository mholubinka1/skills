# Review Criteria

All content here is passed verbatim to the Standards sub-agent. Two rule bindings apply throughout:

- **The repo overrides.** A documented repo standard always wins; where it endorses something that the smell baseline would flag, suppress the smell.
- **Always a judgement call.** Smells are labelled heuristics, not hard violations. Documented-standard breaches may be blocking; smells are always advisory. Skip anything tooling already enforces.

New criteria are not added here directly. `address-copilot-comments` stages them in the
[Criteria gist](CRITERIA-GIST.md) — a live, cross-repo, cross-machine store — tagged
`(repo#PR)`. Periodically, collate: read the gist, rewrite each durable entry to the
[Criteria style](CRITERIA-STYLE.md) rules, add it to whichever section below fits it (Code
Correctness, Code Quality, Security and Performance, Testing, or Documentation) via a normal PR
to this repo, then delete that same line from the gist so it only ever holds entries not yet
collated. Prune stale entries here by hand.

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
- **Inconsistent safeguards across sibling call sites**: flag a guard — a lockfile-strict flag, a null check, a fail-fast lookup, a retry on "already exists" — applied at some call sites for a resource but not others, in the same file or in another service sharing it. Every call site touching the same resource should fail the same way.
- **Unreleased resource on the error path**: flag a teardown that calls several release steps with no guard on each — one step raising skips the rest and leaks whatever it would have released. The same applies to a stream left open when a write fails; abort it before the error propagates.
- **Trusted 200 with an unchecked error envelope**: flag code that indexes into a parsed response without first checking an API's own success/error field — an application-level failure arriving as HTTP 200 raises an unhandled error instead of going through the handling built for transport failures.
- **Borrowed exception type**: flag code that raises a dependency's own exception class to signal an application-level failure — it conflates a genuine transport fault with a business error under any handler written for the dependency's type. Raise the repo's own exception type instead.
- **State marker advanced before completion**: flag a cursor, last-seen value, or done-once flag advanced before the guarded operation is confirmed to have completed. An early return after committing it makes an unprocessed input look already handled, silently suppressing the retry that return was meant to allow. Advance it only after the operation succeeds.
- **Timestamp captured after a moved `await`**: flag a refactor that relocates a timestamp capture into code now running after an `await` that used to happen after it — a slow awaited call can shift which records pass a since-timestamp filter with no visible logic change in the diff.
- **Permissive unknown keys after a rename**: flag a config or schema model without strict unknown-key rejection when a field has been renamed or moved — a leftover key from before the rename is dropped silently instead of failing loudly. Match any sibling model that already rejects unknown keys.
- **Incomplete exception taxonomy in a parser**: when a loader promises to turn every malformed input into one domain error type, check it catches every exception its conversion helpers can raise — attribute, type, key, and value errors — not just the common one.
- **Non-deterministic collection order**: flag a function returning a list assembled from a dict, set, or JSON object with no explicit sort — output order must not depend on input key or insertion order.
- **Falsy-default coalescing**: flag `x or default` used to substitute a default for an optional argument — it silently discards a falsy-but-valid value such as an empty collection or `0`. Use `x if x is None else default` instead.
- **Unvalidated bounded constructor argument**: flag a class whose `__init__` stores a range-limited parameter without rejecting out-of-range values there — a caller that already validates does not stop the class being constructed directly elsewhere.
- **Parser handles only the common input shape**: flag a parser or matcher that accepts only the usual form of a field the spec allows in several — a bare value but not its object form, a plain reference but not a path-qualified one. Input in the other form is silently misread. Handle every form the spec allows.
- **Field presence checked without its type**: flag a parser for external or file input that checks a field exists but not its type — a list or number where a string belongs builds a bad object instead of reaching the parser's own fallback for malformed input. Validate the type as well as the presence.
- **Access check ignores inherited grants**: flag an access or reachability check that inspects only a unit's own configuration — an inherited scope, a resource-attached grant, or a caller that passes its context down can grant the same access while the local settings look safe. Enumerate every mechanism that can grant it, not just the direct one.
- **Coverage judged by a literal token**: flag a coverage or exclusion check that demands a specific literal, such as a named prefix, when a broader pattern already excludes the same cases — a wildcard, or a filter on another dimension. The check reports a gap that is not there. Evaluate what the rule actually excludes, not whether a string appears.
- **Partial payload to a full-replace endpoint**: flag a write to a full-replace endpoint whose payload carries only the fields being changed — every omitted field resets to its default, silently undoing unrelated settings. Fetch the current state, merge the change into it, then write the whole object.
- **Shared status code read as one cause**: flag code that reports a confident result from a status code the API also returns for a different cause — a 404 that means either "absent" or "no permission" cannot prove absence. Report the ambiguity instead of picking one reading.
- **Tool schema checked at one bound only**: flag a tool or UI invocation designed around a typical item count without checking the tool's documented minimum and maximum — a design that fits the middle range can break the schema with too few or too many items. Check both bounds before settling the design.
- **Changed option not re-verified in combination**: flag a fix to one flag or step of a multi-part command that re-checks only the changed part — options that each work alone can interact, often silently, such as a filter now applied per page instead of once to the combined result. Re-verify the whole command against its documented behaviour.
- **`NOT NULL` column added without a default**: flag an additive migration that adds a `NOT NULL` column with no server default — the database rejects the `ADD COLUMN` on any table that already has rows, so the migration fails at its first real deploy. Add it nullable, backfill, then tighten the constraint as a separate step.
- **Strict filter on an unbackfilled column**: flag a live consumer, such as a dashboard or report query, that filters strictly on a new nullable column whose existing rows are still `NULL` — deployed ahead of the producer or the backfill, it returns nothing instead of the last good result. Document the required deploy order where the query is defined.
- **New image with no publish step**: flag a new Dockerfile or Compose service added without a CI step that builds and publishes its image — a fresh deployment pulls a missing or stale image instead of the code just added. Add the build and publish step in the same change.
- **Dependency name differs from its import path**: flag a package declared and installed under one name but imported through a different path — the import resolves only through a development layout trick, such as a `PYTHONPATH` entry or namespace marker, and breaks once the package is installed as a built artefact. Make the declared name and the import agree.
- **Convention file placed by the wrong rule**: flag setup instructions that put a file a tool discovers by convention, such as Compose's `.env`, beside the `-f` target when the tool resolves it from the working directory — required variables are left unset with no clear error. Check the tool's documented lookup rule and place the file by it.
- **Reword inside a section fenced as unchanged**: when the spec or issue marks an existing section as kept verbatim or additive-only, flag any rewording of its existing sentences — even an accuracy fix breaks the fence reviewers rely on to skip that text. Put the correction in the added material instead.
- **Skip-and-continue applied to a foundational step**: flag a blanket "on failure, skip and continue" rule that also covers a step every later step depends on — skipping it lets the rest run on missing data and produce results that look complete. Make that step's failure stop the procedure.
- **Failure path on the last step only**: flag a multi-step procedure of external commands, such as lookup, fetch, then write, where only the final step has a documented failure path — an earlier failure can carry incomplete data into a destructive action. Give every step its own stop that leaves state unchanged.
- **Deletion out of step with git tracking**: flag a step that deletes a file without reconciling the git index — an unstaged deletion of a tracked file can be silently restored by a checkout, while `git add` on a never-tracked path errors. Check whether the path is tracked, and stage the deletion only if it is.
- **Partial validation before a destructive rewrite**: flag a parser that checks only part of an input's expected shape — one section of a document, a bullet's label but not its required trailing tag — before deleting or overwriting the original. Content outside what was checked can be silently lost. Validate the whole structure, or leave the source untouched.
- **Multi-part credential stored in part**: flag a wrapped authentication flow that needs several secret fields together but persists only some of them, filling the rest with a placeholder — the flow then authenticates with the placeholder and fails, or silently misbehaves. Persist every field the flow requires.
- **Wrapped client's internal session never closed**: flag a wrapped HTTP or async client constructed without an explicitly owned session when the library creates one internally and exposes no way to close it — the connection leaks for the life of the process. Pass in a session you own, and close it on shutdown.
- **Repeat alert on every retry**: flag a notification sent from the failure path of a retried operation with no per-incident de-duplication — the same unresolved failure alerts on every retry and every later scheduled run. Suppress it after the first alert, and reset only once the operation succeeds.
- **Recursive traversal with no cycle guard**: flag a recursive or graph traversal — following references, callers, or includes — with no visited set or depth limit. A cycle traps it in unbounded repetition, even when the target system would reject that cycle at a later stage. Track visited nodes or cap the depth.

## Code Quality

- **Type annotations**: all functions and classes must be meaningfully annotated. Types should be honest and specific — not `dict`, `list`, or `Any`. API responses must use Pydantic models.
- **Readability over elegance**: flag nested list comprehensions where a `for` loop would be clearer. Do not enforce Pythonic style at the expense of clarity.
- **Imports at the top**: imports must appear at the top of the file (linters enforce this). **Exception**: heavy imports (`pandas`, `boto3`, `torch`) used only in a single execution branch should be moved inside the function to speed up module loading.
- **Circular imports**: check for circular imports, particularly in FastAPI and FastMCP, that are papered over with local imports inside functions.
- **Mutation and I/O hygiene**: functions must not mutate their arguments. `__init__` must not perform I/O. Default arguments must not be mutable.
- **Observability**: new code paths must have required logging and tests and meet existing observability non-functional requirements.
- **Claims that outrun the code**: flag a comment, docstring, doc line, or acceptance criterion promising more than the code delivers — "atomic", "never", "secret", "validates on its own" — including deferred work described as shipped. Resolve by tightening the code or correcting the claim.
- **Ambiguous log line from a shared dispatch point**: flag a warning or error log emitted from a helper that now serves more than one operation when the message names neither the operation nor a discriminator — a reader cannot tell which path produced it.
- **Linear scan in a repeated-lookup path**: flag a `.index()` call or equivalent scan used as a sort key or evaluated on every comparison — precompute a dict mapping once instead of scanning per call.

## Security and Performance

- **Secrets exposure**: verify no secrets are inadvertently exposed. Do not rely solely on linting tools — check manually too. Local secrets must be in uncommitted, gitignored `.env` files.
- **Personal data in logs**: logging must not expose personal information. Remove statements that risk exposing user data.
- **Input sanitisation**: confirm inputs are appropriately sanitised, particularly anything from a request that flows into a query or LLM prompt.
- **Dependencies**: review new dependencies — confirm they are necessary, actively maintained, and pinned. New packages that pull in large transitive dependency trees may introduce supply-chain risk.
- **Performance bottlenecks**: flag infinite loops, database locks, large objects unnecessarily loaded into memory, and regexes compiled on every call.
- **Unsafe fallback**: flag code that, when its preferred resource is missing, silently does something materially riskier instead of failing — installing into system/global scope when a virtualenv is absent, using an unpinned version when the pinned one is unavailable, writing to a world-writable or predictable path when a private one cannot be created. Failing with a clear message is usually the safer default.
- **Predictable temp paths**: flag temp files or directories named from a fixed string, the PID (`$$`), or another guessable pattern instead of `mktemp` or the language's secure equivalent — they collide across concurrent runs and enable symlink attacks — and flag temp files left behind on either the success or the error path.
- **Prototype-pollution-prone key iteration**: flag a loop over `Object.keys()` of parsed or untrusted input that gates each write with a truthiness check — a key like `__proto__` passes through the prototype chain and pollutes it. Gate on `hasOwnProperty` or an explicit allowed-key set instead.
- **Expiry check with no safety margin**: flag a cached token or credential whose validity check uses the server-reported expiry exactly — clock skew or request latency can race it. Apply a margin against the nominal lifetime instead.
- **Non-root runtime without writable paths**: flag a container image that drops to a non-root user and then runs a tool reading or writing a cache, home, state, or host bind-mounted directory, without making that directory writable or disabling the access explicitly.

## Testing

- **Meaningful assertions**: tests should test behaviour, not the shape of the code. Assertions must provide information on failure. Flag tests that catch exceptions and assert nothing about them.
- **Mock only at system boundaries**: do not mock code that can be controlled — only mock external systems (databases, APIs, queues).
- **Coverage target**: there is an 80% code coverage requirement enforced at the pipeline level. Flag new code paths lacking test coverage.
- **Single test for a branch with several triggers**: flag a catch-all exception or shared branch documented to have more than one cause when only one is exercised by a test. Add one test per distinct triggering path, not one test for the branch as a whole.
- **Fixture that bypasses the mechanism under test**: flag a test fixture that supplies a value directly from a closure or literal when the fix under test changes how that value is looked up or refreshed — such a fixture can pass identically against the unfixed code.
- **Indistinguishable conversion test values**: flag a test for a unit conversion whose input and expected values are far enough apart that skipping the conversion entirely would not change the pass/fail outcome. Pick a value where the converted and unconverted results diverge.
- **Verification step that cannot verify**: flag a test-plan or acceptance step whose stated method gives wrong answers on the real input — a `.`-split sentence count over text containing `.md`, a `grep` that also matches comments. The step passes or fails regardless of the change. State a method that survives the actual data.
- **Migration test run on an empty table**: flag a migration test that builds the old schema fresh and only asserts the new column exists — it cannot catch a failure that occurs only on a table with rows, such as a `NOT NULL` column with no default. Seed a row first, then assert nullability and that the row survives.
- **Config-to-object wiring untested**: flag glue code that turns a config field into a constructor argument when tests cover the config model and the constructed object only separately — a regression in the glue, such as a hardcoded argument or swapped field, passes every test while disabling the feature. Test the wiring function directly, or its effect end to end.

## Documentation

- **READMEs and runbooks**: check that READMEs, runbooks, wikis, and architecture docs are not outdated because of this PR. Authors must document their changes.
- **Environment variables and configuration**: new environment variables or configuration values must be documented.
- **Restated-fact sweep**: when the diff changes or removes something that is stated in more than one place, find the other copies and flag any left contradicting the new code. Two kinds: (a) a design-rationale or invariant comment — why something works a certain way, not what it does — paraphrased in a class comment, an inline comment, a test comment, or a spec; (b) a concrete value, order, or enumeration — a fallback sequence, a set of supported types, a default, a threshold — also written out in a README, a config comment, a spec, or another doc. Both are usually reworded rather than repeated verbatim, so match on meaning.
- **Placeholder in a command run verbatim**: flag a command in a step-logic file an agent executes, such as a `SKILL.md`, that contains an example value or placeholder the step never works out — the agent runs it exactly as written, placeholder included. Prefer a command form that needs no substitution.
- **Directive with an ambiguous cadence**: flag an instruction to act "after every X" or "once Y" that does not say whether it runs on each iteration or a single time at the end — an agent following it can pick either and still believe it complied. State the cadence explicitly.
- **Cross-reference without its section anchor**: flag a cross-reference that names only a file when it could name the section or heading the reader needs — the reader has to search the whole file and may land on the wrong passage. Link the specific anchor, above all when the spec asks for it.
- **Document breaks its own rules**: flag a file that defines a rule set or checklist and breaks it elsewhere in the same file — a section longer than its own length limit, a description in the voice it forbids. Readers copy the example over the rule. Bring the file into line with what it prescribes.
- **Parallel item missing a sibling's element**: flag one item in a parallel series — steps, sections, list entries — that lacks a structural element all its siblings carry, such as a completion criterion or a "Done when" line. Readers assume the omission is deliberate. Add the missing element or say why it is absent.
- **Glossary definition carrying workflow detail**: flag a glossary entry that mixes operational steps into what should be a one-or-two-sentence "what it is" definition — the term becomes harder to scan and the workflow ends up documented in two places. Move the mechanics to where that workflow is documented.
- **Restatement that drops a qualifier**: flag a second statement of an existing rule, constraint, or enumeration — a summary, a shortened rewrite, a checklist item — that loses a caveat, a scope word, or a distinct case the original carries. The two now read as contradicting each other. Keep every qualifier unless it is provably redundant.
- **Unverified description of another document**: flag a claim about what a referenced document contains or omits — "X only covers the upgrade flow", "Y has none of these" — made without checking that document. A wrong description sends readers elsewhere for something that was there. Open the document and confirm the claim before stating it.
