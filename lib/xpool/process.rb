class XPool::Process
  #
  # @return [XPool::Process]
  #   Returns an instance of XPool::Process
  #
  def initialize serializer=Marshal
    @serializer = serializer
    @id = spawn
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
    _shutdown 'SIGUSR1' unless @shutdown
  end

  #
  # A non-graceful shutdown through SIGKILL.
  #
  # @return [void]
  #
  def shutdown!
    _shutdown 'SIGKILL' unless @shutdown
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
  # @raise [RuntimeError]
  #   When the process is dead.
  #
  # @return [XPool::Process]
  #   Returns self
  #
  def schedule(unit,*args)
    if dead?
      raise RuntimeError,
        "cannot schedule work on a dead process (with ID: #{@id})"
    end
    @frequency += 1
    @channel.put unit: unit, args: args
    self
  end

  #
  # @return [Boolean]
  #   Returns true when the process is executing a unit of work.
  #
  def busy?
    synchronize!
    @states[:busy]
  end

  #
  # @return [Boolean]
  #   Returns true when the process is not executing a unit of work.
  #
  def idle?
    !busy?
  end

  #
  # @return [Boolean]
  #   Returns true when the process has failed due to an unhandled exception.
  #
  def failed?
    synchronize!
    @states[:failed]
  end

  #
  # @return [Boolean]
  #   Returns true when the process is still running.
  #
  def alive?
    !dead?
  end

  #
  # @return [Boolean]
  #   Returns true when the process has shutdown.
  #
  def dead?
    synchronize!
    @states[:dead]
  end

  #
  # If a process has failed (see {#failed?}) this method returns the backtrace of
  # the exception that caused the process to fail.
  #
  # @return [Array<String>]
  #   Returns the backtrace.
  #
  def backtrace
    synchronize!
    @states[:backtrace]
  end

  #
  # @return [Fixnum]
  #   Returns the process ID of the new process.
  #
  def restart
    shutdown
    @id = spawn
  end

private
  def _shutdown(sig)
    Process.kill sig, @id
    Process.wait @id
  rescue Errno::ECHILD, Errno::ESRCH
  ensure
    @states = {dead: true} unless failed?
    @shutdown = true
    @channel.close
    @s_channel.close
  end

  def synchronize!
    return if @shutdown
    while @s_channel.readable?
      @states = @s_channel.get
    end
    @states
  end

  def reset
    @channel = IChannel.new @serializer
    @s_channel = IChannel.new @serializer
    @shutdown = false
    @states = {}
    @frequency = 0
  end

  def spawn
    reset
    fork do
      trap :SIGUSR1 do
        XPool.log "#{::Process.pid} got request to shutdown."
        @shutdown_requested = true
      end
      loop &method(:read_loop)
    end
  end

  def read_loop
    if @channel.readable?
      @s_channel.put busy: true
      msg = @channel.get
      msg[:unit].run *msg[:args]
      @s_channel.put busy: false
    end
    sleep 0.05
  rescue Exception => e
    XPool.log "#{::Process.pid} has failed."
    @s_channel.put failed: true, dead: true, backtrace: e.backtrace
    raise e
  ensure
    if @shutdown_requested && !@channel.readable?
      XPool.log "#{::Process.pid} is about to exit."
      exit 0
    end
  end
end
