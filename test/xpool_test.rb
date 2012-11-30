require_relative 'setup'
class XPoolTest < Test::Unit::TestCase
  class Unit
    def run
      sleep 1
    end
  end

  def setup
    @pool = XPool.new 5
  end

  def teardown
    @pool.shutdown
  end
  
  def test_parallelism 
    5.times do 
      @pool.schedule Unit.new
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
