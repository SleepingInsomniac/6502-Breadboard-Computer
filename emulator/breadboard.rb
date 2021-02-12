class Breadboard
  attr_reader :cpu

  def initialize
    @address_bus = Bus.new(16)
    @data_bus    = Bus.new(8)
    @clock       = Bus.new(1)
    @rwb         = Bus.new(1)

    @ram         = Memory.new(
      address_bus: @address_bus,
      data_bus: @data_bus,
      rwb: @rwb,
      enable: 0x4000
    )

    @rom         = Memory.new(
      address_bus: @address_bus,
      data_bus: @data_bus,
      rwb: @rwb,
      enable: 0x8000
    )

    @cpu         = CPU.new(
      address_bus: @address_bus,
      data_bus: @data_bus
    )
  end
end
