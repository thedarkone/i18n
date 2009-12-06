module I18n
  module Backend
    autoload :ActiveRecord,  'i18n/backend/active_record'
    autoload :Base,          'i18n/backend/base'
    autoload :Cache,         'i18n/backend/cache'
    autoload :Chain,         'i18n/backend/chain'
    autoload :Fallbacks,     'i18n/backend/fallbacks'
    autoload :Fast,          'i18n/backend/fast'
    autoload :Gettext,       'i18n/backend/gettext'
    autoload :Helpers,       'i18n/backend/helpers'
    autoload :LazyReloading, 'i18n/backend/lazy_reloading.rb'
    autoload :Metadata,      'i18n/backend/metadata'
    autoload :Pluralization, 'i18n/backend/pluralization'
    autoload :Simple,        'i18n/backend/simple'
  end
end
