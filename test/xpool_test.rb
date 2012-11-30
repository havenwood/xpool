require_relative 'setup'
class XPoolTest < Test::Unit::TestCase
  class Unit
    def run
      sleep 1
    end
  end

  def setup
    @pool = XPool.new 10
  end

  def teardown
    @pool.shutdown
  end
  
  def test_parallelism 
    10.times do 
      @pool.schedule Unit.new
    end
    assert_nothing_raised Timeout::Error do
      Timeout.timeout 3 do 
        @pool.shutdown
      end
    end
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
