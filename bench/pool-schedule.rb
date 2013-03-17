require "xpool"
require "ruby-prof"
class Unit
  def run(x = 1)
    sleep x
  end
end

pool = XPool.new 5
result = RubyProf.profile do
  5.times { pool.schedule Unit.new }
end
pool.shutdown
printer = RubyProf::FlatPrinter.new(result)
printer.print
