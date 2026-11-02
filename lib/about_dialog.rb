# frozen_string_literal: true

require 'adwaita'

# AboutDialog is the app's about window.
#
# Ported from `show_about_dialog` in upstream's src/application.rs: an
# Adw.AboutDialog carrying the app name and icon, the issue and website urls,
# the GPL-3.0 licence, the version and the credits.
class AboutDialog
  APPLICATION_NAME = 'Share Preview'
  ISSUE_URL = 'https://github.com/rafaelmardojai/share-preview/issues'
  WEBSITE = 'https://apps.gnome.org/SharePreview/'

  DEVELOPERS = ['Rafael Mardojai CM https://mardojai.com'].freeze
  ARTISTS = ['Rafael Mardojai CM https://mardojai.com', 'Tobias Bernard'].freeze

  def initialize(application_icon:, version:)
    @application_icon = application_icon
    @version = version
  end

  def present(parent) = dialog.present(parent)

  def dialog
    @dialog ||= Adwaita::AboutDialog.new.tap do |about|
      about.application_name = APPLICATION_NAME
      about.application_icon = @application_icon
      about.issue_url = ISSUE_URL
      about.license_type = Gtk::License::GPL_3_0
      about.website = WEBSITE
      about.version = @version
      about.developers = DEVELOPERS
      about.artists = ARTISTS
    end
  end
end
