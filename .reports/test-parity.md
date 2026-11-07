# Test parity — share-preview-rb

| | |
|---|---|
| Upstream | `origin/master` @ `2d36059` |
| Port | `ruby` @ `27ab64a` |
| Upstream tests | 0 |
| Ported | 0 |
| Gaps | 0 |
| Test command (CI's) | `bin/rspec spec` |
| Test command (the thing that actually exercises the app) | `nix develop --command xvfb-run -a ruby test/drive_*.rb` (not wired to any target) |

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

## The gap: none of this is in any build target

This is the finding this skill exists to surface even when the test-count
math says 0/0.

- `Rakefile` defines no `drive` task, and no task of any name invokes any
  `test/drive_*.rb` file. `grep -n "drive" Rakefile` returns nothing.
- `.gitlab-ci.yml`'s `test` stage runs `bundle exec appraisal ... bin/rspec
  spec --tag ~ci_skip`. `spec/` contains exactly two files:
  `spec_helper.rb` and `README.md`. There is no `spec/*_spec.rb` anywhere
  in the tree. **CI's test stage runs zero examples and reports green.**
  A green CI badge on this port currently proves nothing about the app;
  it proves RSpec can be invoked with an empty example list.
- The task's own runtime gate ("14 checks passed... covering 20
  components") is sourced from one of the four scripts
  (`test/drive_actions.rb`) run by hand this session or a prior one, not
  from a CI run or a Rake task. It is real — re-running it reproduces the
  same 14/14 — but it is not reproducible by anyone who runs the commands
  the repository actually advertises (`rake test`, `rake spec`, the GitLab
  pipeline). The only place the full command is written down is the dev
  shell's own banner (`drive the app: xvfb-run ruby test/drive_*.rb`),
  which is advice to a human at a prompt, not a CI invocation.

So: test parity against upstream is 0/0 and genuinely met. But a reader
who sees "14 checks passed, 0 failed" in a gate and nothing else would
reasonably conclude the port has an automated, re-run-on-every-change test
suite. It does not. It has four good manual drive scripts and a CI
pipeline that executes nothing. That gap — between what the gate reports
and what actually re-runs automatically — is the one worth fixing, and
it is a build-system gap (one more line in `Rakefile`, one task that calls
all four scripts under `xvfb-run`, wired into `.gitlab-ci.yml`), not an app
gap.

## Rules check

- No ported-test row was fabricated to pad a count; the ledger states 0/0
  because that's what upstream has.
- The "no safety net" consequence is stated explicitly, per the skill's
  instruction for exactly this case, rather than left as something the
  reader has to infer from a 0/0 header.
- The four drive scripts are listed as `## Extra`, with real numbers
  (lines, assertions, what they drove), not as a vague "there are some
  tests."
- The CI gap (empty `spec/`, no `drive` task) is reported as a gap in its
  own right, per the task's instruction to treat a narrow or unwired
  runtime gate as a parity gap rather than evidence of completion.
