class XPool
  require 'ichannel'
  require 'timeout'
  require 'logger'
  require 'rbconfig'
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
  def initialize(size=number_of_cpu_cores)
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
          @pool.each(&:shutdown)
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

  #
  # @return [Fixnum]
  #   Returns the number of alive subprocesses in the pool.
  #
  def size
    @pool.count do |process|
      process.alive?
    end
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

  #
  # Count the number of CPU cores available.
  #
  def number_of_cpu_cores
    case RbConfig::CONFIG['host_os']
    when /linux/
      Dir.glob('/sys/devices/system/cpu/cpu[0-9]*').count
    when /darwin|bsd/
      Integer(`sysctl -n hw.ncpu`)
    when /solaris/
      Integer(`kstat -m cpu_info | grep -w core_id | uniq | wc -l`)
    else
      5
    end
  end
end
