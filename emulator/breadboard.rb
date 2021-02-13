class Breadboard
  def initialize
    @callbacks = []
  end

  def on_update(&block)
    @callbacks << block
  end

  def update
    yield if block_given?
    @callbacks.each(&:call)
  end
end
