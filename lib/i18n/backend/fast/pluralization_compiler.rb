module I18n
  module Backend
    class Fast < Base
      module PluralizationCompiler
        extend self
        
        TOKENIZER                    = /(\\\{\{[^\}]+\}\}|\{\{[^\}]+\}\})/
        INTERPOLATION_SYNTAX_PATTERN = /(\\)?(\{\{([^\}]+)\}\})/

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
          str.kind_of?(String) && str =~ INTERPOLATION_SYNTAX_PATTERN
        end

        protected
        # tokenize("foo {{bar}} baz \\\\{{buz}}") # => ["foo ", "{{bar}}", " baz ", "\\\\{{buz}}"]
        def tokenize(str)
          str.split(TOKENIZER)
        end

        def compiled_interpolation_body(str)
          tokenize(str).map do |token|
            (matchdata = token.match(INTERPOLATION_SYNTAX_PATTERN)) ? handle_interpolation_token(token, matchdata) : escape_plain_str(token)
          end.join
        end

        def handle_interpolation_token(interpolation, matchdata)
          escaped, pattern, key = matchdata.values_at(1, 2, 3)
          escaped ? pattern : compile_interpolation_token(key.to_sym)
        end

        def compile_interpolation_token(key)
          eskey = escape_key_sym(key)
          if Base::RESERVED_KEYS.include?(key)
            "\#{raise(ReservedInterpolationKey.new(#{eskey}, self))}"
          else
            "\#{values[#{eskey}] || (values.has_key?(#{eskey}) && values[#{eskey}].to_s) || raise(MissingInterpolationArgument.new(#{eskey}, self))}"
          end
        end

        def escape_plain_str(str)
          str.gsub(/"|\\|#/) {|x| "\\#{x}"}
        end

        def escape_key_sym(key)
          # rely on Ruby to do all the hard work :)
          key.to_sym.inspect
        end

      end
    end
  end
end