require 'bundler/setup'
require 'xpool'
require 'test/unit'
require 'fileutils'
require_relative 'support/sleeper'
require_relative 'support/io_writer'
XPool.debug = ENV.has_key? "DEBUG"
