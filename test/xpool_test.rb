require_relative 'setup'
class XPoolTest < Test::Unit::TestCase
  class Unit
    def call
      sleep 1
    end
  end

  def setup
    @pool = XPool.new 10
    @members = @pool.instance_variable_get(:@pool)
  end

  def teardown
    unless @pool.shutdown?
      @pool.shutdown!
    end
  end

  def test_parallelism 
    10.times do 
      @pool.schedule Unit.new
    end
    Timeout.timeout 3 do
      @pool.shutdown
    end
  end

  def test_busy
    @members.each do |process|
      assert_equal false, process.busy?
    end
  end

  def test_busy_with_work
    5.times { @pool.schedule Unit.new }
    members = @members.reject(&:busy)
    assert_equal 5, members.size
  end
    
  def test_resize
    @pool.resize 1..5
    assert_equal 5, @pool.instance_variable_get(:@pool).size
  end

  def test_resize! 
    @pool.resize! 1..5
    assert_equal 5, @pool.instance_variable_get(:@pool).size
  end
end
