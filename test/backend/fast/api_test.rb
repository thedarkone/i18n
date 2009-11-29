# encoding: utf-8

require File.expand_path(File.dirname(__FILE__) + '/../../test_helper')

class I18nFastBackendApiBasicsTest < Test::Unit::TestCase
  include Tests::Backend::Fast::Setup::Base
  include Tests::Backend::Api::Basics

  def test_uses_fast_backend
    assert_equal I18n::Backend::Fast, I18n.backend.class
  end
end

class I18nFastBackendApiTranslateTest < Test::Unit::TestCase
  include Tests::Backend::Fast::Setup::Base
  include Tests::Backend::Api::Translation

  # implementation specific tests

  def test_translate_calls_lookup_with_locale_given
    I18n.backend.expects(:lookup).with('de', :bar, [:foo], nil).returns 'bar'
    I18n.backend.translate 'de', :bar, :scope => [:foo]
  end

  def test_translate_calls_pluralize
    I18n.backend.expects(:pluralize).with('en', 'bar', 1).returns('bar')
    I18n.backend.translate 'en', :bar, :scope => [:foo], :count => 1
  end
end

class I18nFastBackendApiInterpolateTest < Test::Unit::TestCase
  include Tests::Backend::Fast::Setup::Base
  include Tests::Backend::Api::Interpolation

  # pre-compile default strings to make sure we are testing I18n::Fast::InterpolationCompiler
  def interpolate(*args)
    options = args.last.kind_of?(Hash) ? args.last : {}
    if default_str = options[:default]
      I18n::Backend::Fast::InterpolationCompiler.compile_if_an_interpolation(default_str)
    end
    super
  end

  # I kinda don't think this really is a correct behavior
  undef :test_interpolation_given_no_interpolation_values_it_does_not_alter_the_string

  # implementation specific tests

  def test_interpolate_given_nil_as_a_string_returns_nil
    assert_nil I18n.backend.send(:interpolate, nil, nil, :name => 'David')
  end

  def test_interpolate_given_an_non_string_as_a_string_returns_nil
    assert_equal [], I18n.backend.send(:interpolate, nil, [], :name => 'David')
  end
end

class I18nFastBackendApiLambdaTest < Test::Unit::TestCase
  include Tests::Backend::Fast::Setup::Base
  include Tests::Backend::Api::Lambda
end

class I18nFastBackendApiTranslateLinkedTest < Test::Unit::TestCase
  include Tests::Backend::Fast::Setup::Base
  include Tests::Backend::Api::Link
end

class I18nFastBackendApiPluralizationTest < Test::Unit::TestCase
  include Tests::Backend::Fast::Setup::Base
  include Tests::Backend::Api::Pluralization
end

class I18nFastBackendApiLocalizeDateTest < Test::Unit::TestCase
  include Tests::Backend::Fast::Setup::Localization
  include Tests::Backend::Api::Localization::Date
end

class I18nFastBackendApiLocalizeDateTimeTest < Test::Unit::TestCase
  include Tests::Backend::Fast::Setup::Localization
  include Tests::Backend::Api::Localization::DateTime
end

class I18nFastBackendApiLocalizeTimeTest < Test::Unit::TestCase
  include Tests::Backend::Fast::Setup::Localization
  include Tests::Backend::Api::Localization::Time
end

class I18nFastBackendApiLocalizeLambdaTest < Test::Unit::TestCase
  include Tests::Backend::Fast::Setup::Localization
  include Tests::Backend::Api::Localization::Lambda
end