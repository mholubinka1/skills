# Criteria Style

The linguistic rules every criterion in [REVIEW-CRITERIA.md](REVIEW-CRITERIA.md) follows. Apply
them when collating entries from the [Criteria gist](CRITERIA-GIST.md), and when rewording an
existing criterion. The original baseline criteria ("Edge cases", "Observability") predate these
rules and are left as they are until they are next edited.

## Shape

- **One line, one defect.** `- **Label**: body.` Each criterion names one failure mode. If the
  body needs "also" or a second, unrelated "flag", split it into two criteria.
- **30–60 words**, label included. Anything over 75 needs a reason.

## Label

- **Name the defect, not the topic or the fix.** A noun phrase describing the bad state —
  "State marker advanced before completion", not "Cursor handling" or "Commit cursor after
  success".
- **Sentence case, 3–8 words.** Capitalise only the first word, proper nouns, and code. A
  backticked token is fine when it is the defect (`` `NOT NULL` column added without a
  default ``).
- **Specific enough to grep for.** The label must make sense alone in a findings list —
  "Trusted 200 with an unchecked error envelope", not "API errors".

## Body

- **Open with the reviewer's verb, lowercase after the colon.** "flag" by default; "when …,
  check …" only when the criterion applies in a narrow situation. Never open with
  "must", "never", or a subject such as "Code".
- **Trigger, consequence, fix — in that order.**
  - **Trigger:** what to flag, described in general terms.
  - **Consequence:** an em-dash clause saying what goes wrong and how it shows.
  - **Fix:** one short imperative sentence, often ending "instead".
- **Examples are illustrative, never exhaustive.** Two to four concrete cases, in brackets or
  after an em-dash. Stop at four.
- **Generic, not traceable to a source.** No repo names, `(repo#PR)` tags, product names, or
  the specific case that prompted the criterion — strip the gist's tag on collation. Turn "the
  billing service's meter list" into "a mutable dependency (a meter list, a config reload)".
- **Advisory by default.** "Flag" matches the binding in `REVIEW-CRITERIA.md` that smells are
  judgement calls. Keep "must" for a documented standard or an invariant the fix has to meet.

## Diction

- **British spelling** — artefact, behaviour, recognise, sanitise, judgement.
- **Punctuation.** Spaced em-dashes (` — `) for the consequence clause; backticks for code,
  commands, file names, and literal values; double quotes for quoted phrases.
- **Plain words over coinages.** No invented compounds.
- **Present tense, reviewer as the implied "you".** No "we", "I", or "the agent". Name the
  reader's action, not the author's.
