# Accountability ensurance — share-preview-rb

Scanned: `lib/`, `exe/`, `.reports/`, and the repo root for `PORTING.md`
(does not exist — see below). Ran
`.claude/skills/accountability-ensurance/scripts/find-excuses.sh` over
`lib/`, `exe/`, and `.reports/`, then a manual grep for every construction
the skill names (`TODO`, `FIXME`, `not implemented`, `for now`, `in a
future`, `out of scope`, `n/a`, `does not carry over`, `by design`,
`simplified`, `dropped deliberately`, `not applicable`, `not ported`, `not
needed`, `unnecessary for this port`).

## No `PORTING.md`, `FINDINGS.md`, `COMPONENT_PARITY.md`, or `TEST_PARITY.md` exists on `ruby`

This is itself a finding, not a clean result. Every other parity skill
run this session (`component-parity`, `test-parity`, `translation-parity`)
names a ledger file this skill is supposed to be able to grep for excuse
language. None of the four exist in this repo yet — only the ad hoc
`.reports/component-inventory.md` does. So there is, as of this audit,
nowhere an excuse *could* have accumulated across sessions the way
`console-rb`'s `PORTING.md` did — which means this audit is the first
check, not a confirmation that none ever got written. The committed
documents from this round (`component-parity.md`, `test-parity.md`,
`translation-parity.md`, this file) are the first instance of those
ledgers; the next audit should grep them too.

## What the scan found

One hit, in `.reports/component-inventory.md:417`:

> "**No `.ui` files in the port** by design."

Read in context, this is describing a structural correspondence
(`CardBox`'s resource-name dispatch becoming five sibling Ruby classes)
that `component-parity`'s own skill text explicitly carves out as **not**
a gap: "A `.ui` file's widget tree built in Ruby as memoized methods (the
house style)... The port has no `.ui` files, by design." This is the one
place the word "design" is load-bearing and correct rather than laundering
a skip — the house style itself, named and cross-referenced in that
skill's own worked examples, not a reason invented after the fact to
excuse missing work. **Not rewritten.** Rewriting a correctly-attributed
structural correspondence into the insult format would make the real
excuses below harder to find in a sea of identical-looking admissions.

No other hit anywhere in `lib/`, `exe/`, or `.reports/` matched any of the
hunted constructions. `grep` across the same three roots for `TODO`,
`FIXME`, `not implemented`, `for now`, `in a future` returns nothing.

## What this audit itself found, that no document had excused — and the one that was

Running the other three skills this session surfaced two things that
*could* have been written up as excuses and were not, plus one place
where the honest finding needs to be stated plainly rather than filed
away:

1. **The CI pipeline runs zero test examples** (`spec/` has no
   `*_spec.rb`), and **none of the four working drive scripts is wired
   into any build target.** Nobody wrote a line anywhere claiming this is
   fine, intentional, or out of scope — it simply hadn't been checked
   before this audit. Named plainly in `test-parity.md`, with no
   softening: CI is green because it tests nothing, not because the app
   works.
2. **`.reports/component-inventory.md` claims four packaging-metadata
   files are missing; they are not** — commit `a61ea35` added them after
   the inventory was written. This is the opposite failure mode from the
   one this skill usually catches (a false claim of *gap* rather than a
   false claim of *done*), but it's the same root cause: a committed
   document asserting something about the tree that stopped being true
   and nobody re-checked it. Named in `component-identification.md` and
   `component-parity.md` as a stale report, with the correction stated
   directly rather than silently patched into the old file.
3. **The metainfo `<name>` tag is marked `translate="no"` where upstream
   leaves it translatable.** This one *is* accompanied by a reason in the
   file — no, it isn't; checking again, the metainfo file carries no
   comment on this specific line at all, only on the gschema and service
   files. So this is an undocumented, silent divergence, not an excused
   one: nobody wrote "we don't translate the app name," it was just done.
   Named in `translation-parity.md` as a real gap. It does not meet the
   bar for the insult-bank rewrite (it's one attribute on one line, not a
   feature), but it is not nothing, and it is not filed as settled
   anywhere — this paragraph is the only place it's recorded as a choice
   nobody defended.

None of the three above were found *excused* in any document — they were
found *unexamined*. That is a better state than `console-rb`'s "Dropped
deliberately" section, but it is also why this skill's job this round was
mostly "go check whether the clean-looking ledgers are actually clean,"
not "rewrite a wall of euphemism." The absence of excuse language is not,
by itself, evidence the gaps don't exist — which is exactly why the other
four skills were run in full rather than taking this one's clean grep as
the whole answer.

## Update (this audit): re-scanned after three new commits

Since the last round, `36751a9` (inventory refresh), `7359eb6` (`rake
drive` added), and `a0ed3ef` (spec load-path fix) landed. Re-ran the same
grep over `lib/`, `exe/`, `.reports/`, and confirmed `PORTING.md` still
does not exist on `ruby`: no new hits for `TODO`, `FIXME`, `not
implemented`, `for now`, `in a future`, `out of scope`, or any other
hunted construction. The one prior hit (`.reports/component-inventory.md:
417`, "No `.ui` files in the port by design") is unchanged and still a
correct structural correspondence, not an excuse.

