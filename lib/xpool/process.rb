class XPool::Process
  #
  # @param [Fixnum] id
  #   The Process ID.
  #
  def initialize
    @channel= IChannel.new Marshal
    @busy_channel = IChannel.new Marshal
    @id = spawn
    @busy = false
    @frequency = 0
  end

  #
  # A graceful shutdown of the process.
  #
  # The signal 'SIGUSR1' is caught in the subprocess and exit is
  # performed through Kernel#exit after the process has finished
  # executing its work.
  #
  # @return [void]
  #
  def shutdown
    _shutdown 'SIGUSR1' unless dead?
  end

  #
  # A non-graceful shutdown through SIGKILL.
  #
  # @return [void]
  #
  def shutdown!
    _shutdown 'SIGKILL' unless dead?
  end

  #
  # @return [Fixnum]
  #   The number of times the process has been asked to schedule work.
  #
  def frequency
    @frequency
  end

  #
  # @param [#run] unit
  #   The unit of work
  #
  # @param [Object] *args
  #   A variable number of arguments to be passed to #run
  #
  # @return [void]
  #
  def schedule(unit,*args)
    @frequency += 1
    @channel.put unit: unit, args: args
  end

  #
  # @return [Boolean]
  #   Returns true when the process is executing work.
  #
  def busy?
    if dead?
      false
    elsif @busy_channel.readable?
      begin
        @busy = @busy_channel.get
      end while @busy_channel.readable?
      @busy
    else
      @busy
    end
  end

  #
  # @return [Boolean]
  #   Returns true when the process is alive.
  #
  def alive?
    !dead?
  end

  #
  # @return [Boolean]
  #   Returns true when the process is no longer running.
  #
  def dead?
    @dead
  end

private
  def _shutdown(sig)
    Process.kill sig, @id
    Process.wait @id
    @dead = true
  end

  def spawn
    fork do
      trap :SIGUSR1 do
        XPool.log "#{::Process.pid} got request to shutdown."
        @shutdown_requested = true
      end
      loop do
        begin
          if @channel.readable?
            @busy_channel.put true
            msg = @channel.get
            msg[:unit].run *msg[:args]
          end
        ensure
          @busy_channel.put false
          if @shutdown_requested && !@channel.readable?
            XPool.log "#{::Process.pid} is about to exit."
            break
          end
        end
      end
    end
  end
end
