class XPool::Process
  #
  # @param [Fixnum] id 
  #   The Process ID.
  #
  def initialize(id)
    @id = id
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
  
private
  def _shutdown(sig)
    begin
      Process.kill sig, @id
      Process.wait @id
    rescue SystemCallError
    end
  end
end
