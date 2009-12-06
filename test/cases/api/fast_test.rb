# encoding: utf-8

require File.expand_path(File.dirname(__FILE__) + '/../../test_helper')

class I18nFastBackendApiTest < Test::Unit::TestCase
  include Tests::Api::Basics
  include Tests::Api::Defaults
  include Tests::Api::Interpolation
  include Tests::Api::Link
  include Tests::Api::Lookup
  include Tests::Api::Pluralization
  include Tests::Api::Procs
  include Tests::Api::Localization::Date
  include Tests::Api::Localization::DateTime
  include Tests::Api::Localization::Time
  include Tests::Api::Localization::Procs

  def setup
    I18n.backend = I18n::Backend::Fast.new
    super
  end
  
  # pre-compile default strings to make sure we are testing I18n::Fast::InterpolationCompiler
  def interpolate(*args)
    options = args.last.kind_of?(Hash) ? args.last : {}
    if default_str = options[:default]
      I18n::Backend::Fast::InterpolationCompiler.compile_if_an_interpolation(default_str)
    end
    super
  end
  
  # I kinda don't think this really is a correct behavior
  undef :'test interpolation: given no values it does not alter the string'

  define_method "test: make sure we use the Fast backend" do
    assert_equal I18n::Backend::Fast, I18n.backend.class
  end
end