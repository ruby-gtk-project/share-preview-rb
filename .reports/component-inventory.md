# share-preview-rb — component inventory

Survey of upstream's user-facing surface (`origin/master`, Rust/GTK4) against
the `ruby` branch's `lib/`. One row per unit, in the order a user meets them.
No app code was written for this survey.

## Summary

Upstream has 1 application class, 1 window, 1 composite card widget (+5 social
card partials), 1 card-image widget, 2 dialogs, 1 standalone metadata row
template, 1 shortcuts window, 3 backend models (Data/Card/Image/Log via
`src/backend`), 3 GObject models (`LogItem`, `LogListModel`, `MetadataItem`),
1 GSettings schema (2 keys), 5 social card `.ui` partials, and a `po/`
catalogue with 28 locales. **Every one of these already has a corresponding
file on `ruby`.** This is a survey, not a gap list — `lib/` is a complete,
one-upstream-file-to-one-`lib/file.rb` port of the whole app's component
surface. (Behavioral/signal-level parity is out of scope for this survey —
see the `component-parity` skill for that pass.)

## Components

### 1. Application — `src/application.rs` + `src/main.rs` → `lib/main.rb` (class `App`)
**Kind:** application class (no widget of its own).
Actions: `app.quit`, `app.about`, `app.new-window`. Accels: `<primary>q`,
`<primary>n`, plus window accels `win.url` (`<primary>l`) and
`win.show-help-overlay` (`<primary>question`). Owns the `Gtk::WindowGroup`,
the `--new-window`/`-w` command-line option, and per-URI window dispatch.
**Present:** yes — `lib/main.rb` (class `App`), plus the gem-facing alias
`lib/share_preview/application.rb`.

### 2. About dialog — `show_about_dialog()` in `src/application.rs` → `lib/about_dialog.rb` (class `AboutDialog`)
**Kind:** dialog (`Adw.AboutDialog`/`Adwaita::AboutDialog`).
Carries app name/icon, issue URL, website, GPL-3.0 license, version, developer
and artist credits.
**Present:** yes — `lib/about_dialog.rb`.

### 3. Main window — `src/window.rs` + `data/resources/ui/window.ui` → `lib/window.rb` (class `Window`)
**Kind:** window (`Adw.ApplicationWindow` template `SharePreviewWindow`).
Widgets: `Gtk.WindowHandle` → `Adw.ToastOverlay` (`toasts`) → `Adw.ToolbarView`
with `Gtk.HeaderBar` (`headerbar`: `color_scheme` button, `menu_button`
`Gtk.MenuButton` + `primary_menu` menu model — 2 sections, 3 items: New
Window/Keyboard Shortcuts/About), the linked `url_box` (`Gtk.DropDown` social
+ `Gtk.Entry` url_entry with secondary go-next icon), and a `Gtk.Stack`
(`stack`) with 4 pages: `splash` (`Adw.StatusPage` start_page), `loading`
(`Gtk.Spinner` spinner), `error` (`error_title`/`error_message` labels),
`card` (`cardbox` + metadata/log buttons with `inf_count`/`war_count`/
`err_count` `Adw.ButtonContent`s).
Actions installed: `win.run`, `win.metadata`, `win.log`, `win.url`.
Signals: `color_scheme.clicked` → `on_color_scheme_clicked` (toggles
`Adw.StyleManager` color scheme); `url_entry.changed` →
`on_url_entry_changed` (icon sensitivity); `url_entry.activate` and
`icon-press` → `win.run`; `social` `notify::selected` →
`on_social_selected` (persists to GSettings, re-renders card);
`logger.items-changed` → recomputes info/warning/error counts and their
`accent`/`warning`/`error`/`dim-label` CSS classes.
CSS: `linked`, `urlbox`, `card-container`, `pill`, `flat`, `title-1`, `devel`
(profile-conditional).
**Present:** yes — `lib/window.rb`.

### 4. Shortcuts window — `data/resources/ui/shortcuts.ui` (no backing source file) → `lib/shortcuts_window.rb`
**Kind:** standalone `Gtk.ShortcutsWindow` template, no owning class upstream.
One section "shortcuts", one group "General", three shortcuts: focus URL
entry (`win.url`), show shortcuts (`win.show-help-overlay`), quit (`app.quit`).
**Present:** yes — `lib/shortcuts_window.rb`.

### 5. Card box — `src/widgets/card.rs` + `data/resources/ui/card.ui` → `lib/card_box.rb` (class `CardBox`)
**Kind:** composite widget (`Gtk.Box` template `CardBox`).
Widgets: `Gtk.Stack` (`stack`) with pages `card` (`cardbox` Gtk.Box, CSS
`card`) and `error` (title-1 label + `error_message`).
Behaviour: `set_card`/`new_from_card` loads one of 5 per-social `.ui`
partials by resource path, fills `site`/`title`/`description`/`image`
(`CardImage`) from the scraped `Card`, and applies per-social tweaks (see
rows 6–10). `new_from_error` shows the `error` page with a
`CardError`-derived message (`NotEnoughData`, `TwitterNoCardFound`).
**Present:** yes — `lib/card_box.rb` (and `lib/card.rb` for the per-social
tweak logic / `Card`-to-widget wiring).

