# encoding: utf-8
$:.unshift "lib"

require 'rubygems'
require 'test/unit'
require 'mocha'
require 'i18n'
require 'time'
require 'yaml'

class FastBackendTest < Test::Unit::TestCase
  def setup
    @backend = I18n::Backend::Fast.new
  end

  def assert_escapes(expected, malicious_str)
    assert_equal(expected, @backend.send(:escape_key_sym, malicious_str))
  end

  def assert_flattens(expected, nested)
    assert_equal expected, @backend.send(:flatten_hash, nested)
  end

  def test_hash_flattening_works
    assert_flattens( {:"b.c"=>"c", :"b.f.x"=>"x", :"b.d"=>"d", :a=>"a"}, {:a=>'a', :b=>{:c=>'c', :d=>'d', :f=>{:x=>'x'}}} )
    assert_flattens( {:"a.b"=>['a', 'b']}, {:a=>{:b =>['a', 'b']}} )
  end

  def test_escape_key_properly_escapes
    assert_escapes ':"\""',       '"'
    assert_escapes ':"\\\\"',     '\\'
    assert_escapes ':"\\\\\""',   '\\"'
    assert_escapes ':"\#{}"',     '#{}'
    assert_escapes ':"\\\\\#{}"', '\#{}'
  end

  def test_uses_simple_backends_pluralization_logic_and_lookup
    counts_hash = {:zero => 'zero', :one => 'one', :other => 'other'}
    @backend.store_translations :en, {:a => counts_hash}
    @backend.expects(:lookup).never
    @backend.expects(:lookup_with_count).returns(counts_hash)
    assert_equal 'one', @backend.translate(:en, :a, :count => 1)
  end

  def test_non_interpolated_strings_or_arrays_dont_get_compiled
    ['abc', '\\\\{{a}}', []].each do |obj|
      @backend.send(:compile_if_an_interpolation, obj)
      assert_equal false, obj.respond_to?(:i18n_interpolate)
    end
  end

  def test_interpolated_string_gets_compiled
    str = '-{{a}}-'
    @backend.send(:compile_if_an_interpolation, str)
    assert_equal '-A-', str.i18n_interpolate(:a => 'A')
  end
end