# Translation parity — share-preview-rb

| | |
|---|---|
| Upstream | `origin/master` @ `2d36059` |
| Port | `ruby` @ `27ab64a` |
| Domain | `share-preview` (confirmed: `po/*.pot` on both sides) |
| Upstream messages | 41 |
| Ported | 41 (37 by the automated scanner + 4 corrected by hand, see below) |
| Gaps | 0 real (1 genuine divergence, recorded below, not counted as a message gap because the key *is* produced — see the dedicated section) |
| Extra (untranslated) | 1 |
| Upstream occurrences | 49 across 41 messages (5 reused) |
| Port occurrences | 44 |
| Upstream languages | 29 `.po` files, 1,672 translated, 161 untranslated, 52 fuzzy |
| Languages shipped by the port | 29 `.po` files, 1,561 translated, 152 untranslated, 56 fuzzy |
| Build/verify command | `scripts/catalogue.rb --compare` (this skill's own), cross-checked by hand (see below) |

Generated with `.claude/skills/translation-parity/scripts/catalogue.rb` on a
detached worktree of `origin/master` and on `ruby` directly, then
`--compare`. Raw output saved to `/tmp/translation-parity.yaml` (not
committed — it is a generated scratch artifact, not the ledger).

## The scanner undercounts the port by exactly 4 — and it's the scanner, not the port

The raw compare reported `ported: 37, gaps: 4`, all four being
`msgctxt: "shortcut window"` messages: `Focus the URL entry`, `General`,
`Quit`, `Show Shortcuts`. Before writing those down as gaps, the rule in
`translation-parity`'s own "When the scanner is the thing that is wrong"
section was followed: open the file before trusting the diff.

`lib/shortcuts_window.rb`:

```ruby
GROUP = c_('shortcut window', 'General')
SHORTCUTS = [
  [c_('shortcut window', 'Focus the URL entry'), '<primary>l'],
  [c_('shortcut window', 'Show Shortcuts'), '<primary>question'],
  [c_('shortcut window', 'Quit'), '<primary>q'],
].freeze
```

All four strings are correctly marked with the right context, the right
English, the right key. The scanner's marker regex
(`.claude/skills/translation-parity/scripts/msgid-census.sh`) only matches
uppercase `C_`/`NC_`/`p_`/`np_`/`pgettext`/`npgettext` for the
context-carrying forms. The Ruby `gettext` gem's own convention — and what
`lib/i18n.rb` actually defines — is **lowercase** `c_`:

```ruby
# lib/i18n.rb
def c_(context, message) = I18n.with_context(context, message)
```

So `with_context: 4` on upstream's side and `with_context: 0` on the
port's side in the generated YAML is a scanner defect (this is a shared,
org-wide script per the skill's own description — it was not patched in
this pass, in the interest of not hand-editing a shared resource mid-audit
without coordinating, but it should be: add `c_`/`nc_` to the marker
alternation). **Corrected by hand: all 4 of these messages are genuinely
ported.** Real count: **41/41 messages, 0 real gaps.**

## The one real text divergence: `Share Preview` in the metainfo `<name>`

`uses_mismatch` flagged `Share Preview` at 5 upstream call sites vs 4 port
call sites. Tracing every site:

| | Upstream | Port |
|---|---|---|
| App name, GLib | `src/application.rs:168`, `src/main.rs:24` (both `gettext("Share Preview")`) | `lib/about_dialog.rb:13`, `lib/main.rb:22`, `lib/window.rb:379` (all `_('Share Preview')`) |
| Desktop entry `Name=` | translatable (no `translate="no"`) | translatable (matches) |
| Metainfo `<name>` | `<name>Share Preview</name>` — **translatable** | `<name translate="no">Share Preview</name>` — **not translatable** |

