class Bus
  # @param size - number of bits in bus
  def initialize(size)
    @size = size
    @mask = (1 << @size) - 1 # convert to bitmask
    @data = 0
    @read_callbacks = []
    @write_callbacks = []
  end

  def read
    @data.tap do |val|
      @read_callbacks.each { |func| func.call(val) }
    end
  end

  def write(value)
    @data = (value & @mask).tap do |val|
      @write_callbacks.each { |func| func.call(val) }
    end
  end

  def on_read(mask = @mask, &block)
    @read_callbacks.push ->(val) do
      block.call(val) if mask & val == mask
    end
  end

  def on_write(mask = @mask, &block)
    @write_callbacks.push ->(val) do
      block.call(val) if mask & val == mask
    end
  end
end