### 6–10. Social card partials — `data/resources/ui/cards/{discourse,facebook,linkedin,mastodon,twitter}.ui` → `lib/cards/{discourse,facebook,linkedin,mastodon,twitter}_card.rb`
**Kind:** 5 named (non-template) `Gtk.Box` roots, each embedding a
`CardImage` (`image`) plus `site`/`title`/`description` labels. Not `<template>`
roots — loaded by resource path and destructured by id, same join unit as the
component-identification skill's "named top-level object" case.
- **Discourse**: `card-padding`; header row with `favicon` (`Gtk.Image`,
  hidden by default) + `site` label (ellipsized); body row with `image`
  (`CardImage`, hidden by default) + vertical title(`title-4`)/description.
- **Facebook**: `image` (hidden by default) above `textbox` (`card-padding`):
  `site` (`dim-label`), `title` (`title-4`, 2 lines, ellipsized),
  `description` (hidden by default, ellipsized). Horizontal orientation
  toggle + description visibility driven by `CardSize::Medium` /
  title-length ≤ 65 chars in `card.rs`.
- **LinkedIn**: `image` (hidden by default) above `textbox`: `title`
  (`title-4`, 2 lines), `site` (`dim-label caption`), `description` (hidden,
  never shown by `card.rs`).
- **Mastodon**: `image` (visible) above `textbox` (valign center): `site`,
  `title` (`title-4`, ellipsized), `description` (hidden by default).
  Horizontal toggle on `CardSize::Medium`; falls back to `CardImage#fallback`
  when no image.
- **Twitter**: `image` (hidden) above `textbox`: `title` (`heading`,
  ellipsized), `description` (hidden, wraps, line-limited by size), `site`
  (`dim-label`).
**Present:** yes — all 5 under `lib/cards/`.

### 11. Card image — `src/widgets/image.rs` + `data/resources/ui/image.ui` → `lib/card_image.rb` (class `CardImage`)
**Kind:** composite widget (`Gtk.Box` template `CardImage`).
`Gtk.Stack` (`stack`, crossfade) with pages `fallback` (`fallback_box` →
`fallback_icon` `Gtk.Image`, icon `x-office-document-symbolic`, CSS
`dim-label`) and `image` (`image` `Gtk.Picture`). `set_image`/`set_fallback`
size the box/picture to the social's `CardSize` and swap stack pages.
**Present:** yes — `lib/card_image.rb`.

