require_relative 'setup'
class XPoolTest < Test::Unit::TestCase
  def setup
    @pool = XPool.new 5
  end

  def teardown
    @pool.shutdown!
  end

  def test_broadcast
    subprocesses = @pool.broadcast Sleeper.new(1)
    subprocesses.each { |subprocess| assert_equal 1, subprocess.frequency }
  end

  def test_size_with_graceful_shutdown
    assert_equal 5, @pool.size
    @pool.shutdown
    assert_equal 0, @pool.size
  end

  def test_size_with_forceful_shutdown
    assert_equal 5, @pool.size
    @pool.shutdown!
    assert_equal 0, @pool.size
  end

  def test_queue
    @pool.resize! 1..1
    subprocesses = Array.new(5) { @pool.schedule Sleeper.new(0.1) }.uniq!
    assert_equal 1, subprocesses.size
    assert_equal 5, subprocesses[0].frequency
  end

  def test_distribution_of_work
    subprocesses = (0..4).map { @pool.schedule Sleeper.new(0.1) }
    subprocesses.each { |subprocess| assert_equal 1, subprocess.frequency }
  end

  def test_resize!
    @pool.resize! 1..1
    assert_equal 1, @pool.instance_variable_get(:@pool).size
  end

  def test_dry?
    refute @pool.dry?
    5.times { @pool.schedule Sleeper.new(0.5) }
    sleep 0.1
    assert @pool.dry?
  end

  def test_failed_processes
    @pool.schedule Raiser.new
    sleep 0.1
    assert_equal 1, @pool.failed_processes.size
    assert_equal 4, @pool.size
  end
end
