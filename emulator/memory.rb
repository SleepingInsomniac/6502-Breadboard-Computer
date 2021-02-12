class Memory
  def initialize(address_bus:, data_bus:, rwb:, enable: 0b00000000_00000000)
    @address_bus = address_bus
    @data_bus    = data_bus
    @rwb         = rwb
    @enable      = enable

    @data = Hash.new { 0xFF } # Empty data is all 1s
    @rwb.on_write { update }
    @address_bus.on_write(@enable) { update }
  end

  def update
    if @rwb.read > 0 # value of 1 signifies read
      read(@address_bus.read)
    else # Value of 0 signifies write
      write(@address_bus.read)
    end
  end

  def read(address)
    @data[address]
  end

  def write(address)
    @data[address] = @data_bus.read
  end
end
