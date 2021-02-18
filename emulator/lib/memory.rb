require 'fileutils'

class Memory
  def self.uid
    @uid ||= 0; @uid += 1
  end

  attr_accessor :file

  def initialize(
    address_bus:, data_bus:, rwb:,
    addresses: 0x4000..0x5FFF,
    file: nil, read_only: false
  )
    @address_bus  = address_bus
    @data_bus     = data_bus
    @rwb          = rwb
    @addresses    = addresses
    @read_only    = read_only

    @file =
      if !file || file.is_a?(String)
        file_path = file || "/tmp/65c02_memory_#{Memory::uid}"
        FileUtils.touch(file_path) unless File.exist?(file_path)
        File.open(file_path, 'r+b')
      else
        file
      end
    @file.binmode

    if @file.size < @addresses.size
      @file.seek(@file.size)
      @file.write([0].pack('C') * (@addresses.size - @file.size))
      @file.rewind
    end
  end

  # IE: Returns 0 for 0x4000, 1 for 0x4001 if the addressing begins at 0x4000
  def localize(address)
    address - @addresses.begin
  end

  def update
    current_address = @address_bus.read
    return unless @addresses.include?(current_address)
    if @rwb.read == 1 # value of 1 signifies read
      @data_bus.write(read(current_address))
    else # Value of 0 signifies write
      write(current_address, @data_bus.read)
    end
  end

  def read(address)
    @file.seek(localize(address))
    @file.readbyte
  end

  def write(address, data)
    return false if @read_only
    @file.seek(localize(address))
    @file.write [data].pack('C')
  end
end
