# frozen_string_literal: true

require 'adwaita'

require_relative 'i18n'
require_relative 'metadata_item'
require_relative 'metadata_row'

# DataDialog lists everything scraped from the page: every meta tag on one
# page, every body image url on the other, each searchable.
#
# Ported from upstream's src/widgets/data_dialog.rs and its template
# data/resources/ui/data-dialog.ui: an Adw.Window whose header carries an
# Adw.ViewSwitcher over a two-page Adw.ViewStack, with a search bar per page
# in a stack bound to the view stack's visible page. Each list is a
# Gtk::FilterListModel over its own model, filtered by the matching search
# entry, and each swaps to its "Nothing to Show" page when the filter leaves
# it empty.
class DataDialog
  DEFAULT_WIDTH = 600
  DEFAULT_HEIGHT = 400

  METADATA = 'metadata'
  IMAGES = 'images'
  LIST = 'list'
  EMPTY = 'empty'

  def initialize(data)
    @data = data
  end

  def build
    window.tap do |dialog|
      dialog.content = toolbar_view

      toolbar_view.tap do |view|
        view.add_top_bar(header_bar)
        view.add_top_bar(search_stack)
        view.content = view_stack

        header_bar.tap do |bar|
          bar.title_widget = view_switcher
        end

        search_stack.tap do |pages|
          pages.add_named(metadata_search_bar, METADATA)
          pages.add_named(images_search_bar, IMAGES)

          metadata_search_bar.tap do |bar|
            bar.child = metadata_search_clamp
            metadata_search_clamp.child = metadata_search
          end

          images_search_bar.tap do |bar|
            bar.child = images_search_clamp
            images_search_clamp.child = images_search
          end
        end

        view_stack.tap do |pages|
          pages.add_titled(metadata_page, METADATA, _('Metadata')).icon_name = 'tag-symbolic'
          pages.add_titled(images_page, IMAGES, _('Body Images')).icon_name = 'image-x-generic-symbolic'

          metadata_page.tap do |scroller|
            scroller.child = metadata_clamp
            metadata_clamp.child = metadata_box

            metadata_box.tap do |box|
              box.append(heading_box)
              box.append(metadata_stack)

              heading_box.tap do |heading|
                heading.append(title_label)
                heading.append(url_label)
              end

              metadata_stack.tap do |stack|
                stack.add_named(metadata_list, LIST)
                stack.add_named(metadata_empty, EMPTY)
              end
            end
          end

          images_page.tap do |scroller|
            scroller.child = images_clamp
            images_clamp.child = images_stack

            images_stack.tap do |stack|
              stack.add_named(images_list, LIST)
              stack.add_named(images_empty, EMPTY)
            end
          end
        end

        view_stack.bind_property(
          'visible-child-name',
          search_stack,
          'visible-child-name',
          :sync_create,
        )
      end

      set_metadata
      set_images
    end
  end

  # Fills the metadata list and wires its search and empty state.
  def set_metadata
    title_label.label = site_title
    url_label.label = @data.url.to_s

    @data.metadata.each do |meta|
      metadata_model.append(MetadataItem.new(meta_key(meta), meta.content.to_s))
    end

    metadata_search.bind_property(
      'text',
      key_filter,
      'search',
      :sync_create,
    )
    metadata_search.bind_property(
      'text',
      value_filter,
      'search',
      :sync_create,
    )

    watch(metadata_filter_model, metadata_stack)

    metadata_list.bind_model(metadata_filter_model) do |item|
      MetadataRow.new(item.key, item.value).build
    end
  end

  # Fills the body-image list and wires its search and empty state.
  def set_images
    @data.body_images.each { |image| images_model.append(image.url.to_s) }

    images_search.bind_property(
      'text',
      images_filter,
      'search',
      :sync_create,
    )

    watch(images_filter_model, images_stack)

    images_list.bind_model(images_filter_model) do |item|
      MetadataRow.new(nil, item.string).build
    end
  end

  def present(parent)
    build.tap do |dialog|
      dialog.transient_for = parent
      dialog.present
    end
  end

  def window
    @window ||= Adwaita::Window.new.tap do |dialog|
      dialog.set_default_size(DEFAULT_WIDTH, DEFAULT_HEIGHT)
      dialog.modal = true
      dialog.destroy_with_parent = true
    end
  end

  def toolbar_view = @toolbar_view ||= Adwaita::ToolbarView.new

  def header_bar = @header_bar ||= Adwaita::HeaderBar.new

  def view_switcher
    @view_switcher ||= Adwaita::ViewSwitcher.new.tap do |switcher|
      switcher.stack = view_stack
      switcher.policy = :wide
    end
  end

  def view_stack = @view_stack ||= Adwaita::ViewStack.new

  def search_stack = @search_stack ||= Gtk::Stack.new

  def metadata_search_bar = @metadata_search_bar ||= search_bar

  def images_search_bar = @images_search_bar ||= search_bar

  def metadata_search_clamp = @metadata_search_clamp ||= search_clamp

  def images_search_clamp = @images_search_clamp ||= search_clamp

  def metadata_search = @metadata_search ||= Gtk::SearchEntry.new

  def images_search = @images_search ||= Gtk::SearchEntry.new

  def metadata_page = @metadata_page ||= scrolled_window

  def images_page = @images_page ||= scrolled_window

  def metadata_clamp = @metadata_clamp ||= content_clamp

  def images_clamp = @images_clamp ||= content_clamp

  def metadata_box = @metadata_box ||= Gtk::Box.new(:vertical, 12)

  def heading_box = @heading_box ||= Gtk::Box.new(:vertical, 0)

  def title_label
    @title_label ||= Gtk::Label.new.tap do |label|
      label.xalign = 0
      label.selectable = true
      label.wrap = true
      label.add_css_class('heading')
    end
  end

  def url_label
    @url_label ||= Gtk::Label.new.tap do |label|
      label.xalign = 0
      label.selectable = true
      label.wrap = true
      label.add_css_class('caption')
    end
  end

  def metadata_stack = @metadata_stack ||= list_stack

  def images_stack = @images_stack ||= list_stack

  def metadata_list = @metadata_list ||= list_box

  def images_list = @images_list ||= list_box

  def metadata_empty = @metadata_empty ||= empty_label

  def images_empty = @images_empty ||= empty_label

  def metadata_model = @metadata_model ||= Gio::ListStore.new(MetadataItem.gtype)

  def images_model = @images_model ||= Gtk::StringList.new([])

  def key_filter = @key_filter ||= property_filter(MetadataItem.gtype, 'key')

  def value_filter = @value_filter ||= property_filter(MetadataItem.gtype, 'value')

  def images_filter = @images_filter ||= property_filter(Gtk::StringObject.gtype, 'string')

  # The key and value filters are grouped so a search matches either.
  def metadata_filter
    @metadata_filter ||= Gtk::AnyFilter.new.tap do |filter|
      filter.append(key_filter)
      filter.append(value_filter)
    end
  end

  def metadata_filter_model = @metadata_filter_model ||= filter_model(metadata_model, metadata_filter)

  def images_filter_model = @images_filter_model ||= filter_model(images_model, images_filter)

  private

    def site_title
      case @data.title
      when nil then @data.url.to_s
      else @data.title
      end
    end

    # Upstream joins the meta's name attribute and every one of its property
    # values with spaces to make the row's key.
    def meta_key(meta) = ([meta.name].compact + meta.property).join(' ')

    def search_bar
      Gtk::SearchBar.new.tap do |bar|
        bar.search_mode = true
      end
    end

    def search_clamp
      Adwaita::Clamp.new.tap do |clamp|
        clamp.hexpand = true
      end
    end

    def scrolled_window
      Gtk::ScrolledWindow.new.tap do |scroller|
        scroller.hexpand = true
        scroller.vexpand = true
      end
    end

    def content_clamp
      Adwaita::Clamp.new.tap do |clamp|
        clamp.margin_top = 24
        clamp.margin_bottom = 24
      end
    end

    def list_stack
      Gtk::Stack.new.tap do |stack|
        stack.transition_type = :none
        stack.vhomogeneous = false
        stack.vexpand = true
      end
    end

    def list_box
      Gtk::ListBox.new.tap do |box|
        box.selection_mode = :none
        box.valign = :start
        box.add_css_class('content')
      end
    end

    def empty_label
      Gtk::Label.new(_('Nothing to Show')).tap do |label|
        label.wrap = true
        label.justify = :center
        label.add_css_class('title-1')
      end
    end

    def property_filter(gtype, property)
      Gtk::StringFilter.new.tap do |filter|
        filter.expression = Gtk::PropertyExpression.new(gtype, nil, property)
      end
    end

    def filter_model(model, filter)
      Gtk::FilterListModel.new(model, filter).tap do |filtered|
        filtered.incremental = true
      end
    end

    # Swaps a list's stack to its empty page whenever the filter leaves it
    # with nothing, the way upstream's items-changed handler does.
    def watch(model, stack)
      model.signal_connect('items-changed') { |*| show_items(model, stack) }
      show_items(model, stack)
    end

    def show_items(model, stack)
      case model.n_items.positive?
      when true then stack.visible_child_name = LIST
      else stack.visible_child_name = EMPTY
      end
    end
end
