module I18n
  module Backend
    class Fast < Simple

      # append any your custom pluralization keys to the constant
      PLURALIZATION_KEYS = [:zero, :one, :other]

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
              # short circuit pluralization hashes
              flattened_h[nested_stack_to_flat_key(new_nested_stack)] = v if (v.keys & PLURALIZATION_KEYS).any?

              flatten_hash(v, new_nested_stack, flattened_h)
            else
              flattened_h[nested_stack_to_flat_key(new_nested_stack)] = PluralizationCompiler.compile_if_an_interpolation(v)
            end
          end

          flattened_h
        end

        def nested_stack_to_flat_key(nested_stack)
          nested_stack.join('.').to_sym
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
          # We have to try calling super if no translation is found because Rails helpers rely on being able to access arbitrary translation subtrees.
          # This is *slow* and goes against pretty much all the Fast backend is meant to stand for :(.
          (flattened_translations[locale.to_sym][(scope ? "#{Array(scope).join('.')}.#{key}" : key).to_sym] rescue nil) || super
        end
    end
  end
end