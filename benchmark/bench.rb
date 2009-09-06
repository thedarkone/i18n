$:.unshift "../lib"
 
require 'i18n'
require 'benchmark'
 
def with_fast?; defined?(I18n::Backend::Fast); end
 
f = I18n::Backend::Fast.new if with_fast?
s = I18n::Backend::Simple.new

interpolation = 'abc {{a}}, {{b}}'
[f, s].compact.each {|b| b.store_translations 'en', :foo => {:bar => {:bax => {:buz => 'buz'}, :tr => interpolation}, :baz => 'baz'}}

TESTS = 200_000
Benchmark.bmbm do |results|
  results.report("s.t(:'foo.bar.bax.buz')") do
    TESTS.times { s.translate(:en, :'foo.bar.bax.buz') }
  end
  
  results.report("f.t(:'foo.bar.bax.buz')") do
    TESTS.times { f.translate(:en, :'foo.bar.bax.buz') }
  end if with_fast?
  
  results.report("s.t(:'foo.bar.tr', :a => 'A', :b => 'B')") do
    TESTS.times { s.translate(:en, :'foo.bar.tr', :a => 'A', :b => 'B') }
  end
  
  results.report("f.t(:'foo.bar.tr', :a => 'A', :b => 'B')") do
    TESTS.times { f.translate(:en, :'foo.bar.tr', :a => 'A', :b => 'B') }
  end if with_fast?
end