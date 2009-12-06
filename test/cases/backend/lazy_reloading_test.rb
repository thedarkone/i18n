# encoding: utf-8

require File.expand_path(File.dirname(__FILE__) + '/../../test_helper')

class I18nBackendLazyReloadingTest < Test::Unit::TestCase
  class Backend
    include I18n::Backend::Base
    include I18n::Backend::LazyReloading
  end
  
  def setup
    I18n.backend = Backend.new
    I18n.load_path = [locale_fixture_path('en.yml')]
    I18n.backend.send(:init_translations)
  end

  def locale_fixture_path(file)
    File.join(locales_dir, file)
  end

  def trigger_reload
    I18n.backend.reload!
    I18n.backend.available_locales
  end

  def assert_triggers_translations_reload
    yield
    I18n.backend.expects(:init_translations)
    trigger_reload
  end

  def assert_does_not_trigger_translations_reload
    yield
    I18n.backend.expects(:init_translations).never
    trigger_reload
  end

  def test_does_not_perform_reload_if_translation_files_are_not_updated
    assert_does_not_trigger_translations_reload do
      I18n.backend.reload!
    end
  end

  def test_performs_reload_if_new_translation_is_added
    assert_triggers_translations_reload do
      I18n.load_path << locale_fixture_path('en.rb')
    end
  end

  def test_performs_reload_if_translation_is_removed
    assert_triggers_translations_reload do
      I18n.load_path.clear
    end
  end

  def test_performs_reload_if_translation_file_is_updated
    assert_triggers_translations_reload do
      File.expects(:mtime).with(I18n.load_path.first).returns(Time.now - 10)
    end
  end
end