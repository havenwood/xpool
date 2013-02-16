require_relative 'setup'
class XPoolTest < Test::Unit::TestCase
  include XPool::Support

  def setup
    @pool = XPool.new 5
  end

  def teardown
    @pool.shutdown
  end

  def test_broadcast
    @pool.broadcast SleepUnit.new
    @pool.instance_variable_get(:@pool).each do |process|
      assert process.busy?
    end
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
    units = Array.new(5) { SmartUnit.new }
    units.each do |unit|
      @pool.schedule unit
    end
    @pool.shutdown
    units.each do |unit|
      assert unit.run?
    end
  end

  def test_parallelism
    5.times do
      @pool.schedule SleepUnit.new
    end
    assert_nothing_raised Timeout::Error do
      Timeout.timeout 2 do
        @pool.shutdown
      end
    end
  end

  def test_resize!
    @pool.resize! 1..1
    assert_equal 1, @pool.instance_variable_get(:@pool).size
  end
end