The port's `data/org.rubygtkproject.SharePreview.metainfo.xml.in.in`
explicitly opts the app name out of translation in the one place upstream
leaves it in. The key itself still exists in the port's catalogue (reached
through the three `.rb` call sites), so this doesn't register as a missing
message — but it is a real, if small, behavioural difference: upstream
offers translators the chance to localise the app's display name in a
software-center listing; the port does not. Recorded as a **component-axis
text gap** in `component-parity.md`'s packaging-metadata unit, and named
here per the shared rule that a text divergence is tracked in both
ledgers.

## Languages: 29/29, byte-for-byte file list match

```
diff <(upstream po/*.po basenames) <(port po/*.po basenames)   # empty
```

29 `.po` files on both sides, same filenames, `LINGUAS` matches the file
list on both sides (31 lines each — the extra 2 lines over 29 are
`LINGUAS`'s own header/comment convention, present identically on both
sides). `locale/` carries 29 compiled directories, one per language.

`de` verified live: `test/drive_translated.rb`, re-run this session,
switches the process locale and asserts 20 known messages come back
translated, reporting `drive_translated: OK (20 messages in de)`. This
satisfies the skill's third proof requirement (the app actually speaks a
non-English locale on screen, headless-driven) — not merely the document
math.

`msgfmt`/`rmsgfmt` compilation: not independently re-verified in this
pass beyond the fact that `locale/*/LC_MESSAGES/*.mo` already exist in the
tree and `drive_translated.rb`'s runtime lookup succeeds against them,
which implies compilation happened and is current. A byte-level
`msgfmt -c` validation of all 29 `.po` files was not run — naming this as
an **unrun check**, per the skill's instruction, rather than claiming it
passed.

## Extra (untranslated, outside the count)

- `data/org.rubygtkproject.SharePreview.metainfo.xml.in.in:34` — `<p>This
  is a Ruby GTK4 and Libadwaita port of Share Preview, written against the
  original as its specification.</p>`. Not in any upstream catalogue
  (upstream has no such line — it's not upstream's app). English-only
  until someone translates it; this is expected and fine, and is exactly
  the kind of addition the skill says is "not parity work" and "not free."

## Minor housekeeping found, not scored

- `catalogue.rb` reports `unresolved: 1` on **both** sides, in both cases
  the marker's own definition line (`src/i18n.rs:26` upstream,
  `lib/i18n.rb:116` port) being matched as if it were a call site. Same
  scanner artifact on both trees, cancels out, not a real unresolved
  message on either side.

## Update (this audit): re-checked after the three newest commits

None of `36751a9`, `7359eb6`, or `a0ed3ef` touches `po/`, `locale/`,
`data/*.xml.in.in`, or any `_`/`c_`/`n_` call site — they are an inventory
correction, a Rake task, and a spec load-path fix respectively. Re-grepped
`data/org.rubygtkproject.SharePreview.metainfo.xml.in.in` this session and
confirmed the `<name translate="no">Share Preview</name>` divergence named
below is still present, byte-for-byte unchanged, and re-ran
`test/drive_translated.rb` (20/20 messages in `de`, still passing). Nothing
in this report's numbers moves this round.

## Summary (numbers, not an adjective)

```
41/41 messages (corrected for the c_ scanner gap) · 49/44 occurrences
(1 real-divergence call site: the metainfo <name>, tracked in
component-parity.md) · 29/29 languages · 1,561/1,672 translated strings
inherited · de verified live via test/drive_translated.rb
```

## Rules check

- No row was counted `ported` from reading the code alone without the
  census backing it up — the 4 corrected rows were corrected *because*
  the file was opened and the exact byte-identical msgid/context was
  found, per the skill's explicit procedure for a scanner miss.
- The scanner defect is named as a scanner defect, with the fix it needs
  (`c_`/`nc_` in the marker alternation), not silently worked around and
  left unreported.
- No upstream string was reworded to make a row pass; all three
  cross-checked example messages above are byte-identical.
- The one real text gap (metainfo `<name>` translatability) is recorded
  here and cross-referenced into `component-parity.md`, not hidden behind
  "ported: 41/41."
