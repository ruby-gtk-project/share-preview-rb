# frozen_string_literal: true

require 'adwaita'

require_relative 'card'
require_relative 'cards/discourse_card'
require_relative 'cards/facebook_card'
require_relative 'cards/linkedin_card'
require_relative 'cards/mastodon_card'
require_relative 'cards/twitter_card'
require_relative 'social'

# CardBox is the framed area the preview sits in, and the error state shown
# instead when the card could not be built.
#
# Ported from upstream's src/widgets/card.rs and its template
# data/resources/ui/card.ui: a box holding a stack with a "card" page — the
# rounded, clipped container the platform layout is appended into — and an
# "error" page carrying the "Card Error" heading and the message.
#
# Upstream loads the platform layout from one of the five cards/*.ui
# resources and pokes its objects by id; the port asks the matching card
# class in lib/cards for a built widget instead.
class CardBox
  CARD = 'card'
  ERROR = 'error'

  LAYOUTS = {
    discourse: Cards::DiscourseCard,
    facebook:  Cards::FacebookCard,
    linkedin:  Cards::LinkedinCard,
    mastodon:  Cards::MastodonCard,
    twitter:   Cards::TwitterCard,
  }.freeze

  # The message upstream's `new_from_error` writes for each CardError.
  ERROR_MESSAGES = {
    CardError::NOT_ENOUGH_DATA       => 'Couldn’t find enough data to generate a card for this social media.',
    CardError::TWITTER_NO_CARD_FOUND => 'Twitter: No card found.',
  }.freeze

  class << self
    def from_card(card)
      new.tap do |box|
        box.build
        box.set_card(card)
      end
    end

    def from_error(error)
      new.tap do |box|
        box.build
        box.set_error(error)
      end
    end
  end

  def build
    root.tap do |box|
      box.append(stack)

      stack.tap do |pages|
        pages.add_named(card_box, CARD)
        pages.add_named(error_box, ERROR)

        error_box.tap do |errors|
          errors.append(error_title)
          errors.append(error_message)
        end
      end
    end
  end

  # Appends the platform's layout and shows the card page.
  def set_card(card)
    card_box.append(LAYOUTS.fetch(card.social.key).new(card).build)
    stack.visible_child_name = CARD
  end

  # Shows the error page with the message for this CardError.
  def set_error(error)
    error_message.label = ERROR_MESSAGES.fetch(error.kind, error.message)
    stack.visible_child_name = ERROR
  end

  def root
    @root ||= Gtk::Box.new(:horizontal, 0).tap do |box|
      box.vexpand = true
    end
  end

  def stack = @stack ||= Gtk::Stack.new

  def card_box
    @card_box ||= Gtk::Box.new(:horizontal, 0).tap do |box|
      box.hexpand = true
      box.valign = :center
      box.overflow = :hidden
      box.add_css_class('card')
    end
  end

  def error_box
    @error_box ||= Gtk::Box.new(:vertical, 12).tap do |box|
      box.halign = :center
      box.valign = :center
    end
  end

  def error_title
    @error_title ||= Gtk::Label.new('Card Error').tap do |label|
      label.add_css_class('title-1')
    end
  end

  def error_message = @error_message ||= Gtk::Label.new
end
