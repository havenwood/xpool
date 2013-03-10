class Raiser
  def run
    raise RuntimeError, "", %w(42)
  end
end
