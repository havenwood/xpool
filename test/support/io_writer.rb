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
    end
  end

  def wrote_to_disk?
    return @wrote_to_disk if defined?(@wrote_to_disk)
    @wrote_to_disk = File.read(@path) == 'true'
    FileUtils.rm_rf @path
    @wrote_to_disk
  end
end
