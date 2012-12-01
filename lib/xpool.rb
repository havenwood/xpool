class XPool
  require 'ichannel'
  require 'timeout'
  require 'logger'
  require_relative "xpool/version"
  require_relative "xpool/process"

  def self.debug
    if block_given?
      begin
        @debug = true
        yield
      ensure
        @debug = false
      end
    else
      @debug
    end
  end

  def self.debug=(boolean)
    @debug = boolean
  end

  def self.log(msg, type = :info) 
    @logger = @logger || Logger.new(STDOUT)
    if @debug
      @logger.public_send type, msg
    end
  end

  #
  # @param [Fixnum] size
  #   The number of subprocesses to spawn.
  #
  # @return [XPool]
  #
  def initialize(size=5)
    @channel = IChannel.new Marshal
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
      rescue Timeout::Error
        XPool.log "'#{timeout}' seconds elapsed, switching to hard shutdown."
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
  # All subprocesses in the pool are abruptly stopped through {#shutdown!} and 
  # a new pool the size of _range_ is created.
  #
  # @example
  #   pool = XPool.new 5
  #   pool.resize! 1..3 
  #   pool.shutdown
  #
  # @param [Range] range
  #   The new size of the pool.
  #
  # @return [void]
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
  def spawn
    pid = fork do
      trap :SIGUSR1 do
        XPool.log "#{::Process.pid} got request to shutdown."
        @shutdown_requested = true 
      end
      loop do
        begin
          #
          # I've noticed that select can wait an infinite amount of time for 
          # a UNIXSocket to become readable. It usually happens on the tenth or 
          # so iteration. By checking if we have data to read first we elimate 
          # this problem but it is a band aid for a bigger issue I don't 
          # understand right now.
          #
          if @channel.readable?
            msg = @channel.get
            msg[:unit].run *msg[:args]
          end
        ensure
          if @shutdown_requested && !@channel.readable?
            XPool.log "#{::Process.pid} is about to exit."
            break
          end
        end
      end
    end
    Process.new pid 
  end
end
