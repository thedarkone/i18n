module I18n
  module Backend
    class Fast < Simple
      def reset_flattened_translations!
        @flattened_translations = nil
      end
      
      def flattened_translations
        @flattened_translations ||= flatten_hash(translations)
      end
      
      def merge_translations(locale, data)
        super
        reset_flattened_translations!
      end
      
      def lookup(locale, key, scope = [])
        return unless key
        init_translations unless initialized?
        keys = I18n.send(:normalize_translation_keys, locale, key, scope)
        flattened_translations[keys.map{|k| k.to_s}.join('.').to_sym]
      end
      
      def init_translations
        super
        reset_flattened_translations!
      end
      
      def localize(locale, object, format = :default)
        raise ArgumentError, "Object must be a Date, DateTime or Time object. #{object.inspect} given." unless object.respond_to?(:strftime)

        type = object.respond_to?(:sec) ? 'time' : 'date'
        # TODO only translate these if format is a String?
        # format = 
        # format = formats[format.to_sym] if formats && formats[format.to_sym]
        # TODO raise exception unless format found?
        format = (translate(locale, :"#{type}.formats.#{format}") rescue nil) || format.to_s.dup

        # TODO only translate these if the format string is actually present
        # TODO check which format strings are present, then bulk translate then, then replace them
        format.gsub!(/%a/, translate(locale, :"date.abbr_day_names")[object.wday])
        format.gsub!(/%A/, translate(locale, :"date.day_names")[object.wday])
        format.gsub!(/%b/, translate(locale, :"date.abbr_month_names")[object.mon])
        format.gsub!(/%B/, translate(locale, :"date.month_names")[object.mon])
        format.gsub!(/%p/, translate(locale, :"time.#{object.hour < 12 ? :am : :pm}")) if object.respond_to? :hour
        object.strftime(format)
      end
      
      private
        # {:a=>'a', :b=>{:c=>'c', :d=>'d', :f=>{:x=>'x'}}} => {:"b.c"=>"c", :"b.f.x"=>"x", :"b.d"=>"d", :a=>"a"}
        def flatten_hash(h, nested_stack = [], flattened_h = {})
          h.each_pair do |k, v|
            new_nested_stack = nested_stack + [k]

            if v.kind_of?(Hash)
              flatten_hash(v, new_nested_stack, flattened_h)
            else
              flattened_h[new_nested_stack.join('.').to_sym] = v
            end
          end

          flattened_h
        end
    end
  end
end