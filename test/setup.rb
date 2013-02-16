require 'bundler/setup'
require 'xpool'
require 'test/unit'
require 'fileutils'
require_relative 'support/sleep_unit'
require_relative 'support/smart_unit'
XPool.debug = ENV.has_key? "DEBUG"