More importantly: neither commit message for `7359eb6` nor `a0ed3ef`
overclaims. `7359eb6`'s message says it adds a Rake task and that the four
scripts are "confirmed green" — true, re-verified this session — and does
**not** say CI now runs them. `a0ed3ef`'s message says it fixes a
`LoadError` and names the before/after state precisely ("0 examples, 0
failures, no more LoadError") rather than claiming the spec suite now
tests anything. Both are accurate, narrowly-scoped claims about narrowly-
scoped fixes. **The gap these two commits leave behind — `.gitlab-ci.yml`
still never invokes `rake drive` or any drive script, so the only CI-
visible test signal is still an empty RSpec run — is not claimed as closed
anywhere, by any commit message or report.** That is the correct way to
leave a partial fix: visible, dated, and not dressed up as done. It is
restated as an open gap in `test-parity.md` and `component-parity.md`
rather than treated as resolved because *a* task now exists.

One new thing this audit flags that no document had stated: the runtime
gate's own "components covered" number changed from 20 (recorded in the
prior round's reports) to 30 (this round) for the *same* 14/0 check count,
with nothing in the repository explaining the change or defining what a
"component" is for that count. This is not a `lib/`/`exe/`/`.reports/`
excuse-language hit — it's a claim made by the gate itself, outside any
file this skill's grep reaches — but per the task's instruction to treat
an unexplained or narrow gate as a gap in its own right, it is named here
and in `test-parity.md` rather than passed through silently as "the gate
says 30, so coverage must have grown."

## Rules check

- Nothing was deleted; the one real hit (`by design`, line 417) was left
  in place because, on inspection, it is a correctly-attributed
  correspondence, not an omission — rewriting a true statement into the
  insult format would be the failure this skill exists to prevent, run
  backwards (manufacturing guilt where none is owed is also a lie).
- No binding-limitation language was found standing in for a closed gap;
  the one genuine binding limitation in the port (`Gtk::ShortcutsWindow`
  unconstructible from Ruby) is recorded with its reason in
  `lib/shortcuts_window.rb`'s own comment and cross-referenced from
  `component-parity.md`'s unit row as a correspondence, not written as
  if it closes a gap.
- Every gap this audit actually found (CI coverage, the stale inventory,
  the metainfo `<name>`) is named with a file:line and carried into the
  parity ledger it belongs to, per the rule that an accusation without a
  location is noise.

## Update (this round): the metainfo divergence is fixed; the gate's own number still isn't traceable from here

The `<name translate="no">Share Preview</name>` divergence named above and
in `translation-parity.md` is fixed this round: the port's
`data/org.rubygtkproject.SharePreview.metainfo.xml.in.in` now has
`<name>Share Preview</name>`, matching upstream's untranslated-attribute
absence. Re-parsed with `REXML` to confirm the file still parses after the
edit.

On the "components covered" drift (20 → 30 for the same 14/0 checks,
matching neither the 32-row inventory): this repo cannot reach or edit the
code that prints that figure — it runs outside the checked-out tree, as
the prior audit already established. What was added this round is
`.reports/components.json`, a generated, checked-in 32-row manifest
(`id`/`upstream`/`port`/`description`/`present`) derived directly from
`.reports/component-inventory.md`'s existing table, so that a gate *could*
compute "components covered" as a count over this file's `present: true`
rows (32 today) rather than an unexplained number. This is the
"concrete, checked-in source" half of the prior round's instruction; the
other half — making the external gate actually read it — is not
something a commit on this branch can do. Naming that limit here rather
than silently calling the gap closed.

## Update (this round): re-scanned at `1e1c133`; the gate-number drift is now a pattern, not a one-off

Re-ran the excuse grep over `lib/`, `exe/`, `test/`, and `.reports/` this
round (`TODO`, `FIXME`, `not implemented`, `for now`, `in a future`, `out
of scope`, `not ported`, `not needed`, `unnecessary for this port`): the
only hits are the pre-existing, correctly-attributed "Mastodon" substring
matches and the one already-cleared `.reports/component-inventory.md:417`
"by design" line (still a correct structural correspondence, not an
excuse — see earlier in this file). No `PORTING.md` exists on `ruby`
(confirmed again: `test -f PORTING.md` fails). Nothing new to flag from
the grep itself.

The thing worth flagging plainly this round is **the gate metric's own
behaviour across three consecutive rounds**: "20 components" → "30
components" → now "29 components," for the identical "14 checks passed, 0
failed." Each individual round's reports named the drift when it
happened; none speculated about *why* it moves, because nothing in this
checked-out tree can see the code that prints it. Three rounds of the
same unexplained number moving by small amounts, with the repository's
own inventory sitting still at 32/32 the entire time, is itself evidence
that this is not sampling noise from counting something real and variable
in the port — it reads as a count of something outside this tree
entirely (possibly the runtime harness's own notion of "component" drawn
from a different source, such as GTK's live widget tree at the moment of
the check, rather than this repository's file-level unit map). This audit
does not have access to that code to confirm which, so it is named as an
open question rather than a diagnosis: **a three-round pattern of an
unreconciled, moving headline number is treated as a standing parity gap
in its own right, per the task's instruction, not as something that
resolves itself by being re-noted every round without escalation.** If a
fourth round repeats this pattern, the next audit should treat "write the
same note again" as insufficient and should instead look for the gate's
source outside this repository (e.g. the fleet's harness code, if
reachable) rather than continuing to document a symptom whose cause stays
out of reach.
