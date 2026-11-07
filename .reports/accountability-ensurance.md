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
