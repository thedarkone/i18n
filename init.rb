silence_warnings do
  load_path, default_locale, exception_handler = I18n.load_path, I18n.default_locale, I18n.send(:class_variable_get, '@@exception_handler')
  # overwrite rails bundled i18n lib
  %w(i18n i18n/exceptions i18n/backend/simple i18n/backend/fast i18n/backend/fast/interpolation_compiler).each do |file|
    Kernel.load(File.join(File.dirname(__FILE__), "lib/#{file}.rb"))
  end
  I18n.load_path, I18n.default_locale, I18n.exception_handler = load_path, default_locale, exception_handler
end