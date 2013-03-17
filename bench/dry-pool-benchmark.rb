require "xpool"
require "ruby-prof"
class Unit
  def run(x)
    sleep x
  end
end

pool = nil
result = RubyProf.profile do
  pool = XPool.new 5
  5.times { pool.schedule Unit.new, 0.1 }
  pool.dry?
end

pool.shutdown
printer = RubyProf::FlatPrinter.new(result)
printer.print(STDOUT)
