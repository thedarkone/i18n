module I18n
  module Backend
    class Fast < Simple
      module PluralizationCompiler
        extend self

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
          str.kind_of?(String) && str.scan(Simple::MATCH).find{|escape_chars, interpolation| !escape_chars && interpolation}
        end

        protected
        def compiled_interpolation_body(str)
          str.gsub(Simple::MATCH) do
            escaped, pattern, key = $1, $2, $3.to_sym

            if escaped
              pattern
            else
              eskey = escape_key_sym(key)
              if Simple::INTERPOLATION_RESERVED_KEYS.include?(key)
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
end