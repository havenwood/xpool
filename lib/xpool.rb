class XPool
  require 'json'
  require 'ichannel'
  require 'timeout'
  require 'logger'
  require_relative "xpool/version"
  require_relative "xpool/process"

  def self.debug
    @debug
  end

  def self.debug=(boolean)
    @debug = boolean
  end

  #
  # @param [Fixnum] size
  #   The number of subprocesses to spawn.
  #
  # @return [XPool]
  #
  def initialize(size=10)
    @channel = IChannel.new Marshal
    @logger = Logger.new STDOUT
    @pool = Array.new size do 
      spawn
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
  def schedule(unit, *args)
    @channel.put unit: unit, args: args
  end

private
  def log(msg)
    if XPool.debug
      @logger.info msg
    end
  end

  def spawn
    pid = fork do
      trap :SIGUSR1 do
        log "#{::Process.pid} got request to shutdown."
        @shutdown_requested = true 
        @channel.close
      end
      loop do
        begin
          msg = @channel.get
          msg[:unit].run *msg[:args]
        ensure
          if @shutdown_requested
            log "#{::Process.pid} is about to exit."
            break
          end
        end
      end
    end
    Process.new pid 
  end
end
