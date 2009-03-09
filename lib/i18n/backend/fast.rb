module I18n
  module Backend
    class Fast < Simple
      def reset_flattened_translations!
        @flattened_translations = nil
      end

      def flattened_translations
        @flattened_translations ||= flatten_translations(translations)
      end

      def merge_translations(locale, data)
        super
        reset_flattened_translations!
      end

      def init_translations
        super
        reset_flattened_translations!
      end

      protected
        # {:a=>'a', :b=>{:c=>'c', :d=>'d', :f=>{:x=>'x'}}} => {:"b.c"=>"c", :"b.f.x"=>"x", :"b.d"=>"d", :a=>"a"}
        def flatten_hash(h, nested_stack = [], flattened_h = {})
          h.each_pair do |k, v|
            new_nested_stack = nested_stack + [k]

            if v.kind_of?(Hash)
              flatten_hash(v, new_nested_stack, flattened_h)
            else
              flattened_h[new_nested_stack.join('.').to_sym] = compile_if_an_interpolation(v)
            end
          end

          flattened_h
        end

        def flatten_translations(translations)
          # don't flatten locale roots
          translations.inject({}) do |flattened_h, (locale_name, locale_translations)|
            flattened_h[locale_name] = flatten_hash(locale_translations)
            flattened_h
          end
        end

        def interpolate(string, values)
          string.respond_to?(:i18n_interpolate) ? string.i18n_interpolate(values) : string
        end

        def lookup(locale, key, scope = nil)
          init_translations unless @initialized
          flattened_translations[locale.to_sym][(scope ? "#{Array(scope).join('.')}.#{key}" : key).to_sym] rescue nil
        end

        def compile_if_an_interpolation(string)
          if interpolated_str?(string)
            string.instance_eval <<-RUBY_EVAL, __FILE__, __LINE__
              def i18n_interpolate(values = {})
                "#{compiled_interpolation_body(string)}"
              end
            RUBY_EVAL
          end

          string
        end

        def interpolated_str?(str)
          str.kind_of?(String) && str.scan(MATCH).find{|escape_chars, interpolation| !escape_chars && interpolation}
        end

        def compiled_interpolation_body(str)
          str.gsub(MATCH) do
            escaped, pattern, key = $1, $2, $3.to_sym

            if escaped
              pattern
            else
              eskey = escape_key_sym(key)
              if INTERPOLATION_RESERVED_KEYS.include?(key)
                "\#{raise(ReservedInterpolationKey.new(#{eskey}, self))}"
              else
                "\#{values[#{eskey}] || (values.has_key?(#{eskey}) && values[#{eskey}].to_s) || raise(MissingInterpolationArgument.new(#{eskey}, self))}"
              end
            end

          end
        end

        def escape_key_sym(key)
          # rely on Ruby to do all the hard work :)
          key.to_sym.inspect
        end
    end
  end
end