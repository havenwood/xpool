class XPool::Process
  def initialize
    @id = nil
    @busy = false
    @spawned = false
    @job_channel = IChannel.new Marshal
    @busy_channel = IChannel.new JSON
  end

  #
  # Spawn a subprocess.
  # 
  # @return [void]
  #
  def spawn
    @active = true
    @id = fork
    listen
  end

  #
  # @return [Boolean]
  #   Returns true when the process is alive.
  #   
  def active
    @active
  end
  alias_method :active?, :active

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
    _shutdown 'SIGUSR1'
  end

  #
  # A non-graceful shutdown through SIGKILL.
  #
  # @return [void]
  #
  def shutdown!
    _shutdown 'SIGKILL'
  end
  
  #
  # Schedule a unit of work to be executed in the subprocess.
  #
  # @param [#call] unit
  #   Any object that responds to `#call`.
  #   Well, almost. We cannot serialize Proc objects.
  #
  # @return [void]
  #
  def schedule(unit)
    @busy = true
    @job_channel.put unit
  end

  #
  # @return [Boolean]
  #   Returns true if the subprocess is busy executing a unit of work.
  #
  def busy
    @busy
  end
  alias_method :busy?, :busy

private
  def _shutdown(sig)
    begin
      Process.kill sig, @id
      Process.wait @id
    rescue SystemCallError
    ensure
      @active = false
      [@job_channel.close, @busy_channel.close]
    end
  end

  def listen
    Thread.new do 
      loop do
        msg = @busy_channel.get
        @busy = msg["busy"] if msg
      end
    end
  end

  def fork
    super do
      trap :SIGUSR1 do
        while @busy
          sleep 0.1
        end
        exit
      end
      Thread.new do 
        loop &method(:dispatch_loop)
      end.join
    end
  end
  
  def dispatch_loop
    unit = @job_channel.get
    if unit
      begin
        @busy = true
        @busy_channel.put busy: true
        unit.call
      ensure 
        @busy = false
        @busy_channel.put busy: false
      end
    end
  end
end
