require 'tempfile'
class IOWriter
  def initialize
    file = Tempfile.new '__xpool_test'
    @path = file.path
    file.close false
  end

  def run
    File.open @path, 'w' do |f|
      f.write 'true'
      sleep 0.1
    end
  end

  def run?
    return @run if defined?(@run)
    @run = File.read(@path) == 'true'
    FileUtils.rm_rf @path
    @run
  end
end
