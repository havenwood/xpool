require_relative 'setup'
class XPoolTest < Test::Unit::TestCase
  class Unit
    def run
      sleep 1
    end
  end

  class XUnit
    def initialize
      file = Tempfile.new '__xpool_test'
      @path = file.path
      file.close false
    end

    def run
      File.open @path, 'w' do |f|
        f.write 'true'
      end
    end

    def run?
      return @run if defined?(@run)
      @run = File.read(@path) == 'true'
      FileUtils.rm_rf @path
      @run
    end
  end

  def setup
    @pool = XPool.new 5
  end

  def teardown
    @pool.shutdown
  end
  

  def test_queue 
    @pool.resize! 1..1
    units = Array.new(5) { XUnit.new }
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
