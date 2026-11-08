# Component parity — share-preview-rb

| | |
|---|---|
| Upstream | `origin/master` @ `2d36059` |
| Port | `ruby` @ `27ab64a` |
| Units with full 4-axis parity confirmed | 27 / 32 (3 flagged, 2 corrected from a stale gap) |

This reads `.reports/component-inventory.md`'s 32-row map as the unit list
and checks axes 1–4 (count, style, behaviour, text) against the running
port, per `component-parity`'s Step 3–5. Steps 4 and 5 (CSS actually
rendering, signals actually firing) were done by running the app headless
and driving it — `ruby-gtk-testing`'s mechanism, via the four `test/drive_*.rb`
scripts under `nix develop --command xvfb-run -a ruby test/drive_*.rb` — not
by reading source and assuming.

## Headline: the runtime gate is narrower than its own claim, and its own number moved

This round's runtime gate reports **"14 checks passed, 0 failed, covering 30
components."** (The prior round's gate, for the identical 14/0, said "20
components" — see `test-parity.md` for why that drift is itself a finding,
not an improvement.) The 14/0 is true of exactly one file, `test/drive_actions.rb`
(confirmed by re-running it: `14 of 14 checks passed` / `DRIVE OK`, the
only file in `test/` whose assertion unit is `check(...)` and the only one
that prints `DRIVE OK`/`DRIVE FAILED`). The other three driver scripts —
`drive_cards.rb`, `drive_window.rb`, `drive_translated.rb` — were **not**
counted in that "14 checks" figure, because they don't call `check()`; they
collect failure strings into an array and print one pass/fail verdict per
file, not per assertion. Re-running them directly:

```
drive_cards.rb:      30 card boxes built, both error cards, log dialog (4 rows), data dialog (2 metadata + 1 image row) — OK
drive_window.rb:     card render + log counts, 6 log lines, every platform cycled, both dialogs opened — OK
drive_translated.rb: 20 messages verified in de — OK
```

All four scripts pass. So the **actual** verified coverage this round is
wider than "14 checks / 20 components" suggests — but that number, taken on
its own, is also not something anyone could reconstruct from the other
three files' output, because they report no per-assertion count at all. A
reader of the gate alone would not know `drive_cards.rb`/`drive_window.rb`/
`drive_translated.rb` exist, or that they, too, passed. See
`accountability-ensurance.md` for why a report that's narrower than the
work actually done is still a finding, not a clean bill.

**Separately and more seriously:** `Rakefile` now has a `drive` task
(commit `7359eb6`, added after the last round) — but `.gitlab-ci.yml`'s
`test` stage still runs only `bin/rspec spec`, and `spec/` still contains
only `spec_helper.rb` and `README.md` — zero example files. CI is green by
running nothing; a local Rake task existing doesn't change what GitLab
actually executes. See `test-parity.md` for the full update.

## Unit-by-unit axis check

Units not listed below were checked on all 4 axes from the inventory's own
tables plus a direct read of the port file and found to match upstream
with no open question (CSS classes present and defined, signals connected,
actions named literally, text marked with `_`/`c_`/`n_` at the right site).
Listed here are only the units with something to say.

### Unit: shortcuts window — `data/resources/ui/shortcuts.ui` → `lib/shortcuts_window.rb`

| Widget | Up × | Port × | CSS | Signals | Text | Verdict |
|---|---:|---:|---|---|:-:|---|
| `Gtk.ShortcutsWindow` → `Adw.ShortcutsDialog` | 1 | 1 | — | — | — | **correspondence** |
| `Gtk.ShortcutsSection`/group | 1 | 1 | — | — | ✓ | parity |
| `Gtk.ShortcutsShortcut` ×3 | 3 | 3 | — | — | ✓* | parity |

