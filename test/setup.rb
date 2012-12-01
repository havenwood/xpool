require 'bundler/setup'
require 'xpool'
require 'test/unit'
require 'fileutils'
XPool.debug = ENV.has_key? "DEBUG"
