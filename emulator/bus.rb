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
    @read_callbacks.each { |func| func.call(@data) }
    @data
  end

  def write(value)
    new_val = value & @mask
    old_val = @data
    @data = new_val
    @write_callbacks.each { |func| func.call(new_val, old_val) }
  end

  def on_read(mask = @mask, &block)
    @read_callbacks.push ->(value) { block.call(value) if value & mask != 0 }
  end

  def on_write(mask = @mask, &block)
    @write_callbacks.push ->(value, old_value) do
      block.call(value) if diff_bit?(old_value, value, mask)
    end
  end

  def diff_bit?(value, change, mask)
    value ^ change & mask != 0
  end
end
