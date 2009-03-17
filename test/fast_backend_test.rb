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

  def assert_flattens(expected, nested)
    assert_equal expected, @backend.send(:flatten_hash, nested)
  end

  def test_hash_flattening_works
    assert_flattens(
      {:a=>'a', :b=>{:c=>'c', :d=>'d', :f=>{:x=>'x'}}, :"b.f" => {:x=>"x"}, :"b.c"=>"c", :"b.f.x"=>"x", :"b.d"=>"d"},
      {:a=>'a', :b=>{:c=>'c', :d=>'d', :f=>{:x=>'x'}}}
    )
    assert_flattens({:a=>{:b =>['a', 'b']}, :"a.b"=>['a', 'b']}, {:a=>{:b =>['a', 'b']}})
  end

  def test_pluralization_logic_and_lookup_works
    counts_hash = {:zero => 'zero', :one => 'one', :other => 'other'}
    @backend.store_translations :en, {:a => counts_hash}
    assert_equal 'one', @backend.translate(:en, :a, :count => 1)
  end
end