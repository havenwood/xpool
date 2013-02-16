require_relative 'setup'
class XPoolProcessTest < Test::Unit::TestCase
  include XPool::Support

  def setup
    @process = XPool::Process.new
  end

  def test_busy_method
    @process.schedule SmartUnit.new
    assert @process.busy?, 'Expected process to be busy'
    sleep 0.1
    refute @process.busy?, 'Expected process to not be busy'
  end

  def test_busy_method_on_dead_process
    @process.schedule SmartUnit.new
    @process.shutdown!
    refute @process.busy?
  end
end
