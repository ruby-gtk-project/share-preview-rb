# Test parity — share-preview-rb

| | |
|---|---|
| Upstream | `origin/main` @ `2d36059` |
| Port | `ruby` @ `a0ed3ef` (refreshed this audit; prior round was `27ab64a`) |
| Upstream tests | 0 |
| Ported | 0 |
| Gaps | 0 |
| Test command (CI's) | `bin/rspec spec` — still 0 examples |
| Test command (the thing that actually exercises the app) | `nix develop --command xvfb-run -a ruby test/drive_*.rb`, now also `rake drive` — neither is in `.gitlab-ci.yml` |

## Upstream has no test suite

Checked directly, not assumed: `git ls-tree -r --name-only origin/master`
has no `tests/` directory and no file matching `*test*`; `Cargo.toml` has
no `[[test]]` section; a full scan of every `.rs` file on `origin/master`
for `#[test]`, `#[cfg(test)]`, `fn test_` returns nothing. Upstream Share
Preview ships zero tests.

Per `test-parity`'s own rule for this exact situation: parity is **0/0,
met trivially**, and — the part that must not be left implied — **the port
therefore inherits no safety net.** Every check the port has was written
for the port and pins nothing that the upstream authors found worth
pinning down. This is not a defect in the port; it is a fact about what
"parity" can mean here, stated so the next reader doesn't read 0/0 as
"nothing to verify."

## What the port has instead (the `## Extra` section, outside the count)

- `test/drive_actions.rb` — 294 lines, 14 `check(...)` calls. Drives: the
  splash page, an invalid URL adding the `error` CSS class, a refused
  connection, a 404, `win.run` through the action group, `app.new-window`,
  the colour-scheme toggle flipping `Adw::StyleManager.dark?`, `win.url`
  focusing the entry, `win.show-help-overlay`, the data dialog's empty
  state, both metadata rows before searching, a search narrowing to one
  row, an unmatched search's empty state, and `app.about` presenting
  without raising. Re-run this session under
  `nix develop --command xvfb-run -a ruby test/drive_actions.rb`: **14 of
  14 checks passed, `DRIVE OK`.**
- `test/drive_cards.rb` — 135 lines. Builds 30 card boxes (every platform ×
  size combination the inventory records), both card-error variants, the
  log dialog (asserts 4 rows, worrying-count `[1, 1, 1]`), the data dialog
  (asserts 2 metadata rows, 1 image row). Re-run: prints `drive_cards: OK`.
  Uses `failures = []` / `case failures` rather than a per-call `check`, so
  it contributes 0 to any `check`-based count, but it is real, passing
  coverage.
- `test/drive_window.rb` — 105 lines. Runs a live scrape against a local
  HTTP fixture, asserts the card renders and the log's worrying-count is
  `[1, 0, 0]`, asserts 6 log lines appear with the expected levels and
  text, cycles every platform in the dropdown, opens both the shortcuts
  and about dialogs. Re-run: prints `drive_window: OK`.
- `test/drive_translated.rb` — 102 lines. Switches the process locale and
  asserts 20 messages come back translated in `de`. Re-run: prints
  `drive_translated: OK (20 messages in de)`.

Total: **4 scripts, 636 lines, at minimum 14 named assertions plus three
whole-scenario pass/fail scripts that between them touch every unit in
`component-inventory.md` except the shortcuts/about dialogs' *contents*
and the packaging metadata files** (neither of which upstream tests either,
since upstream has no tests at all). All four pass when actually run.

## Update (this audit): `rake drive` now exists — CI still doesn't call it

Since the last round, commit `7359eb6` ("Wire the headless drive scripts
into a rake task") added a `drive` task to `Rakefile`:

```ruby
desc "Run every headless GTK drive script under Xvfb (requires the Nix dev shell)"
task :drive do
  DRIVE_SCRIPTS.each do |script|
    sh "nix", "develop", "--command", "xvfb-run", "-a", "ruby", script
  end
end
```

Re-verified this session by running all four scripts by hand under
`nix develop --command xvfb-run -a ruby test/drive_*.rb` (not `rake drive`
itself, which shells out to `nix develop` again and is slow/nested from
inside this sandbox): `drive_actions.rb` 14/14 `DRIVE OK`, `drive_cards.rb`
OK (30 card boxes, both error cards, log dialog 4 rows/[1,1,1], data dialog
2+1 rows), `drive_window.rb` OK (card renders, log counts `[1,0,0]`, 6 log
lines, every platform cycled, both dialogs opened), `drive_translated.rb`
OK (20 messages in `de`). The commit's own claim holds.

**This closes half the gap, not all of it.** `grep -n "drive" Rakefile`
now finds it — but `grep -n "drive" .gitlab-ci.yml` finds **nothing**.
`.gitlab-ci.yml`'s `test` stage still runs only `bin/rspec spec --tag
~ci_skip`, and `spec/` still contains exactly `spec_helper.rb` and
`README.md` — zero `*_spec.rb` files, confirmed by re-running the dev
shell's own rspec invocation this session:

```
No examples found.
0 examples, 0 failures
```

(A second, independent thing changed since the last round and is worth
naming so it isn't mistaken for the same fix: commit `a0ed3ef` added the
missing `lib/share/preview/rb.rb` version file and made
`require "kettle/test/rspec"` rescue-optional in `spec_helper.rb`. Before
that commit, `rake spec`/the dev shell's rspec command **raised** a
`LoadError` before collecting any examples — a harder failure than "0
examples, green." That is a real fix, re-verified above, but it fixes
"RSpec crashes" into "RSpec runs 0 examples," not into "RSpec covers the
app." The gate's actual coverage still comes entirely from the four
`test/drive_*.rb` scripts, which `.gitlab-ci.yml` never invokes.)

So the pipeline that GitLab actually runs on a push is unchanged: it
installs gems, runs `bin/rake --tasks` as a smoke test, and runs an empty
RSpec suite. **It never runs `rake drive` and never runs Xvfb.** The only
way the four real checks get exercised is a human (or an agent) typing the
command by hand, exactly as before. `rake drive` existing makes that
command one word shorter; it does not make it automatic, and nothing in
the repo claims otherwise — but nothing fixes the actual CI gap either.
That is this round's finding, not a softened repeat of the last one.

## The runtime gate's own number doesn't match the repository

This round's gate reports "14 checks passed, 0 failed, covering 30
components." The 14/0 reproduces exactly (see above). The "30 components"
does not map onto anything written down in this tree: `.reports/
component-inventory.md` enumerates **32** numbered units (1 through
29–32, several of which are multi-row groups); the gate's own prior run
(recorded in the last round's reports) said "20 components" for the same
14/0 checks. No file in `lib/`, `exe/`, `test/`, or `.reports/` defines
what "a component" is for gate-counting purposes, so there is no way to
reconcile 20 vs. 30 vs. 32 from inside the repository — all three numbers
describe the same 14-assertion script (`drive_actions.rb`) plus, at most,
whatever the other three un-gated scripts touch. Per the task's own
instruction to treat a narrow or inconsistent gate as a parity gap rather
than evidence of completion: an unexplained, moving "components covered"
figure is exactly that. It is named here rather than quietly accepted.

## The gap, restated for this round

- `Rakefile` now has a `drive` task (fixed, re-verified above).
- `.gitlab-ci.yml` still never calls it, and its `test` stage still runs
  zero RSpec examples while reporting green. **This is the same build-
  system gap as last round, just one layer narrower than it was.**
- The gate's "components covered" figure cannot be derived from anything
  in the repository and has changed between rounds without explanation.

Test parity against upstream is still 0/0 and genuinely met (upstream ships
no tests — re-confirmed: `git ls-tree -r --name-only origin/main` has no
`tests/` directory and no `*test*`/`#[test]`/`#[cfg(test)]` anywhere). But
"the port has a real, reproducible, automated test suite" is still not
true of anything GitLab actually runs, and the gate's headline number is
not traceable to the tree it is supposedly describing.

## Rules check

- No ported-test row was fabricated to pad a count; the ledger states 0/0
  because that's what upstream has.
- The "no safety net" consequence is stated explicitly, per the skill's
  instruction for exactly this case, rather than left as something the
  reader has to infer from a 0/0 header.
- The four drive scripts are listed as `## Extra`, with real numbers
  (lines, assertions, what they drove), not as a vague "there are some
  tests."
- The CI gap (empty `spec/`, `.gitlab-ci.yml` never calling `rake drive`)
  is reported as a gap in its own right, per the task's instruction to
  treat a narrow or unwired runtime gate as a parity gap rather than
  evidence of completion — updated this round to reflect that `rake
  drive` now exists in `Rakefile` (real progress) while `.gitlab-ci.yml`
  is untouched (the gap that remains), rather than either overclaiming
  the fix or ignoring it.
- The gate's unexplained "20 components" → "30 components" drift between
  rounds is named rather than silently accepted as a bigger, better
  number.
