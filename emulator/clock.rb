class Clock
  attr_accessor :bus

  def initialize(bus)
    @bus = bus
  end

  def tick
    @bus.write(1)
    @bus.write(0)
  end
end
