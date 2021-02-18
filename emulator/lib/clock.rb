class Clock
  attr_reader :cycles

  def initialize
    @cycles = 0
    @callbacks = []
  end

  def on_tick(&block)
    @callbacks << block
  end

  def tick
    @cycles += 1
    yield if block_given?
    @callbacks.each(&:call)
  end
end
