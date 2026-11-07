# share-preview-rb — component identification (refresh)

| | |
|---|---|
| Upstream | `origin/master` @ `2d36059` ("Translated using Weblate (Georgian)") |
| Port | `ruby` @ `27ab64a` ("Add a drive script covering app/window actions, error states and search") |

This is a refresh of `.reports/component-inventory.md`, which already does the
full per-file, per-widget inventory (32 rows, upstream file ↔ port file
mapping, widget/CSS/signal tables for every unit). That document is not
redone wholesale here — it is read, verified against the current tree, and
corrected where it is stale.

## Finding: the existing inventory is stale on 4 of its 32 rows

`.reports/component-inventory.md` is dated to commit `797ace5` and lists
components 29–32 (the `.desktop.in.in` launcher entry, `.metainfo.xml.in.in`
AppStream catalogue, `.service.in` D-Bus activation file, and a
`.gschema.xml` install file) as **missing** (`Exists: no`).

They are not missing. `git log` shows the inventory document was written at
commit `1750019` ("Inventory upstream components"), and commit `a61ea35`
("Port packaging metadata: desktop entry, metainfo, D-Bus service, GSettings
schema") landed **after** it. Checking the current tree:

```
data/org.rubygtkproject.SharePreview.desktop.in.in
data/org.rubygtkproject.SharePreview.gschema.xml.in
data/org.rubygtkproject.SharePreview.metainfo.xml.in.in
data/org.rubygtkproject.SharePreview.service.in
```

all four exist now, each with a header comment naming the upstream file it
was ported from. So the inventory's "4 gaps" finding is itself out of date —
a stale report, committed to the repo, making a claim about the tree that
is no longer true. It is the kind of thing `accountability-ensurance`
exists to catch when it runs the other direction (a stale claim of *success*
hiding a real gap); here it runs the safe direction (a stale claim of
*gap* that is actually closed), but it is still a report in `.reports/`
that disagrees with the tree it describes, and the next reader has no way
to know that without re-deriving it, which is what this refresh does.

**Action taken:** none to the file itself (rewriting someone else's dated
survey mid-audit would just produce a second stale document); the
correction lives here and in `component-parity.md`'s row for this unit.

## Everything else in the inventory still reads correctly

Spot-checked against the current tree rather than re-run from scratch
(budget), focusing on the places most likely to have drifted since
`797ace5`:

- `lib/cards/*.rb` (5 files), `lib/card_box.rb`, `lib/card_image.rb`,
  `lib/data_dialog.rb`, `lib/metadata_row.rb`, `lib/log_dialog.rb`,
  `lib/log_row.rb`, `lib/shortcuts_window.rb`, `lib/about_dialog.rb`,
  `lib/window.rb`, `lib/main.rb` — all present, all still match the
  one-upstream-file(s)-to-one-port-file mapping the inventory records.
- `data/style.css` is byte-identical to upstream's
  `data/resources/style.css` (`diff` confirms this — see
  `component-parity.md`).
- `app.quit` / `app.new-window` / `win.url` accelerators and `win.run` /
  `win.metadata` / `win.log` / `win.url` actions are installed in
  `lib/main.rb` and `lib/window.rb` exactly where the inventory says, and
  match upstream's `src/application.rs` / `src/window.rs` install sites
  literal-for-literal.
- `lib/shortcuts_window.rb` is the one place the port *does* carry a
  bindings-forced divergence from the house "no `.ui`, memoized widgets"
  shape that the inventory already calls out (`Adw.ShortcutsDialog` instead
  of an unconstructible `Gtk.ShortcutsWindow`) — confirmed still true and
  still the only one.

No new components found that the existing inventory missed, and no
component it lists has disappeared from `lib/`.

## What this step did not re-derive

A full re-scan with `component-scan.sh` against a freshly built GIR symbol
table was not run this pass — the existing inventory's widget/CSS/signal
tables are detailed enough (built the same way this skill asks for) that
redoing them wholesale would reproduce the same 32 rows. What *was* run
fresh, and feeds `component-parity.md` and `translation-parity.md` instead
of this document, is the translation census comparison and the headless
drive-script runs, both of which touch the same unit boundaries.
