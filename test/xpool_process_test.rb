require_relative 'setup'
class XPoolProcessTest < Test::Unit::TestCase
  def setup
    @process = XPool::Process.new
  end

  def teardown
    @process.shutdown
  end

  def test_busy_method
    @process.schedule Sleeper.new(0.5)
    sleep 0.1
    assert @process.busy?, 'Expected process to be busy'
    sleep 0.4
    refute @process.busy?, 'Expected process to not be busy'
  end

  def test_busy_method_on_dead_process
    @process.schedule Sleeper.new(1)
    @process.shutdown!
    refute @process.busy?
  end
end
