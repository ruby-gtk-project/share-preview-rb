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
`lib/<gem>/application.rb` as the gem shell. The port currently holds only
that shell plus a placeholder status page, so **nothing user-facing exists
yet**.

## What `lib/` has today

| File | What it is |
|---|---|
| `lib/share_preview.rb` | requires `share_preview/application` |
| `lib/share_preview/application.rb` | placeholder: `Gtk::Application`, `Adwaita::ApplicationWindow`, `Adwaita::ToolbarView`, `Adwaita::HeaderBar`, one `Adwaita::StatusPage` reading "The Ruby port has not been written yet." |
| `lib/share/preview/rb/version.rb` | gem version |

Nothing in upstream maps to the placeholder status page; it is scaffolding to
be replaced by `lib/main.rb`.

## Component map

| # | Upstream file(s) | Port file | Kind | Exists |
|---|---|---|---|:-:|
| 1 | `src/application.rs`, `src/main.rs`, `src/i18n.rs`, `data/…desktop.in.in` | `lib/main.rb` | application + app actions + accels | no |
| 2 | `src/window.rs`, `data/resources/ui/window.ui` | `lib/window.rb` | main window | no |
| 3 | `data/resources/ui/window.ui` (`menu primary_menu`) | `lib/window.rb` (within) | primary menu | no |
| 4 | `data/resources/ui/shortcuts.ui` | `lib/shortcuts_window.rb` | keyboard shortcuts window | no |
| 5 | `src/application.rs` (`show_about_dialog`) | `lib/about_dialog.rb` | about dialog | no |
| 6 | `src/widgets/card.rs`, `data/resources/ui/card.ui` | `lib/card_box.rb` | card container + card error state | no |
| 7 | `data/resources/ui/cards/discourse.ui` | `lib/cards/discourse_card.rb` | card layout | no |
| 8 | `data/resources/ui/cards/facebook.ui` | `lib/cards/facebook_card.rb` | card layout | no |
| 9 | `data/resources/ui/cards/linkedin.ui` | `lib/cards/linkedin_card.rb` | card layout | no |
| 10 | `data/resources/ui/cards/mastodon.ui` | `lib/cards/mastodon_card.rb` | card layout | no |
| 11 | `data/resources/ui/cards/twitter.ui` | `lib/cards/twitter_card.rb` | card layout | no |
| 12 | `src/widgets/image.rs`, `data/resources/ui/image.ui` | `lib/card_image.rb` | image widget + fallback state | no |
| 13 | `src/widgets/data_dialog.rs`, `data/resources/ui/data-dialog.ui` | `lib/data_dialog.rb` | metadata dialog (2 pages, 2 empty states) | no |
| 14 | `data/resources/ui/metadata-item.ui` | `lib/metadata_row.rb` | list row | no |
| 15 | `src/widgets/log_dialog.rs`, `data/resources/ui/log-dialog.ui` | `lib/log_dialog.rb` | scraping-log dialog | no |
| 16 | `src/widgets/log_dialog.rs` (`bind_model` closure) | `lib/log_row.rb` | list row (4 level variants) | no |
| 17 | `src/models/log_item.rs` | `lib/log_item.rb` | model | no |
| 18 | `src/models/log_model.rs`, `src/backend/log.rs` | `lib/log_model.rb` | model + log sink | no |
| 19 | `src/models/metadata_item.rs` | `lib/metadata_item.rb` | model | no |
| 20 | `src/backend/social.rs` | `lib/social.rb` | non-UI: platform constraints | no |
| 21 | `src/backend/card.rs` | `lib/card.rb` | non-UI: card builder, size, errors | no |
| 22 | `src/backend/data.rs` | `lib/data.rb` | non-UI: scraped metadata | no |
| 23 | `src/backend/image.rs` | `lib/image.rb` | non-UI: image fetch/validate | no |
| 24 | `src/backend/scraper.rs` | `lib/scraper.rb` | non-UI: HTTP + HTML scrape | no |
| 25 | `data/…gschema.xml.in` | `lib/settings.rb` | non-UI: GSettings (`social`, `dark-theme`) | no |
| 26 | `data/resources/style.css` | `lib/style.rb` (or `data/style.css`) | stylesheet: 7 app classes | no |
| 27 | `data/resources/icons/{code,info,tag}-symbolic.svg` | `data/icons/` | 3 bundled symbolic icons | no |
| 28 | `po/` (30 catalogues, `po/POTFILES.in`) | translation setup | i18n | no |

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

## 28. Translations

`po/LINGUAS` lists 30 languages; `po/POTFILES.in` lists 20 source files
(7 `.ui`, 3 `data/*.in`, 10 `.rs`). User-visible strings total roughly 45,
including one `msgctxt "shortcut window"` group and the `gettext_f` named
placeholder `Server Error {status}`. The port needs its own extraction list and
should carry the existing catalogues over rather than restart them.

## Gaps and risks for the port

1. **Everything is missing.** `lib/` has a placeholder only; all 28 rows are new work.
2. **`Adwaita::Application` / `Adwaita::ApplicationWindow`** — the skill flags `Adwaita::Application` as broken; use `Gtk::Application`. The existing placeholder already uses `Adwaita::ApplicationWindow.new(app)` successfully, so keep that.
3. **`Gtk::ShortcutsWindow` is deprecated** in current GTK; verify it exists in the bindings before committing to §4, else hand-build it like the pilot.
4. **`Gtk::PropertyExpression` + `Gtk::StringFilter` + `Gtk::AnyFilter`** over a custom GObject (`MetadataItem`) is the riskiest binding surface in the app. Verify early; the fallback is a `Gtk::CustomFilter` or filtering in Ruby and rebuilding the list box.
5. **Async.** Upstream's fetch is `async`/`spawn!`. Ruby has no equivalent in the bindings; the port needs a thread plus `GLib::Idle.add` to get back on the main loop, or the spinner never animates.
6. **No `.ui` files in the port** by design — the five `cards/*.ui` trees and `metadata-item.ui` become Ruby classes, and `CardBox`'s resource-name dispatch becomes a lookup table of five classes.
7. **Upstream ref naming** — the port's tooling should say `origin/master`, not `origin/main`.
