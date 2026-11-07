# share-preview-rb — upstream component inventory

Survey step for the full-parity Ruby GTK4/Libadwaita port of
[Share Preview](https://github.com/rafaelmardojai/share-preview) (gtk-rs).
No app code written in this step.

**Upstream ref.** The task text named `origin/main`; this clone has no such
ref. The upstream implementation is on **`origin/master`** (`origin/HEAD`
points at `origin/ruby`, the port branch). Everything below was read with
`git show origin/master:<path>`.

**Upstream shape.** A GtkBuilder app: every component is a `.rs` subclass
beside a `.ui` template, so each port file unions two upstream files. Five of
the `.ui` files (`cards/*.ui`) have no subclass at all — they are plain
`<object>` trees loaded by `CardBox#set_card` at runtime and poked by id.

**Port shape.** The pilot (`gnome-contacts-rb`) puts the app class in
`lib/main.rb` and one component per `lib/<thing>.rb` sibling, with
`lib/<gem>/application.rb` as the gem shell. The port now follows that shape
throughout: `lib/main.rb` is `App`, `lib/share_preview/application.rb` is a
three-line alias onto it, and the 26 component files exist.

**Second re-survey.** This revision re-reads `lib/` and `data/` at commit
`5ea68dd` ("Parity reports"), after commit `a61ea35` ("Port packaging
metadata: desktop entry, metainfo, D-Bus service, GSettings schema") landed
the four data files the previous re-survey (at `797ace5`) still listed as
missing. They are confirmed present under their renamed, port-specific app
id: `data/org.rubygtkproject.SharePreview.desktop.in.in`,
`.metainfo.xml.in.in`, `.service.in` and `.gschema.xml.in`, verified by
listing `data/` directly rather than trusting the prior report's "no". The
component bodies are otherwise unchanged from the first reading of upstream
— upstream has not moved. `.reports/component-parity.md` (already on this
branch, commit `5ea68dd`) ran the 4-axis check on these four files ahead of
this re-survey and found one real text-axis divergence worth repeating here
rather than only there: upstream's `metainfo.xml.in.in` has
`<name>Share Preview</name>` with no `translate="no"`, so the app name is in
upstream's translatable catalogue; the port's copy has
`<name translate="no">Share Preview</name>`, opting out. See
`translation-parity.md` for the message-count consequence. There is no
remaining gap in "does the file exist" terms; the open items are the two
already-documented divergences (this one, and `lib/settings.rb` backing the
gschema's keys with a JSON file rather than reading an installed, compiled
schema) — both load-bearing enough to flag again below rather than drop now
that the files exist.

## What `lib/` has today

| File | Lines | What it is |
|---|---:|---|
| `lib/main.rb` | 191 | `App`: `Gtk::Application`, `Gtk::WindowGroup`, app actions, accels, `--new-window`, URI args |
| `lib/window.rb` | 556 | main window, primary menu, 4 stack pages, url box, count badges, `win.*` actions |
| `lib/card_box.rb` | 117 | card container + card-error state, dispatch onto the five card classes |
| `lib/cards/discourse_card.rb` | 134 | card layout |
| `lib/cards/facebook_card.rb` | 105 | card layout |
| `lib/cards/linkedin_card.rb` | 92 | card layout |
| `lib/cards/mastodon_card.rb` | 94 | card layout |
| `lib/cards/twitter_card.rb` | 109 | card layout |
| `lib/card_image.rb` | 103 | picture + fallback-icon stack |
| `lib/data_dialog.rb` | 348 | metadata dialog: view switcher, 2 search bars, 2 list boxes, 2 empty states |
| `lib/metadata_row.rb` | 84 | key/value list row |
| `lib/log_dialog.rb` | 70 | scraping-log dialog |
| `lib/log_row.rb` | 82 | log list row, 4 level variants |
| `lib/shortcuts_window.rb` | 56 | `Adwaita::ShortcutsDialog` (upstream's `GtkShortcutsWindow` is unconstructible from Ruby) |
| `lib/about_dialog.rb` | 37 | `Adwaita::AboutDialog` |
| `lib/log_item.rb` | 48 | model |
| `lib/log_model.rb` | 68 | model + log sink |
| `lib/metadata_item.rb` | 43 | model with real `key`/`value` properties |
| `lib/social.rb` | 126 | the five platforms and their constraints |
| `lib/card.rb` | 428 | card builder, sizes, card errors, log strings |
| `lib/data.rb` | 104 | scraped metadata |
| `lib/image.rb` | 310 | image fetch/decode/validate |
| `lib/scraper.rb` | 213 | HTTP + HTML scrape |
| `lib/http_client.rb` | 100 | **extra, no upstream file**: the transport `scraper.rb` and `image.rb` share, standing in for the Rust `reqwest` client |
| `lib/settings.rb` | 75 | GSettings (`social`, `dark-theme`) |
| `lib/style.rb` | 49 | CSS provider + icon-theme search path |
| `lib/share_preview.rb` | 3 | requires `share_preview/application` |
| `lib/share_preview/application.rb` | 12 | `SharePreview::Application = ::App` |

`data/style.css` (byte-identical to upstream's `data/resources/style.css`) and
`data/icons/hicolor/scalable/actions/{code,info,tag}-symbolic.svg` are carried
over too, plus an app icon at
`data/icons/hicolor/scalable/apps/org.rubygtkproject.SharePreview.svg`, and
now the four packaging files renamed under the port's own app id:
`data/org.rubygtkproject.SharePreview.{desktop.in.in,metainfo.xml.in.in,service.in,gschema.xml.in}`.
The placeholder status page that the first survey recorded is gone.

## Component map

`Exists` is read against `lib/` and `data/` on `ruby` at commit `5ea68dd`.

| # | Upstream file(s) | Port file | Kind | Exists |
|---|---|---|---|:-:|
| 1 | `src/application.rs`, `src/main.rs`, `src/i18n.rs`, `data/…desktop.in.in` | `lib/main.rb` | application + app actions + accels | yes |
| 2 | `src/window.rs`, `data/resources/ui/window.ui` | `lib/window.rb` | main window | yes |
| 3 | `data/resources/ui/window.ui` (`menu primary_menu`) | `lib/window.rb` (within) | primary menu | yes |
| 4 | `data/resources/ui/shortcuts.ui` | `lib/shortcuts_window.rb` | keyboard shortcuts window | yes |
| 5 | `src/application.rs` (`show_about_dialog`) | `lib/about_dialog.rb` | about dialog | yes |
| 6 | `src/widgets/card.rs`, `data/resources/ui/card.ui` | `lib/card_box.rb` | card container + card error state | yes |
| 7 | `data/resources/ui/cards/discourse.ui` | `lib/cards/discourse_card.rb` | card layout | yes |
| 8 | `data/resources/ui/cards/facebook.ui` | `lib/cards/facebook_card.rb` | card layout | yes |
| 9 | `data/resources/ui/cards/linkedin.ui` | `lib/cards/linkedin_card.rb` | card layout | yes |
| 10 | `data/resources/ui/cards/mastodon.ui` | `lib/cards/mastodon_card.rb` | card layout | yes |
| 11 | `data/resources/ui/cards/twitter.ui` | `lib/cards/twitter_card.rb` | card layout | yes |
| 12 | `src/widgets/image.rs`, `data/resources/ui/image.ui` | `lib/card_image.rb` | image widget + fallback state | yes |
| 13 | `src/widgets/data_dialog.rs`, `data/resources/ui/data-dialog.ui` | `lib/data_dialog.rb` | metadata dialog (2 pages, 2 empty states) | yes |
| 14 | `data/resources/ui/metadata-item.ui` | `lib/metadata_row.rb` | list row | yes |
| 15 | `src/widgets/log_dialog.rs`, `data/resources/ui/log-dialog.ui` | `lib/log_dialog.rb` | scraping-log dialog | yes |
| 16 | `src/widgets/log_dialog.rs` (`bind_model` closure) | `lib/log_row.rb` | list row (4 level variants) | yes |
| 17 | `src/models/log_item.rs` | `lib/log_item.rb` | model | yes |
| 18 | `src/models/log_model.rs`, `src/backend/log.rs` | `lib/log_model.rb` | model + log sink | yes |
| 19 | `src/models/metadata_item.rs` | `lib/metadata_item.rb` | model | yes |
| 20 | `src/backend/social.rs` | `lib/social.rb` | non-UI: platform constraints | yes |
| 21 | `src/backend/card.rs` | `lib/card.rb` | non-UI: card builder, size, errors | yes |
| 22 | `src/backend/data.rs` | `lib/data.rb` | non-UI: scraped metadata | yes |
| 23 | `src/backend/image.rs` | `lib/image.rb` | non-UI: image fetch/validate | yes |
| 24 | `src/backend/scraper.rs` | `lib/scraper.rb` | non-UI: HTTP + HTML scrape | yes |
| 25 | `data/…gschema.xml.in` | `lib/settings.rb` | non-UI: GSettings (`social`, `dark-theme`) | yes |
| 26 | `data/resources/style.css` | `lib/style.rb` + `data/style.css` | stylesheet: 7 app classes | yes |
| 27 | `data/resources/icons/{code,info,tag}-symbolic.svg` | `data/icons/hicolor/scalable/actions/` | 3 bundled symbolic icons | yes |
| 28 | `po/` (29 catalogues, `po/POTFILES.in`, `po/LINGUAS`) | `lib/i18n.rb` + `po/` + `locale/` | i18n | yes |
| 29 | `data/com.rafaelmardojai.SharePreview.desktop.in.in` | `data/org.rubygtkproject.SharePreview.desktop.in.in` | desktop launcher entry | yes |
| 30 | `data/com.rafaelmardojai.SharePreview.metainfo.xml.in.in` | `data/org.rubygtkproject.SharePreview.metainfo.xml.in.in` | AppStream metadata | yes (text divergence: `<name>` gained `translate="no"` — see `translation-parity.md`) |
| 31 | `data/com.rafaelmardojai.SharePreview.service.in` | `data/org.rubygtkproject.SharePreview.service.in` | D-Bus service activation file | yes |
| 32 | `data/com.rafaelmardojai.SharePreview.gschema.xml.in` | `data/org.rubygtkproject.SharePreview.gschema.xml.in` + `lib/settings.rb` | GSettings schema install file | yes (file ships and validates under `glib-compile-schemas --strict --dry-run`; `lib/settings.rb` itself still backs the two keys with a JSON file rather than reading the installed schema — documented substitution, not a gap in file presence) |
| — | none (new) | `lib/http_client.rb` | non-UI: shared HTTP transport | yes (extra) |

## 1. `src/application.rs` + `src/main.rs` → `lib/main.rb` — the application

| Widget / object | × | CSS | Signals / actions | Notes |
|---|---:|---|---|---|
| `Adw.Application` | 1 | — | `activate`, `startup`, `command_line` | flags `HANDLES_COMMAND_LINE`; app id `com.rafaelmardojai.SharePreview`; resource base path. **Quirk: `Adwaita::Application` is broken in the Ruby bindings — use `Gtk::Application`.** |
| `Gtk.WindowGroup` | 1 | — | — | every window joins it |
| `Adw.AboutDialog` | 1 | — | — | see §5 |

Actions installed: `app.quit`, `app.about`, `app.new-window`.
Accelerators: `app.quit` → `<primary>q`, `app.new-window` → `<primary>n`,
`win.url` → `<primary>l`.
Command line: `--new-window` / `-w`; bare URI args each open a window and call
`open_uri`. Desktop file adds an `Actions=new-window` launcher entry and
registers the `http`/`https` scheme handlers.
`src/main.rs` also sets the application name, prgname and default icon, and
`src/i18n.rs` supplies `gettext_f` (named `{var}` interpolation) — used once,
for `Server Error {status}`.

## 2. `src/window.rs` + `window.ui` → `lib/window.rb` — the main window

| Widget | × | CSS | Signals / actions | Notes |
|---|---:|---|---|---|
| `Adw.ApplicationWindow` | 1 | `devel` (Devel profile only) | — | `resizable=false`, 524×562, focus widget `url_entry`, title "Share Preview" |
| `Gtk.WindowHandle` | 1 | — | — | whole content is draggable |
| `Adw.ToastOverlay` | 1 | — | — | `toasts`; shows `Adwaita::Toast` "Invalid URL" |
| `Adw.ToolbarView` | 1 | — | — | two top bars, one content |
| `Gtk.HeaderBar` | 1 | — | — | `headerbar` |
| `Gtk.Button` (color scheme) | 1 | — | `clicked` → `on_color_scheme_clicked` | `display-brightness-symbolic`, tooltip "Toggle Color Scheme"; flips `Adw.StyleManager` between `ForceLight`/`ForceDark` |
| `Gtk.MenuButton` | 1 | — | — | `open-menu-symbolic`, tooltip "Main Menu", model `primary_menu` |
| `Gtk.Box` (url box) | 1 | `linked`, `urlbox` | — | `url_box`; `set_sensitive(false)` while loading |
| `Gtk.DropDown` | 1 | — | `notify::selected` → `on_social_selected` | model is a 5-item `Gtk.StringList`: Discourse, Facebook, LinkedIn, Mastodon, Twitter. Writes the `social` GSetting and re-renders the card |
| `Gtk.Entry` | 1 | `error` (added on invalid URL, removed on success) | `changed`, `activate`, `icon-press` | `input-purpose=url`, secondary icon `go-next-symbolic` with tooltip "Go", insensitive while empty |
| `Gtk.Stack` | 1 | — | — | crossfade; 4 pages: `splash`, `loading`, `error`, `card` |
| `Adw.StatusPage` | 1 | — | — | `splash`: title "Set a URL to preview", icon = app id |
| `Gtk.Spinner` | 1 | — | — | `loading` page, 32×32, started/stopped around the fetch |
| `Gtk.Label` (error title) | 1 | `title-1` | — | "Network Error" / "Unexpected Error" |
| `Gtk.Label` (error message) | 1 | — | — | "Couldn't connect to the given URL." / `Server Error {status}` |
| `Gtk.Box` (card box) | 1 | `card-container` | — | `cardbox`; holds the `CardBox` prepended by `update_card` |
| `Gtk.CenterBox` | 1 | — | — | bottom action row of the card page |
| `Gtk.Button` (metadata) | 1 | `pill` | `action-name win.metadata` | — |
| `Adw.ButtonContent` | 1 | — | — | `code-symbolic` + "View Metadata" |
| `Gtk.Button` (log) | 1 | `flat` | `action-name win.log` | tooltip "Show Logs" |
| `Gtk.Box` (counts) | 1 | — | — | spacing 3 |
| `Adw.ButtonContent` (counts) | 3 | **dynamic, per count**: `inf_count` `accent`↔`dim-label`; `war_count` `warning`↔`dim-label`; `err_count` `error`↔`dim-label` | — | icons `info-symbolic`, `dialog-warning-symbolic`, `dialog-error-symbolic`; labels set from `LogListModel#worrying_count` on `items-changed` |

Window actions installed in `class_init`: `win.run`, `win.metadata`,
`win.log`, `win.url` (grabs focus on the entry). `win.show-help-overlay` comes
free from `GtkApplicationWindow` + the `gtk/help-overlay.ui` resource alias.

Non-widget behaviour that is still part of this component:
- `run()`: prefixes `http://` when no scheme, rewrites the entry text, parses
  the URL, swaps to `loading`, fetches, then `card` or `error`; on a parse
  failure shows the "Invalid URL" toast and marks the entry `error`.
- `open_uri()`: sets the entry and runs — the command-line entry point.
- `setup_widgets()`: restores the `social` GSetting into the dropdown.
- `update_card()`: flushes the logger, rebuilds the `CardBox`, removes the old.

Repeaters: the three count `ButtonContent`s are fixed, not a repeater.
Conditional: the four stack pages; the devel CSS class.

## 3. `window.ui` `menu primary_menu` → within `lib/window.rb` — primary menu

Two sections, three items: "_New Window" → `app.new-window`; "_Keyboard
Shortcuts" → `win.show-help-overlay`; "_About Share Preview" → `app.about`.
No `custom:` slots.

## 4. `shortcuts.ui` → `lib/shortcuts_window.rb` — keyboard shortcuts

| Widget | × | CSS | Signals | Notes |
|---|---:|---|---|---|
| `Gtk.ShortcutsWindow` | 1 | — | — | `help_overlay`, modal; aliased into the resource as `gtk/help-overlay.ui` |
| `Gtk.ShortcutsSection` | 1 | — | — | `section-name=shortcuts`, `max-height=10` |
| `Gtk.ShortcutsGroup` | 1 | — | — | title "General" (msgctxt `shortcut window`) |
| `Gtk.ShortcutsShortcut` | 3 | — | — | "Focus the URL entry" → `win.url`; "Show Shortcuts" → `win.show-help-overlay`; "Quit" → `app.quit` |

`Gtk::ShortcutsWindow` is deprecated in GTK 4.18+; if the Ruby bindings make it
unusable, the pilot's hand-built `lib/shortcuts_dialog.rb` is the fallback
shape. Keep the same three rows and the same group title either way.

## 5. `src/application.rs` `show_about_dialog` → `lib/about_dialog.rb`

`Adw.AboutDialog`: application name "Share Preview", icon = app id, version,
license `GPL-3.0`, website `https://apps.gnome.org/SharePreview/`, issue URL,
one developer, two artists. Presented on the active window.

## 6. `src/widgets/card.rs` + `card.ui` → `lib/card_box.rb`

| Widget | × | CSS | Signals | Notes |
|---|---:|---|---|---|
| `Gtk.Box` (template root) | 1 | — | — | `vexpand` |
| `Gtk.Stack` | 1 | — | — | pages `card`, `error` |
| `Gtk.Box` (card) | 1 | `card` | — | `overflow=hidden`, `valign=center`; the per-social tree is appended here |
| `Gtk.Box` (error) | 1 | — | — | vertical, spacing 12 |
| `Gtk.Label` | 1 | `title-1` | — | "Card Error" |
| `Gtk.Label` (error message) | 1 | — | — | "Couldn't find enough data to generate a card for this social media." / "Twitter: No card found." |

`set_card` loads the social's `.ui` by name and applies `site`, `title`,
`description`, `image`, then runs a per-social tweak block — the orientation
flips, the visibility flips and the `description.set_lines` calls listed in §7–§11.
In the port this dispatch becomes five sibling classes under `lib/cards/`
rather than five resource loads.

## 7–11. `cards/*.ui` → `lib/cards/*_card.rb` — the five card layouts

Shared shape: a root `Gtk.Box` `card`, a `CardImage` `image` and three
`Gtk.Label`s (`site`, `title`, `description`) inside a `Gtk.Box` `textbox`
carrying `card-padding`. Every one of these labels is set unconditionally by
`CardBox#set_card`; the *visibility* and *orientation* differ:

| Port file | Widgets | CSS | Conditional behaviour (from `card.rs`) |
|---|---|---|---|
| `lib/cards/discourse_card.rb` | 4 `Gtk.Box`, 1 `Gtk.Image` (`favicon`, hidden by default), 1 `CardImage` (hidden), 3 `Gtk.Label` | `card-padding`, `title-4` | image shown when present; favicon shown only when the bytes decode to a `Gdk::Texture` |
| `lib/cards/facebook_card.rb` | 2 `Gtk.Box`, 1 `CardImage` (hidden), 3 `Gtk.Label` (`description` hidden) | `card-padding`, `title-4`, `dim-label` | image shown when present; description shown only when the title is ≤ 65 characters; root box turns horizontal on a Medium card |
| `lib/cards/linkedin_card.rb` | 2 `Gtk.Box`, 1 `CardImage` (hidden), 3 `Gtk.Label` (`description` hidden) | `card-padding`, `title-4`, `dim-label`, `caption` | image shown when present |
| `lib/cards/mastodon_card.rb` | 2 `Gtk.Box`, 1 `CardImage` (visible), 3 `Gtk.Label` (`description` hidden) | `card-padding`, `title-4` | root box turns horizontal on Medium; `CardImage#set_fallback` when there is no image; description always shown when present |
| `lib/cards/twitter_card.rb` | 2 `Gtk.Box`, 1 `CardImage` (hidden), 3 `Gtk.Label` (`description` hidden) | `card-padding`, `heading`, `dim-label` | image + description shown when present; Medium → horizontal and `description.lines = 3`; Large → `description.lines = 2` |

## 12. `src/widgets/image.rs` + `image.ui` → `lib/card_image.rb`

| Widget | × | CSS | Signals | Notes |
|---|---:|---|---|---|
| `Gtk.Box` (template root) | 1 | — | — | — |
| `Gtk.Stack` | 1 | — | — | crossfade; pages `fallback`, `image` |
| `Gtk.Box` (fallback) | 1 | — | — | sized from `CardSize#image_size` |
| `Gtk.Image` (fallback icon) | 1 | `dim-label` | — | `x-office-document-symbolic`, pixel size from `CardSize#icon_size` |
| `Gtk.Box` (image) | 1 | — | — | — |
| `Gtk.Picture` | 1 | — | — | width/height request from `CardSize#image_size`; falls back when `Gdk::Texture` decoding fails |

## 13. `src/widgets/data_dialog.rs` + `data-dialog.ui` → `lib/data_dialog.rb`

| Widget | × | CSS | Signals | Notes |
|---|---:|---|---|---|
| `Adw.Window` (template root) | 1 | — | — | 600×400, modal, destroy-with-parent, `transient_for` the window |
| `Adw.ToolbarView` | 1 | — | — | — |
| `Adw.HeaderBar` | 1 | — | — | title widget is the view switcher |
| `Adw.ViewSwitcher` | 1 | — | — | policy `wide`, bound to `viewstack` |
| `Gtk.Stack` (search bars) | 1 | — | — | `visible-child-name` bound to `viewstack` with `SYNC_CREATE` |
| `Gtk.SearchBar` | 2 | — | — | `search-mode-enabled=true`, always open |
| `Adw.Clamp` | 4 | — | — | 2 around the search entries, 2 around the page bodies (margins 24) |
| `Gtk.SearchEntry` | 2 | — | `notify::text` via `bind_property` | `search`, `images_search`; each text-bound to its `Gtk.StringFilter`(s) |
| `Adw.ViewStack` | 1 | — | — | `viewstack` |
| `Adw.ViewStackPage` | 2 | — | — | "Metadata" / `tag-symbolic`; "Body Images" / `image-x-generic-symbolic` |
| `Gtk.ScrolledWindow` | 2 | — | — | one per page |
| `Gtk.Box` | 2 | — | — | metadata page: outer vertical spacing 12, header vertical |
| `Gtk.Label` (title) | 1 | `heading` | — | the page title, or the URL when there is none; selectable, wrapping |
| `Gtk.Label` (url) | 1 | `caption` | — | selectable, wrapping |
| `Gtk.Stack` (metadata) | 1 | — | `items-changed` on the filter model drives it | pages `list`, `empty` |
| `Gtk.ListBox` (metadata) | 1 | `content` | — | `selection-mode=none`, bound to a `FilterListModel` |
| `Gtk.Label` (empty) | 1 | `title-1` | — | "Nothing to Show" |
| `Gtk.Stack` (images) | 1 | — | `items-changed` | pages `list`, `empty` |
| `Gtk.ListBox` (images) | 1 | `content` | — | `selection-mode=none` |
| `Gtk.Label` (empty) | 1 | `title-1` | — | "Nothing to Show" (second copy) |

Non-widget objects this component owns: `Gio.ListStore` of `MetadataItem`,
`Gtk.StringList` of body-image URLs, two `Gtk.StringFilter`s + a
`Gtk.AnyFilter` over `key` and `value` via `Gtk.PropertyExpression`, one
`StringFilter` over `string` for the images, and two incremental
`Gtk.FilterListModel`s.

Repeaters: both list boxes — one `MetadataRow` per metadata entry and one per
body image, counts driven by the scrape.
Empty states: two, both reached by the filter model emitting zero items (so an
empty scrape *and* a search with no matches land on the same page).

## 14. `metadata-item.ui` → `lib/metadata_row.rb`

| Widget | × | CSS | Signals | Notes |
|---|---:|---|---|---|
| `Gtk.ListBoxRow` | 1 | `metadata-item` | — | — |
| `Gtk.Box` | 2 | — | — | horizontal spacing 6 → vertical spacing 3, `hexpand` |
| `Gtk.Label` (key) | 1 | `caption-heading`, `dimmed-label` | — | selectable, `wrap-mode=word-char`; **hidden when there is no key** — the images list passes none |
| `Gtk.Label` (value) | 1 | — | — | selectable, `wrap-mode=word-char`; hidden when there is no value |

This is the one place upstream toggles `visible` on data, and it is load-bearing
(the Body Images rows have no key), so it is a deliberate exception to the house
rule against data-driven visibility. Note `dimmed-label` here vs `dim-label`
elsewhere — reproduce both spellings as written.

## 15. `src/widgets/log_dialog.rs` + `log-dialog.ui` → `lib/log_dialog.rb`

| Widget | × | CSS | Signals | Notes |
|---|---:|---|---|---|
| `Adw.Dialog` (template root) | 1 | — | — | 500×500 content, title "Scraping Log"; presented on the window |
| `Adw.ToolbarView` | 1 | — | — | — |
| `Adw.HeaderBar` | 1 | — | — | empty |
| `Gtk.ScrolledWindow` | 1 | — | — | `vexpand` |
| `Gtk.ListBox` | 1 | `logs`, `background` | — | `selection-mode=none`, `bind_model` over the `LogListModel` |
| `Gtk.SizeGroup` | 1 | — | — | horizontal, over every level label so the text columns align |

Repeater: one `LogRow` per `LogItem`.

## 16. `log_dialog.rs` `bind_model` closure → `lib/log_row.rb`

| Widget | × | CSS | Signals | Notes |
|---|---:|---|---|---|
| `Gtk.ListBoxRow` | 1 | — | — | built per item |
| `Gtk.Box` | 1 | `log-item` + **one of** `debug`+`dim-label`, `accent`, `warning`, `error` | — | spacing 12 |
| `Gtk.Label` (level) | 1 | `caption` (Debug only) | — | "DEBUG" / "INFO" / "WARNING" / "ERROR", all translated; `valign=start`, joined to the size group |
| `Gtk.Label` (text) | 1 | `caption` (Debug only) | — | wrapping, `hexpand`, selectable |

## 17–19. Models

- `src/models/log_item.rs` → `lib/log_item.rb`: a `level` (`LogLevel`) plus a
  `text` property. Needs no GObject property in Ruby — plain attributes are
  enough unless a filter model needs expressions.
- `src/models/log_model.rs` + `src/backend/log.rs` → `lib/log_model.rb`: a
  `Gio::ListModel` of `LogItem`, with `append`, `clear`, `worrying_count`
  (info/warning/error triple) and the `Log` sink's `log`/`flush`. Its
  `items-changed` is what drives the window's three count badges, so the port
  needs a real list model or an equivalent signal.
- `src/models/metadata_item.rs` → `lib/metadata_item.rb`: `key` and `value`
  GObject properties — **these two must stay real properties**, because
  `DataDialog` filters on them through `Gtk::PropertyExpression`.

## 20–25. Non-UI backend

| Upstream | Port | What the UI needs from it |
|---|---|---|
| `src/backend/social.rs` (185 ln) | `lib/social.rb` | the five platforms, their metadata lookup tables, their constraints, and `image_size`/`SocialImageSizeKind` |
| `src/backend/card.rs` (471 ln) | `lib/card.rb` | `Card.new` from `Data` + `Social`; `CardSize` (`image_size`, `icon_size`); `CardError::{NotEnoughData,TwitterNoCardFound}`; **6 translated log strings** emitted into the logger |
| `src/backend/data.rs` (159 ln) | `lib/data.rb` | `Meta`, `Data`, `get_meta`, `lookup_meta`, `lookup_meta_images`, `get_body_images` |
| `src/backend/image.rs` (313 ln) | `lib/image.rb` | fetch/decode/validate, `size`, `ImageError` with its translated messages, data-URL support, 5 MB cap, PNG/JPEG/GIF/WebP |
| `src/backend/scraper.rs` (179 ln) | `lib/scraper.rb` | async HTTP with redirects + HTML parse; `Error::{NetworkError,Unexpected}` feed the window's error page |
| `data/…gschema.xml.in` | `lib/settings.rb` | keys `social` (string, default `''`) and `dark-theme` (boolean, default false). **`dark-theme` is declared and never read** by upstream — the colour-scheme button only touches `Adw.StyleManager` and does not persist. Port the key, note the dead behaviour |

## 26–27. Stylesheet and icons

`data/resources/style.css` defines exactly seven app classes, all padding-only:
`.urlbox`, `.card-container`, `.card-padding`, `.metadata-item`, `.logs`,
`.log-item` (also `font-family: monospace`). Every one is applied somewhere
above; none is dead. Everything else (`title-1`, `title-4`, `heading`,
`caption`, `caption-heading`, `dim-label`, `dimmed-label`, `card`, `pill`,
`flat`, `linked`, `content`, `background`, `accent`, `warning`, `error`,
`devel`) comes from Adwaita.

Three symbolic icons ship in the GResource and are referenced by name:
`code-symbolic` (View Metadata), `info-symbolic` (info badge), `tag-symbolic`
(Metadata view-stack page). They are **not** in the system icon theme, so the
port must bundle them and register an icon-theme search path.

## 28. `po/` + `src/i18n.rs` → `lib/i18n.rb` + `po/` + `locale/` — translations

`po/LINGUAS` lists 29 languages; upstream's `po/POTFILES.in` lists 20 source
files (7 `.ui`, 3 `data/*.in`, 10 `.rs`). User-visible strings total roughly
45, including one `msgctxt "shortcut window"` group and the `gettext_f` named
placeholder `Server Error {status}`. **Ported** (commit `6453489`):
`lib/i18n.rb` binds the gettext domain via libc and supplies `_`, `c_` and
`f_`; the port's own `po/POTFILES.in` lists the Ruby sources; `rake pot` /
`rake translations` extract and compile; 61 of upstream's 66 message keys are
produced, the other five being the desktop/metainfo strings that have no
source file yet (see components 29–30, still gaps).

## 29–32. Desktop launcher, AppStream metadata, D-Bus service, GSettings schema file

All four now have a port counterpart under `data/` on `ruby`, landed in
commit `a61ea35`: `data/org.rubygtkproject.SharePreview.desktop.in.in`,
`.metainfo.xml.in.in`, `.service.in` and `.gschema.xml.in`, renamed onto the
port's own app id (`org.rubygtkproject.SharePreview`, from `lib/main.rb`'s
`App::APP_ID`) with the `@app-id@`/`@gettext-package@`/`@icon@` meson
substitutions filled in concretely, since this gem has no meson build step to
perform them; `@bindir@` is left as a genuine build-time placeholder in the
service file. These are not widgets, but they are user-facing: the desktop
entry is what the shell's launcher shows and what supplies the
`Actions=new-window` quick-launch entry and the `http`/`https` scheme
handlers that `lib/main.rb`'s command-line parsing assumes exist; the
metainfo file is what a software-center page reads; the service file is what
lets D-Bus activate the app by name; the gschema file is what
`glib-compile-schemas` reads to install the `social`/`dark-theme` keys, and
it validates clean under `glib-compile-schemas --strict --dry-run`.

Two things to still flag rather than call finished: (1) the metainfo file's
`<name>` carries `translate="no"` where upstream's does not — upstream puts
"Share Preview" in its translatable catalogue, the port opts it out; this is
a real text-axis divergence, not a correspondence, and it is the reason the
translation census's use-count for that string differs by one between the
two sides (see `translation-parity.md`). (2) the gschema *file* now exists
and validates, but `lib/settings.rb` does not read the keys from an
installed, compiled schema at runtime — it backs the same two keys with a
JSON file instead, to avoid requiring a system schema install just to run
the app from a checkout. Same keys, same defaults, same semantics, but the
file on disk is packaging truth the running app does not itself consult.
Neither of these two is "not applicable" or "by design" in the sense of
needing no further work — they are documented, deliberate divergences that a
reviewer should be able to find without re-deriving them, and whoever picks
up gschema-backed settings as real work still has that to do.

## Gaps and risks for the port

1. **Translations and the four packaging data files are both ported now; two
   named divergences remain, not file-presence gaps.** `po/` and
   `lib/i18n.rb` landed in commit `6453489`; the desktop entry, metainfo
   catalogue, D-Bus service file and GSettings schema landed in commit
   `a61ea35` (see components 28–32). What is left is the two divergences
   named in full under components 29–32: the metainfo `<name>` carrying
   `translate="no"` against upstream's translatable name, and
   `lib/settings.rb` backing the gschema's keys with a JSON file rather than
   reading them from an installed, compiled schema. Both are recorded, not
   swept into "by design" — see `.reports/accountability-ensurance.md` and
   `component-parity.md` for the fuller writeups and who still owes work on
   the second one if a real schema install is ever required.
2. **Two deliberate divergences from upstream, both recorded in the files:**
   - `lib/shortcuts_window.rb` builds an `Adwaita::ShortcutsDialog`, because
     `Gtk::ShortcutsWindow.new` raises *"GtkWindow is not subtype of
     GtkShortcutsWindow"* and GTK deprecates the widget anyway. Same group
     title, same three rows.
   - `lib/http_client.rb` has no upstream counterpart: it is the `reqwest`
     client that `scraper.rb` and `image.rb` share, split out rather than
     duplicated.
3. **`dark-theme` stays dead.** The GSetting is ported because upstream
   declares it, but upstream never reads it — the colour-scheme button only
   flips `Adw.StyleManager` and does not persist. Do not "fix" this into a
   behaviour difference.
4. **`metadata-item.ui` keeps its data-driven visibility.** The key label is
   hidden when there is no key, because the Body Images rows have none. This
   is the documented exception to the house rule, and `lib/metadata_row.rb`
   must keep it. Note also `dimmed-label` there against `dim-label`
   elsewhere — both spellings are reproduced as written.
5. **The risky binding surfaces are now exercised, so re-verify rather than
   re-plan:** `Gtk::PropertyExpression` + `Gtk::StringFilter` + `Gtk::AnyFilter`
   over `MetadataItem` in `lib/data_dialog.rb`, the `items-changed`-driven
   count badges in `lib/window.rb`, and the thread + `GLib::Idle.add` hop that
   replaces upstream's `async`/`spawn!`. `test/drive_window.rb` and
   `test/drive_cards.rb` are the drive scripts that cover them.
6. **No `.ui` files in the port** by design. `CardBox`'s resource-name
   dispatch became a lookup over the five `lib/cards/*.rb` classes.
7. **Upstream ref naming** — the port's tooling should say `origin/master`,
   not `origin/main`. Still true, and still worth fixing wherever the task
   text is generated.
