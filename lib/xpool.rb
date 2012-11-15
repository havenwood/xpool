class XPool
  require 'json'
  require 'ichannel'
  require 'thread'
  require 'timeout'
  require_relative "xpool/version"
  require_relative "xpool/process"
  #
  # @param [Fixnum] size
  #   The number of subprocesses to spawn.
  #
  # @return [XPool]
  #
  def initialize(size=10)
    @queue = Queue.new
    @pool = Array.new(size) do 
      process = Process.new
      process.spawn
      process
    end
    queue_loop
  end

  #
  # @return [Boolean]
  #   Returns false when the pool has active subprocesses.
  #
  def shutdown?
    @pool.none? do |process|
      process.active?
    end
  end

  #
  # A graceful shutdown of the pool.
  #
  # All busy subprocesses finish up any code they're running & exit normally 
  # afterwards.
  #
  # @param [Fixnum] timeout 
  #   An optional amount of seconds to wait before forcing a shutdown through
  #   {#shutdown!}.
  #
  # @see XPool::Process#spawn
  # 
  # @return [void]
  #
  def shutdown(timeout=nil)
    if timeout
      begin
        Timeout.timeout(timeout) do
          @pool.each do |process|
            process.shutdown
          end
        end
      rescue Timeout::Error => e
        shutdown!
      end
    else
      @pool.each(&:shutdown) 
    end
  end

  #
  # A forceful shutdown of the pool (through SIGKILL).
  #
  # @return [void]
  #
  def shutdown!
    @pool.each(&:shutdown!)
  end

  #
  # Resize the pool. 
  # All subprocesses in the pool are gracefully shutdown through {#shutdown} and
  # a new pool the size of _range_ is created. 
  #
  # @example
  #   pool = XPool.new 10
  #   pool.resize 1..5 
  #   pool.shutdown
  #
  # @param [Range] range
  #   The new size of the pool.
  #
  # @return [void]
  #
  def resize(range)
    shutdown
    @pool = range.to_a.map do 
      spawn
    end
  end

  #
  # Resize the pool.
  # All subprocesses in the pool are abruptly stopped through {#shutdown!} and 
  # a new pool the size of _range_ is created.
  #
  # @param 
  #   (see #resize)
  #
  # @return
  #   (see #resize)
  #
  # @see XPool#resize
  #
  def resize!(range)
    shutdown!
    @pool = range.to_a.map do
      spawn
    end
  end

  #
  # Dispatch a unit of work in a subprocess.
  #
  # @param 
  #   (see Process#schedule)
  #
  # @return 
  #   (see Process#schedule)
  #
  def schedule(unit)
    process = random_subprocess
    if process
      process.schedule unit
    else
      @queue.enq unit
    end
  end

private
  def spawn
    Process.new.tap do |process|
      process.spawn
    end
  end

  def random_subprocess
    available.sample
  end

  def available
    @pool.reject do |process|
      process.busy?
    end
  end

  def queue_loop
    Thread.new do
      loop do
        Thread.current[:unit] ||= @queue.deq
        process = random_subprocess 
        if process
          Thread.current[:unit] = nil
          process.schedule unit
        end
      end
    end
  end
end
