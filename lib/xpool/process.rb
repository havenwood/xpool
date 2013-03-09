class XPool::Process
  #
  # @return [XPool::Process]
  #   Returns an instance of XPool::Process
  #
  def initialize
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
  #   Returns true when the process is executing work.
  #
  def busy?
    if dead?
      false
    elsif @status_channel.readable?
      set_busy_and_failed
      @busy
    else
      @busy
    end
  end

  def failed?
    @failed
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
    @dead = true
  end

  def reset
    @channel = IChannel.new Marshal
    @status_channel = IChannel.new Marshal
    @busy = false
    @dead = false
    @failed = false
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
    try do
      @status_channel.put busy: true
      msg = @channel.get
      msg[:unit].run *msg[:args]
      @status_channel.put busy: false
    end
  end

  def try
    if @channel.readable?
      yield
    end
  rescue Exception => e
    XPool.log "#{::Process.pid} has failed."
    @status_channel.put failed: true, dead: true, backtrace: e.backtrace
  ensure
    if @shutdown_requested && !@channel.readable?
      XPool.log "#{::Process.pid} is about to exit."
      exit 0
    end
  end

  def set_busy_and_failed
    begin
      message = @status_channel.get
      @busy, @failed, @dead, @backtrace = message.values_at :busy,
        :failed,
        :dead,
        :backtrace
    end while @status_channel.readable?
  end
end
