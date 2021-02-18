class Bus
  # @param size - number of bits in bus
  def initialize(size)
    @size = size
    @mask = (1 << @size) - 1 # convert to bitmask
    @data = 0
  end

  def read
    @data
  end

  def write(value)
    @data = value & @mask
  end

  def to_s(radix = 16)
    @data.to_s(radix)
  end
end
