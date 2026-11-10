# quiz-the-diff — Reference

Detail for the workflow in [SKILL.md](SKILL.md): diff resolution, the in-scope filter, the
teach phase, and how to write questions. The pedagogy draws on Matt Pocock's `teach` skill
and Geoffrey Litt's "explain diff" technique — see [Pedagogy notes](#pedagogy-notes).

## Diff resolution

| Situation | What to run |
|---|---|
| Argument is a PR number or URL (call it `<ref>`) | `gh pr diff <ref>`; `gh pr view <ref> --json number,title,body,files` |
| No argument, branch has an open PR | `gh pr view --json number,title,body,files`; `gh pr diff` (both default to the branch's PR) |
| No PR, or `gh` missing / unauthenticated | `git fetch` (proceed if it fails), then `git diff --merge-base <base-ref> HEAD` |

`<base-ref>` is the remote-tracking ref for the default branch. Read it from
`git symbolic-ref refs/remotes/origin/HEAD --short`, which returns it already
`origin/`-qualified (e.g. `origin/main`); use it verbatim — do not add another `origin/`.
Comparing against the remote-tracking ref rather than a local branch keeps a stale local
checkout from inflating the diff. If `git symbolic-ref` fails (origin/HEAD unset), try
`git remote show origin`, else use `origin/main`. Run `git fetch` first so the ref is
current; if it fails (offline), carry on and tell the reader the base may be behind.

In the local-diff fallback there is no title or description; teach from the diff and the
surrounding code alone.

## In-scope diff

The **in-scope diff** is what remains after removing documentation. Classify by the
*purpose* of the change, not the file's extension: a `.md` file can be documentation in one
repo and executable agent logic in another.

### Out of scope — documentation

- Files that exist to explain the project to a human reader: `README*`, `CHANGELOG*`,
  `CONTRIBUTING*`, `CODE_OF_CONDUCT*`, `SECURITY*`.
- Anything under a `docs/` or `.agent-docs/` directory at any depth (guides, specs, issues,
  ADRs, `context.md`, `agent.md`).
- `LICENSE` / `NOTICE` (any casing, with or without extension), `*.rst`, `*.txt`.
- `.md` / `.mdx` files that are narrative documentation — a design note, a how-to, a wiki
  page.
- In any file, a hunk where *every* added or removed line is a comment, a docstring line,
  blank, or a line of narrative prose. One changed line of code, config, data, or
  instruction keeps the hunk in scope.

### In scope — behaviour

- Application and library code in any language.
- Configuration, CI/CD workflow files (`.github/workflows/**`, etc.), build scripts,
  infrastructure-as-code.
- Test files, fixtures.
- Lockfiles, dependency manifests, schema and migration files.
- **Agent-instruction files** — `SKILL.md`, `REFERENCE.md`, `WORKFLOW.md`, `AGENTS.md`,
  `CLAUDE.md`, prompt templates — when the change alters steps, commands, control flow,
  decision rules, or tool usage. A pure rewording of the same instruction is documentation
  and stays out.

The test for an ambiguous `.md` file: is it *consumed as instructions* (a skill entrypoint,
a prompt) or *read as explanation* (a README, an ADR)? Instructions are in scope.

### Worked examples

| Change | In scope? |
|---|---|
| `README.md` rewritten | No — explains the project |
| A step reordered and a command changed in `some-skill/SKILL.md` | Yes — step logic |
| A sentence in `some-skill/SKILL.md` reworded, no step change | No — prose only |
| `.agent-docs/adr/0004-thing.md` added | No — under `.agent-docs/` |
| New function added, with a docstring | Yes — the function body is code |
| Only a docstring reworded in `service.py` | No — docstring-only hunk |
| A CI job's timeout raised in `ci.yml` | Yes — config |
| `poetry.lock` regenerated | Yes — lockfile |
| A typo fixed in a code comment, nothing else in the hunk | No — comment-only hunk |

## Mission question

Ask once, with `AskUserQuestion`, and make skipping cost nothing:

- **Reviewing it** — emphasise correctness, edge cases, and what could break in production.
- **Onboarding to the area** — emphasise how the changed code fits the wider system.
- **Inheriting ownership** — emphasise why decisions were made and what the alternatives were.
- **Just curious** — a balanced mix.

If the reader skips, teach and quiz with the balanced mix.

## Teach phase

Three sections, short enough to hold in working memory, every claim carrying a citation.

**Background** — the system context a reader needs before the diff makes sense: what the
touched code did before this PR, why the change was wanted, what problem or ticket drove it.
Pull this from the PR description and from reading the surrounding files, not just the diff.

**Intuition** — the core idea of the change in plain language, ideally with a tiny concrete
example ("before, a retry waited 1s every time; now it doubles: 1s, 2s, 4s"). One or two
sentences per distinct idea. No code yet.

**Code walkthrough** — group the in-scope hunks by concept, not by file order. For each
group: name the concept, point at the hunks (`path/to/file.py` around the `handle_retry`
change), say what the code now does and how it connects to callers and tests. Call out
anything subtle: a changed default, a widened type, an ordering dependency, an error path.

**Citations** — every factual claim references a file and a locator within it (a function or
class name, or a nearby unique string). Line numbers drift; names are stabler.

**Large in-scope diff** (rough guide: > ~40 files or > ~2000 changed lines) — rank files by
signal (core logic and behaviour changes first, then config and tests, then generated
files), walk through the top handful in full, and summarise the remainder one line per
file. Every non-doc hunk is still fair game for a question.

## Writing questions

Each question tests one idea from the in-scope diff or its immediate context.

### Format

- Exactly four options.
- Options are close to equal in length and word count. The correct answer must not be the
  longest, the most detailed, or the most hedged.
- Vary which position (1–4) holds the correct answer from question to question.
- No "all of the above", no "none of the above", no "both A and C".
- One unambiguously correct option; the other three are plausible to someone who half-read
  the diff — near-misses, not jokes.
- Ask about behaviour, consequences, and reasons ("what happens when the queue is empty
  after this change?"), not trivia ("how many lines were added to `queue.py`?").

### Difficulty

Aim at the reader's zone of proximal development: hard enough to require recalling what was
taught, not so hard it needs knowledge the teach phase never covered. Medium baseline.
Adjust to the mission answer, not to whether the last answer was right.

### On a wrong answer

1. Name the misconception briefly and without judgement.
2. Re-teach just the missed concept — two or three sentences, one citation.
3. Ask the next question about a **different** hunk or concept. Do not re-ask the same
   question reworded.

### Coverage

Spread the ten required correct answers across the in-scope diff, using the `TodoWrite`
item's examined list to see what is left. On a small diff, revisit a hunk only with a
genuinely different angle: its happy path, then its edge case, then why this approach over
an alternative. Interleaving across hunks is deliberate.

### Anti-gaming checklist

Before sending each question, confirm:

- [ ] The four options are within a few words of each other in length.
- [ ] The correct answer is not the longest, most specific, or most hedged option.
- [ ] The correct answer is not in the same position as the previous question's.
- [ ] No option is "all of the above", "none of the above", or "both X and Y".
- [ ] The three distractors are plausible to someone who skimmed the diff, not absurd.
- [ ] The question asks about behaviour or reasoning, not line counts or trivia.

## Recap

When `correct_count` reaches ten, close with:

- **Covered** — the concepts examined, one line each.
- **Re-taught** — the concepts the reader missed on the way, so they know where they were
  shaky.
- **Read next** — one or two high-trust primary sources (the library's own docs for an API
  the diff uses, a linked design doc, the ADR the PR implements). Skip this line if there is
  nothing genuinely worth citing.

## Pedagogy notes

Sources: Matt Pocock's `teach` skill (`mattpocock-skills`,
`skills/productivity/teach/SKILL.md`); Geoffrey Litt's "explain diff" gist
(<https://gist.github.com/geoffreylitt/a29df1b5f9865506e8952488eac3d524>).
