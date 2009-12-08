# encoding: utf-8

require 'yaml'

module I18n
  module Backend
    module Base
      include I18n::Backend::Helpers

      RESERVED_KEYS = [:scope, :default, :separator]
      INTERPOLATION_SYNTAX_PATTERN = /(\\)?\{\{([^\}]+)\}\}/

      # Accepts a list of paths to translation files. Loads translations from
      # plain Ruby (*.rb) or YAML files (*.yml). See #load_rb and #load_yml
      # for details.
      def load_translations(*filenames)
        filenames.each { |filename| load_file(filename) }
      end

      # Stores translations for the given locale in memory.
      # This uses a deep merge for the translations hash, so existing
      # translations will be overwritten by new ones only at the deepest
      # level of the hash.
      def store_translations(locale, data, options = {})
        merge_translations(locale, data)
      end

      def translate(locale, key, opts = nil)
        raise InvalidLocale.new(locale) unless locale
        return key.map { |k| translate(locale, k, opts) } if key.is_a?(Array)

        if opts
          count = opts[:count]
          scope = opts[:scope]

          if entry = lookup(locale, key, scope, opts[:separator]) || ((default = opts.delete(:default)) && default(locale, key, default, opts))
            entry = resolve(locale, key, entry, opts)
            entry = pluralize(locale, entry, count) if count
            entry = interpolate(locale, entry, opts)
            entry
          end
        else
          resolve(locale, key, lookup(locale, key), opts)
        end || raise(I18n::MissingTranslationData.new(locale, key, opts))
      end

      # Acts the same as +strftime+, but uses a localized version of the
      # format string. Takes a key from the date/time formats translations as
      # a format argument (<em>e.g.</em>, <tt>:short</tt> in <tt>:'date.formats'</tt>).
      def localize(locale, object, format = :default, options = {})
        raise ArgumentError, "Object must be a Date, DateTime or Time object. #{object.inspect} given." unless object.respond_to?(:strftime)

        if Symbol === format
          key = format
          type = object.respond_to?(:sec) ? 'time' : 'date'
          format = lookup(locale, :"#{type}.formats.#{key}")
          raise(MissingTranslationData.new(locale, key, options)) if format.nil?
        end

        format = resolve(locale, object, format, options)
        format = format.to_s.gsub(/%[aAbBp]/) do |match|
          case match
          when '%a' then I18n.t(:"date.abbr_day_names",                  :locale => locale, :format => format)[object.wday]
          when '%A' then I18n.t(:"date.day_names",                       :locale => locale, :format => format)[object.wday]
          when '%b' then I18n.t(:"date.abbr_month_names",                :locale => locale, :format => format)[object.mon]
          when '%B' then I18n.t(:"date.month_names",                     :locale => locale, :format => format)[object.mon]
          when '%p' then I18n.t(:"time.#{object.hour < 12 ? :am : :pm}", :locale => locale, :format => format) if object.respond_to? :hour
          end
        end

        object.strftime(format)
      end

      def initialized?
        @initialized ||= false
      end

      # Returns an array of locales for which translations are available
      # ignoring the reserved translation meta data key :i18n.
      def available_locales
        init_translations unless initialized?
        translations.inject([]) do |locales, (locale, data)|
          locales << locale unless (data.keys - [:i18n]).empty?
          locales
        end
      end

      def reload!
        @initialized = false
        @translations = nil
      end

      protected
        def init_translations
          load_translations(*I18n.load_path.flatten)
          @initialized = true
        end

        def translations
          @translations ||= {}
        end

        # Looks up a translation from the translations hash. Returns nil if
        # eiher key is nil, or locale, scope or key do not exist as a key in the
        # nested translations hash. Splits keys or scopes containing dots
        # into multiple keys, i.e. <tt>currency.format</tt> is regarded the same as
        # <tt>%w(currency format)</tt>.
        def lookup(locale, key, scope = [], separator = nil)
          return unless key
          init_translations unless initialized?
          keys = I18n.send(:normalize_translation_keys, locale, key, scope, separator)
          keys.inject(translations) do |result, key|
            key = key.to_sym
            if result.respond_to?(:has_key?) and result.has_key?(key)
              result[key]
            else
              return nil
            end
          end
        end

        # Evaluates defaults.
        # If given subject is an Array, it walks the array and returns the
        # first translation that can be resolved. Otherwise it tries to resolve
        # the translation directly.
        def default(locale, object, subject, options = {})
          options = options.dup.reject { |key, value| key == :default }
          case subject
          when Array
            subject.each do |subject|
              result = resolve(locale, object, subject, options) and return result
            end and nil
          else
            resolve(locale, object, subject, options)
          end
        end

        # Resolves a translation.
        # If the given subject is a Symbol, it will be translated with the
        # given options. If it is a Proc then it will be evaluated. All other
        # subjects will be returned directly.
        def resolve(locale, object, subject, options = nil)
          case subject
          when Symbol
            I18n.translate(subject, (options || {}).merge(:locale => locale, :raise => true))
          when Proc
            resolve(locale, object, subject.call(object, options), options = {})
          else
            subject
          end
        rescue MissingTranslationData
          nil
        end

        # Picks a translation from an array according to English pluralization
        # rules. It will pick the first translation if count is not equal to 1
        # and the second translation if it is equal to 1. Other backends can
        # implement more flexible or complex pluralization rules.
        def pluralize(locale, entry, count)
          return entry unless entry.is_a?(Hash) and count

          key = :zero if count == 0 && entry.has_key?(:zero)
          key ||= count == 1 ? :one : :other
          raise InvalidPluralizationData.new(entry, count) unless entry.has_key?(key)
          entry[key]
        end

        # Interpolates values into a given string.
        #
        #   interpolate "file {{file}} opened by \\{{user}}", :file => 'test.txt', :user => 'Mr. X'
        #   # => "file test.txt opened by {{user}}"
        #
        # Note that you have to double escape the <tt>\\</tt> when you want to escape
        # the <tt>{{...}}</tt> key in a string (once for the string and once for the
        # interpolation).
        def interpolate(locale, string, values = {})
          return string unless string.is_a?(String) && !values.empty?

          s = string.gsub(INTERPOLATION_SYNTAX_PATTERN) do
            escaped, key = $1, $2.to_sym
            if escaped
              "{{#{key}}}"
            elsif RESERVED_KEYS.include?(key)
              raise ReservedInterpolationKey.new(key, string)
            else
              "%{#{key}}"
            end
          end
          values.each { |key, value| values[key] = value.call(values) if interpolate_lambda?(value, s, key) }
          s % values

        rescue KeyError => e
          raise MissingInterpolationArgument.new(values, string)
        end

        # returns true when the given value responds to :call and the key is
        # an interpolation placeholder in the given string
        def interpolate_lambda?(object, string, key)
          object.respond_to?(:call) && string =~ /%\{#{key}\}|%\<#{key}>.*?\d*\.?\d*[bBdiouxXeEfgGcps]\}/
        end

        # Loads a single translations file by delegating to #load_rb or
        # #load_yml depending on the file extension and directly merges the
        # data to the existing translations. Raises I18n::UnknownFileType
        # for all other file extensions.
        def load_file(filename)
          type = File.extname(filename).tr('.', '').downcase
          raise UnknownFileType.new(type, filename) unless respond_to?(:"load_#{type}")
          data = send :"load_#{type}", filename # TODO raise a meaningful exception if this does not yield a Hash
          data.each { |locale, d| merge_translations(locale, d) }
        end

        # Loads a plain Ruby translations file. eval'ing the file must yield
        # a Hash containing translation data with locales as toplevel keys.
        def load_rb(filename)
          eval(IO.read(filename), binding, filename)
        end

        # Loads a YAML translations file. The data must have locales as
        # toplevel keys.
        def load_yml(filename)
          YAML::load(IO.read(filename))
        end

        # Deep merges the given translations hash with the existing translations
        # for the given locale
        def merge_translations(locale, data)
          locale = locale.to_sym
          translations[locale] ||= {}
          data = deep_symbolize_keys(data)

          # deep_merge by Stefan Rusterholz, see http://www.ruby-forum.com/topic/142809
          merger = proc { |key, v1, v2| Hash === v1 && Hash === v2 ? v1.merge(v2, &merger) : v2 }
          translations[locale].merge!(data, &merger)
        end
    end
  end
end
