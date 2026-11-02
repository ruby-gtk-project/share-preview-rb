# frozen_string_literal: true

# Social is one of the five supported platforms, with the meta-tag lookups,
# fetch constraints and image dimensions that platform expects.
#
# Ported from upstream's src/backend/social.rs: the `Social` enum with its
# `lookups`, `constraints` and `image_size` methods, plus the
# `SocialMetaLookup` / `SocialConstraints` / `SocialImageConstraints` structs
# the enum returns and the `SocialImageSizeKind` enum they are keyed by.
class Social
  # Lookup defaults, shared by every platform that does not override them.
  NAMES        = ['og:title', 'title'].freeze
  DESCRIPTIONS = ['og:description', 'description'].freeze
  IMAGES       = ['og:image'].freeze
  KINDS        = ['og:type'].freeze

  # The formats GdkPixbuf names for the four formats upstream allows through
  # the `image` crate: PNG, JPEG, GIF and WebP.
  IMAGE_FORMATS = %w[png jpeg gif webp].freeze

  # 5 MB. Facebook is the one platform that allows more.
  MAX_SIZE = 5_000_000

  # The three card shapes a platform can ask an image to fit.
  SMALL  = :small
  MEDIUM = :medium
  LARGE  = :large

  # Dimensions a platform wants for a given size kind: [minimum, recommended],
  # each as [width, height]. A platform with one entry uses it for every kind.
  SIZES = {
    discourse: {default: [[50, 50], [50, 50]]},
    facebook:  {
      LARGE   => [[600, 315], [600, 315]],
      default: [[200, 200], [200, 200]],
    },
    linkedin:  {default: [[20, 20], [600, 315]]},
    mastodon:  {
      LARGE   => [[300, 157], [300, 157]],
      default: [[50, 50], [100, 100]],
    },
    twitter:   {
      LARGE   => [[300, 157], [300, 157]],
      default: [[144, 144], [144, 144]],
    },
  }.freeze

  # Per-platform lookup overrides; anything absent falls back to the shared
  # defaults above.
  LOOKUPS = {
    linkedin: {description: ['og:description'].freeze},
    twitter:  {
      title:       ['twitter:title', 'og:title', 'title'].freeze,
      description: ['twitter:description', 'og:description'].freeze,
      image:       ['twitter:image', 'twitter:image:src', 'og:image'].freeze,
      kind:        ['twitter:card', 'og:type'].freeze,
    },
  }.freeze

  MAX_SIZES = {facebook: 8_000_000}.freeze

  attr_reader :key, :name

  def initialize(key, name)
    @key = key
    @name = name
  end

  DISCOURSE = new(:discourse, 'Discourse')
  FACEBOOK  = new(:facebook, 'Facebook')
  LINKEDIN  = new(:linkedin, 'LinkedIn')
  MASTODON  = new(:mastodon, 'Mastodon')
  TWITTER   = new(:twitter, 'Twitter')

  # Declaration order is the order the window's drop-down lists them, and the
  # index upstream's `Social as u32` cast produces.
  ALL = [DISCOURSE, FACEBOOK, LINKEDIN, MASTODON, TWITTER].freeze

  class << self
    def all = ALL

    def names = ALL.map(&:name)

    # Upstream's FromStr never fails: an unknown string falls back to the
    # first platform rather than raising.
    def from_s(string) = ALL.find { |social| social.name == string } || DISCOURSE

    def at(index) = ALL[index] || DISCOURSE
  end

  def to_s = @name

  def index = ALL.index(self)

  def ==(other) = other.is_a?(Social) && other.key == @key

  alias eql? ==

  def hash = @key.hash

  # The meta names and properties to try, in order, for each card field.
  def lookups
    overrides = LOOKUPS.fetch(@key, {})
    {
      title:       overrides.fetch(:title, NAMES),
      description: overrides.fetch(:description, DESCRIPTIONS),
      image:       overrides.fetch(:image, IMAGES),
      kind:        overrides.fetch(:kind, KINDS),
    }
  end

  # The limits an image has to fit to be usable at all.
  def constraints
    {
      image_size:    MAX_SIZES.fetch(@key, MAX_SIZE),
      image_formats: IMAGE_FORMATS,
    }
  end

  # The minimum and recommended dimensions for one size kind.
  def image_size(kind)
    sizes = SIZES.fetch(@key)
    minimum, recommended = sizes.fetch(kind, sizes[:default])
    {minimum: minimum, recommended: recommended}
  end
end
