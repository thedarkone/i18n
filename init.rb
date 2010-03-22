require File.dirname(__FILE__) + '/lib/i18n/backend/lazy_reloading' # only require the LazyReloading module
$:.delete(File.expand_path(File.dirname(__FILE__) + '/lib')) # get rid of myself from the load path