### 12. Data dialog — `src/widgets/data_dialog.rs` + `data/resources/ui/data-dialog.ui` → `lib/data_dialog.rb` (class `DataDialog`)
**Kind:** dialog (`Adw.Window` template `DataDialog`).
Widgets: `Adw.ToolbarView` → `Adw.HeaderBar` with an `Adw.ViewSwitcher`
titled on an `Adw.ViewStack` (`viewstack`, pages `metadata`/`images`); a
`Gtk.Stack` of two `Gtk.SearchBar`s (bound to `viewstack`'s visible page) each
wrapping an `Adw.Clamp` + `Gtk.SearchEntry` (`search`, `images_search`); each
view-stack page holds a scrolled `Adw.Clamp` with a `Gtk.Stack`
(`stack`/`images_stack`) toggling between a `Gtk.ListBox` (`list`/
`images_list`, CSS `content`) and an empty-state `title-1` label "Nothing to
Show".
Models/behaviour: `gio::ListStore` of `MetadataItem` + `gtk::StringList` of
image URLs, each with a `StringFilter`/`AnyFilter` bound (`SYNC_CREATE`) to
its search entry's text, feeding a `FilterListModel` bound to its `ListBox`
via `bind_model`; `items-changed` on each filter model switches its stack
between `list`/`empty`.
**Present:** yes — `lib/data_dialog.rb`.

### 13. Metadata row — `metadata_row()` in `src/widgets/data_dialog.rs` + `data/resources/ui/metadata-item.ui` → `lib/metadata_row.rb` (class `MetadataRow`)
**Kind:** standalone (non-template) `Gtk.ListBoxRow` object, CSS
`metadata-item`; a vertical `key`/`value` label pair (`key`:
`caption-heading dimmed-label`), each hiding itself (`set_visible(false)`)
when its text is absent. Built once per metadata item / image URL row in
`DataDialog`'s two `bind_model` factories — a repeater, N rows per filtered
item.
**Present:** yes — `lib/metadata_row.rb`.

### 14. Log dialog — `src/widgets/log_dialog.rs` + `data/resources/ui/log-dialog.ui` → `lib/log_dialog.rb` (class `LogDialog`)
**Kind:** dialog (`Adw.Dialog` template `LogDialog`, 500×500 content).
`Adw.ToolbarView` → `Adw.HeaderBar` + scrolled `Gtk.ListBox` (`list`, CSS
`logs background`) bound via `bind_model` to the window's `LogListModel`.
**Present:** yes — `lib/log_dialog.rb`.

### 15. Log row — row factory inside `LogDialog::new` (no separate upstream file; built in `src/widgets/log_dialog.rs`) → `lib/log_row.rb` (class `LogRow`)
**Kind:** repeater — one `Gtk.ListBoxRow` built per `LogItem`, built in code
(no `.ui`): a `Gtk.Box` (spacing 12, CSS `log-item` + per-level class) with a
size-grouped level label (`caption`, text "DEBUG"/"INFO"/"WARNING"/"ERROR")
and a wrapping, selectable text label. Per-level CSS: `debug dim-label`,
`accent`, `warning`, `error`.
**Present:** yes — `lib/log_row.rb`.

### 16. Log model — `src/models/log_model.rs` + `src/models/log_item.rs` → `lib/log_model.rb` (`LogListModel`), `lib/log_item.rb` (`LogItem`)
**Kind:** non-widget GObject models (`Gio.ListModel`/`GObject`) — behaviour,
not screen presence; listed because the window and log dialog bind to them.
`LogListModel#worrying_count` drives the window's info/warning/error button
badges; `flush` clears the log on each run.
**Present:** yes — `lib/log_model.rb`, `lib/log_item.rb`.

### 17. Metadata item model — `src/models/metadata_item.rs` → `lib/metadata_item.rb` (`MetadataItem`)
**Kind:** non-widget GObject model (`key`/`value` properties), backs the
data dialog's filtered `ListStore`.
**Present:** yes — `lib/metadata_item.rb`.

### 18. Backend — `src/backend/{data,card,image,log,scraper,social}.rs` → `lib/{data,card,image,log_item,scraper,social}.rb` + `lib/http_client.rb`
**Kind:** non-widget backend (scraping, `Card`/`Data`/`Image` value types,
`Social` enum + constraints, HTTP client). Not components by the skill's
definition (no widget tree), included because the window, card box and data
dialog all depend on their shapes (`CardSize`, `CardError`, `Error`
variants used in window.rb's error-page text).
**Present:** yes.

### 19. Preferences / GSettings — `data/com.rafaelmardojai.SharePreview.gschema.xml.in` → `lib/settings.rb` (class `Settings`)
**Kind:** GSettings schema, 2 keys: `dark-theme` (bool, default false — unused
dead key upstream, color scheme is runtime-toggled via `Adw.StyleManager`
instead) and `social` (string, default `''`, persists the last-picked social
dropdown selection).
**Present:** yes — `lib/settings.rb`.

### 20. Stylesheet — `data/resources/style.css` → `lib/style.rb`
**Kind:** app stylesheet (not a widget), defines `urlbox`, `card-container`,
`card`, `card-padding`, `metadata-item`, `logs`, `log-item` and friends
referenced by the rows above.
**Present:** yes — `lib/style.rb`.

### 21. i18n — `src/i18n.rs` → `lib/i18n.rb`
**Kind:** gettext setup/helpers (`gettext_f`), not a component but the thing
every translatable string above goes through.
**Present:** yes — `lib/i18n.rb`.

### 22. `po/` catalogue → no `lib/` equivalent (packaging-level)
28 locale `.po` files + `share-preview.pot` + `POTFILES.in`/`LINGUAS`. Not a
widget; a port of the Ruby app is responsible for exposing translatable
strings via `gettext`, which `lib/i18n.rb` already does, but reproducing the
upstream `.po` *catalogue* itself is a packaging/build-system concern, not a
widget-tree component. Flagged for the `translation-parity` skill, not here.

## Not ported as separate `lib/` files, and why that's fine

- `src/widgets/mod.rs`, `src/backend/mod.rs`, `src/models/mod.rs`,
  `src/config.rs.in` — Rust module wiring / build-time constants, no
  Ruby equivalent needed (handled by `require_relative` + `lib/main.rb`
  constants).
- `data/resources/resources.gresource.xml`, `data/resources/meson.build`,
  `data/*.in`, `meson.build` family — GResource/build packaging, out of
  scope for a widget-tree inventory.

## Conclusion

No missing component files were found. The `ruby` branch already has a
`lib/*.rb` file for every upstream window, dialog, composite widget, model and
settings schema. This survey intentionally stopped at *presence* — it did not
verify signal-for-signal / CSS-class-for-CSS-class behavioral parity inside
each file, which is the `component-parity` skill's job and should be run next,
file by file, starting with `lib/window.rb` and `lib/card.rb` (the two
largest/most signal-dense files).
