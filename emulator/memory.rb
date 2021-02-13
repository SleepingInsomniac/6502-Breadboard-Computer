require 'fileutils'

class Memory
  def self.uid
    if defined? @uid
      @uid += 1
    else
      @uid = 1
    end
  end

  def initialize(address_bus:, data_bus:, rwb:, enable: 0b00000000_00000000, file_path: nil, read_only: false, size: 0x7FFF)
    @address_bus = address_bus
    @data_bus    = data_bus
    @rwb         = rwb
    @enable      = enable
    @read_only   = read_only
    @size        = size

    @file_path = file_path || "/tmp/65c02_memory_#{Memory::uid}"
    FileUtils.touch(@file_path) unless File.exist?(@file_path)
    @file = File.open(@file_path, 'r+b')

    if @file.size < @size
      @file.write([0].pack('C') * (@size - @file.size))
    end

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
    @file.seek(@size & address)
    @file.readbyte
  end

  def write(address)
    return if @read_only
    @file.seek(@size & address)
    @file.write [@data_bus.read].pack('C')
  end
end
