# frozen_string_literal: true

require 'fiddle'

# I18n reads upstream's message catalogues through the same C gettext that GTK
# itself uses.
#
# Ported from upstream's src/i18n.rs, and from the four i18n calls at the top of
# src/main.rs that set the locale and bind the domain. There is no gettext in
# the Ruby standard library and none in the ruby-gnome bindings, but every
# string GTK renders already goes through the libc implementation — so this
# binds to that rather than adding a gem and a second, differently-behaving
# catalogue reader. The LANGUAGE search list and the encoding conversion come
# along for free.
#
# `translate_f` is upstream's `gettext_f`: a gettext whose `{name}`
# placeholders are filled from a dictionary, so the msgid that reaches the
# catalogue is the one the translators were given rather than a Ruby `format`
# string.
module I18n
  # Upstream's GETTEXT_PACKAGE, which is meson.project_name() (meson.build:40),
  # so the catalogues install as <lang>/LC_MESSAGES/share-preview.mo.
  DOMAIN = 'share-preview'

  # glibc keeps gettext in libc; elsewhere it lives in a separate libintl.
  LIBRARIES = ['libc.so.6', 'libintl.so.8', 'libintl.so', 'libc.so'].freeze

  # The locale category to set from the environment. glibc and musl both
  # number LC_ALL 6; the constant is not exposed through any Ruby binding, and
  # reading it from the C headers would need a compiler at runtime.
  LC_ALL = 6

  # gettext stores a contextual message under "context\u0004message".
  CONTEXT_SEPARATOR = "\u0004"

  # Compiled catalogues live beside the source when running from a checkout
  # (`rake translations` writes them there) and in the system locale directory
  # once installed. Upstream's equivalent is config::LOCALEDIR.
  DIRECTORIES = [
    File.expand_path('../locale', __dir__),
    '/usr/share/locale',
  ].freeze

  module_function

  def library
    @library ||= LIBRARIES.filter_map { |name| open_library(name) }.first
  end

  def open_library(name)
    Fiddle.dlopen(name)
  rescue Fiddle::DLError
    nil
  end

  def function(name, argument_types)
    @functions ||= {}
    @functions[name] ||= Fiddle::Function.new(
      library[name],
      argument_types,
      Fiddle::TYPE_VOIDP,
    )
  end

  # Point the domain at a directory of <lang>/LC_MESSAGES/share-preview.mo and
  # set the process locale from the environment — gettext refuses to translate
  # anything while the locale is still the "C" default.
  def bind(directory = DIRECTORIES.find { |dir| File.directory?(dir) })
    directory.then do |dir|
      if dir
        setlocale
        function('bindtextdomain', [Fiddle::TYPE_VOIDP, Fiddle::TYPE_VOIDP]).call(DOMAIN, dir)
        function('bind_textdomain_codeset', [Fiddle::TYPE_VOIDP, Fiddle::TYPE_VOIDP])
          .call(DOMAIN, 'UTF-8')
        function('textdomain', [Fiddle::TYPE_VOIDP]).call(DOMAIN)
      end
    end
  end

  def setlocale
    function('setlocale', [Fiddle::TYPE_INT, Fiddle::TYPE_VOIDP]).call(LC_ALL, '')
  end

  def translate(message)
    function('dgettext', [Fiddle::TYPE_VOIDP, Fiddle::TYPE_VOIDP])
      .call(DOMAIN, message)
      .to_s
      .force_encoding(Encoding::UTF_8)
  end

  # A message the catalogue stores under a context. gettext hands back the
  # "context\u0004message" key itself when nothing is translated, which is not
  # a string anybody should see, so the untranslated message is returned
  # instead.
  def with_context(context, message)
    translate("#{context}#{CONTEXT_SEPARATOR}#{message}").then do |translated|
      if translated.include?(CONTEXT_SEPARATOR)
        message
      else
        translated
      end
    end
  end

  # Upstream's `freplace`: replace every `{name}` in the string with the value
  # the dictionary gives for `name`.
  def freplace(string, arguments)
    arguments.inject(string) { |text, (name, value)| text.gsub("{#{name}}", value.to_s) }
  end

  # Upstream's `gettext_f`: translate, then fill the placeholders.
  def translate_f(message, arguments) = freplace(translate(message), arguments)
end

# Short names, so the call sites read like the ones being ported.
def _(message) = I18n.translate(message)
def c_(context, message) = I18n.with_context(context, message)
def f_(message, **arguments) = I18n.translate_f(message, arguments)

# The catalogues are bound as the module loads, so that a translatable string
# assigned to a constant at load time is already translated.
I18n.bind