`Gtk::ShortcutsWindow.new` raises in the Ruby bindings ("GtkWindow is not
subtype of GtkShortcutsWindow"); the port substitutes `Adw.ShortcutsDialog`,
same group title ("General"), same three rows, same accelerators, same
`msgctxt "shortcut window"`. Per `component-parity`'s own rule — "a widget
replaced by a strictly newer equivalent... record the substitution and the
reason" — this is a documented correspondence, not a gap. *Text axis
footnote: see `translation-parity.md` — the automated census scanner
initially reported these four strings as untranslated; that was a scanner
defect (it only recognises uppercase `C_`/`NC_`, not the Ruby gettext gem's
lowercase `c_`), not a real gap. Reading `lib/shortcuts_window.rb` directly
confirms all four are `c_('shortcut window', ...)`.

### Unit: packaging metadata — `data/*.in`/`*.in.in` → `data/org.rubygtkproject.SharePreview.*`

Count axis: all four files now exist (corrected from `component-inventory.md`'s
stale "no" — see `component-identification.md`). Style/behaviour axes don't
apply to these files. Text axis has one real, if small, divergence:

- Upstream's `data/com.rafaelmardojai.SharePreview.metainfo.xml.in.in` has
  `<name>Share Preview</name>` with **no** `translate="no"` — the app name
  is in upstream's translatable catalogue.
- The port's `data/org.rubygtkproject.SharePreview.metainfo.xml.in.in` has
  `<name translate="no">Share Preview</name>` — explicitly opted out of
  translation.

This is why the translation census's "uses" count for the message `Share
Preview` comes out 5 upstream vs 4 port (see `translation-parity.md`). It's
a one-line, easily-defended choice (app names commonly go untranslated) but
it is a real behavioural difference from upstream, not a correspondence the
port gets to claim for free, and it is recorded as a gap in
`translation-parity.md` rather than waved through here.

The gschema file carries an extra authored comment explaining that
`lib/settings.rb` backs the same two keys with a JSON file instead of an
installed, compiled GSettings schema (to avoid requiring a system schema
install just to run the app from a checkout). This is a **documented
substitution with equivalent behaviour** — same keys (`social`,
`dark-theme`), same defaults, same semantics, verified by reading
`lib/settings.rb` — not an omission, and the reasoning is given alongside
the behaviour rather than instead of it, so it does not read as an excuse
for missing work. It is flagged here only so a reviewer knows the gschema
file on disk is packaging truth that the running app does not itself read
from the installed schema path.

### Unit: window count badges / `items-changed` wiring (`lib/window.rb`, `lib/log_model.rb`)

This is the risk the inventory itself flags as the binding surface most
likely to be silently wrong (`Gtk::PropertyExpression` + `Gtk::StringFilter`
+ `Gtk::AnyFilter`, and the `items-changed`-driven count badges). Directly
driven by `test/drive_window.rb` this run: `card shown; log counts (info,
warning, error) = [1, 0, 0]` after a real scrape, and
`test/drive_cards.rb`: `log dialog: 4 rows, counts [1, 1, 1]` after a
synthetic log. Both match the behaviour the inventory describes. Confirmed
working, not just read as plausible.

### Unit: data dialog search/filter (`lib/data_dialog.rb`)

`test/drive_actions.rb`'s checks confirm this at the behaviour level: empty
state with no metadata, both rows present before searching, search narrows
to one row, an unmatched search flips to the empty state. The `uses_mismatch`
the translation census reports for `Nothing to Show` (upstream 2 call sites
in two template copies, port 1 call site) is **not** a gap — `lib/data_dialog.rb`
factors the label into one `empty_label` helper called from two memoized
accessors (`metadata_empty`, `images_empty`), so two real widget instances
exist; the census undercounts because it's reading lexical occurrence of
the string literal, not call sites of the helper. Confirmed by reading
lines 235–237 and 316–321 of `lib/data_dialog.rb`.

## Stylesheet (axis 2, both halves)

`data/style.css` vs upstream's `data/resources/style.css`: **byte-identical**
(`diff` returns nothing). All seven app classes (`.urlbox`, `.card-container`,
`.card-padding`, `.metadata-item`, `.logs`, `.log-item`) are therefore
defined with the same rules; the open question is only whether the port's
widgets attach them, which the inventory's per-unit tables already record
and this review did not find any case of a class attached on one side and
not the other.

## Rules check

- No unit here claims parity from the scan/inventory alone — every one
  above was either driven headless this run or read at the exact line.
- The one real cross-component text gap found (`Share Preview` metainfo
  translatability) is recorded in both this ledger and
  `translation-parity.md`, per the shared rule that a text-axis gap lives
  in both places.
- The stale "4 gaps" in `component-inventory.md` is not silently
  reconciled — it's named here and in `component-identification.md` as a
  stale report, not quietly corrected and left unremarked.

## Update (this round): metainfo `<name>` translatability fixed

The divergence described above (port's `<name translate="no">` vs.
upstream's plain `<name>`) is fixed: the port's
`data/org.rubygtkproject.SharePreview.metainfo.xml.in.in` now matches
upstream on this attribute. Row 30 of `.reports/component-inventory.md`
still shows the pre-fix wording from when it was written; this note is the
pointer to the current state rather than a silent rewrite of that row.

## Update (this round): re-driven at `1e1c133` — no behavioural change, gate metric drifted a third time

Re-ran all four `test/drive_*.rb` scripts against the port at `1e1c133`
("Capture screenshots from the actions drive script, add gtk_driver
helper") with upstream unchanged at `2d36059`. All four still pass
(14/14, `drive_cards`/`drive_window`/`drive_translated` all OK — see
`test-parity.md`'s update for the full output). The commit's actual
content is additive-only to the test harness (screenshot capture to
`tmp/shots/`, a vendored `test/gtk_driver.rb`), touching no `lib/` or
`data/` unit, so none of the per-unit findings above change: the
shortcuts-window correspondence, the stylesheet byte-identity, the
window/log-model behaviour, and the data-dialog search/filter behaviour
were all re-confirmed live rather than re-read from memory.

One thing to flag rather than silently re-approve: `drive_actions.rb`'s
new screenshot step reports two of five shots "skipped: widget produced
no render node" (the splash page and the data dialog). The script does
not treat this as a failure (it's a `shot ... skipped` log line, not a
`check`), and the three shots that *do* render (network error, unexpected
error, loaded card) land under `tmp/shots/`, confirmed present on disk
this session. This is accepted as a known headless-rendering limitation
(GTK ties render-node production to an actual compositor frame, which
Xvfb+software rendering doesn't always produce for every widget state) —
not a parity gap, since the screenshot step is observability sugar added
on top of the 14 checks, not a replacement for any of them, and the 14/14
checks it wraps still run and still pass regardless of whether a given
shot renders.

Still open from prior rounds, not improved this round: the runtime gate
reports "29 components" this time, a third distinct figure (20 → 30 →
29) for the identical 14/0 check count, with `.reports/components.json`
still at 32/32 present and nothing in this commit touching the unit map.
See `test-parity.md`'s update for the full statement; it is not repeated
twice in the same words here, but it means this document cannot say the
runtime gate corroborates "all units verified" — only this round's direct
drive-script re-run can, and it does, for the units the four scripts
actually touch.

## Update (this round): re-driven at `5f6d600` — unchanged tree, gate metric drifted a fourth time

No new commit exists to re-check this round (port `HEAD` is `5f6d600`,
identical to the commit the prior round's reports describe; upstream
unchanged at `2d36059`). Re-ran all four `test/drive_*.rb` scripts rather
than assuming the prior round's pass still holds: all four pass with the
same numbers as before (14/14, 30 card boxes, log counts `[1,0,0]`/
`[1,1,1]`, 20 `de` messages). Every per-unit finding above — the shortcuts-
window correspondence, the byte-identical stylesheet, the window/log-model
badge behaviour, the data-dialog search/filter behaviour, the metainfo
`<name>` fix — was re-confirmed against the current tree, not re-read from
memory, and nothing has changed.

The runtime gate this round reports "14 checks passed, 0 failed, covering
10 components" — a fourth distinct figure (20 → 30 → 29 → 10) for the
identical 14/0 check count, against a component map that has sat at 32/32
for four rounds running with zero commits between the last two. This
document cannot derive "10" from any unit table above, and does not try
to. The verified parity remains what every unit row above states: driven
live, matched to upstream, with the one documented correspondence
(shortcuts dialog) and the one small, now-fixed historical divergence
(metainfo `<name>`) already accounted for.
