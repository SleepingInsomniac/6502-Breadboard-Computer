require 'fileutils'

class Memory
  def self.uid
    if defined? @uid
      @uid += 1
    else
      @uid = 1
    end
  end

  attr_accessor :file

  def initialize(
    address_bus:, data_bus:, rwb:,
    enable: 0x4000, address_mask: 0x3FFF, size: 0x7FFF,
    file: nil, read_only: false
  )
    @address_bus  = address_bus
    @data_bus     = data_bus
    @rwb          = rwb
    @enable       = enable
    @address_mask = address_mask
    @read_only    = read_only
    @size         = size

    @file =
      if !file || file.is_a?(String)
        file_path = file || "/tmp/65c02_memory_#{Memory::uid}"
        FileUtils.touch(file_path) unless File.exist?(file_path)
        File.open(file_path, 'r+b')
      else
        file
      end
    @file.binmode

    if @file.size < @size
      @file.seek(@file.size)
      @file.write([0].pack('C') * (@size - @file.size))
      @file.rewind
    end
  end

  def update
    return unless @address_bus.read & @enable != 0
    if @rwb.read == 1 # value of 1 signifies read
      @data_bus.write(read(@address_bus.read))
    else # Value of 0 signifies write
      write(@address_bus.read, @data_bus.read)
    end
  end

  def read(address)
    @file.seek(address & @address_mask)
    @file.readbyte
  end

  def write(address, data)
    return false if @read_only
    @file.seek(address & @address_mask)
    @file.write [data].pack('C')
  end
end
