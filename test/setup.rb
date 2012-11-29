require 'bundler/setup'
require 'xpool'
require 'test/unit'
XPool.debug = ENV.has_key? "DEBUG"
