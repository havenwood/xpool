require_relative 'setup'
class XPoolTest < Test::Unit::TestCase
  def setup
    klass = self.class # XPoolTest
    klass.const_set :Unit, Class.new {
      def call
        sleep 1
      end
    }
    @pool = XPool.new 10
    @members = @pool.instance_variable_get(:@pool)
  end

  def teardown
    @pool.shutdown!
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
