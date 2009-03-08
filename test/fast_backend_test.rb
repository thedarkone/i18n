# encoding: utf-8
$:.unshift "lib"

require 'rubygems'
require 'test/unit'
require 'mocha'
require 'i18n'
require 'time'
require 'yaml'

class FlatteningHashTest < Test::Unit::TestCase
  def test_flattening_works
    assert_equal( {:"b.c"=>"c", :"b.f.x"=>"x", :"b.d"=>"d", :a=>"a"},
                  I18n::Backend::Fast.new.send(:flatten_hash, {:a=>'a', :b=>{:c=>'c', :d=>'d', :f=>{:x=>'x'}}}))
  end
end