# encoding: utf-8
$:.unshift "lib"

require 'rubygems'
require 'test/unit'
require 'i18n'

PluralizationCompiler = I18n::Backend::Fast::PluralizationCompiler

class PluralizationCompilerTest < Test::Unit::TestCase
  def assert_escapes(expected, malicious_str)
    assert_equal(expected, PluralizationCompiler.send(:escape_key_sym, malicious_str))
  end

  def test_escape_key_properly_escapes
    assert_escapes ':"\""',       '"'
    assert_escapes ':"\\\\"',     '\\'
    assert_escapes ':"\\\\\""',   '\\"'
    assert_escapes ':"\#{}"',     '#{}'
    assert_escapes ':"\\\\\#{}"', '\#{}'
  end

  def test_non_interpolated_strings_or_arrays_dont_get_compiled
    ['abc', '\\\\{{a}}', []].each do |obj|
      PluralizationCompiler.compile_if_an_interpolation(obj)
      assert_equal false, obj.respond_to?(:i18n_interpolate)
    end
  end

  def test_interpolated_string_gets_compiled
    str = '-{{a}}-'
    PluralizationCompiler.compile_if_an_interpolation(str)
    assert_equal '-A-', str.i18n_interpolate(:a => 'A')
  end
end