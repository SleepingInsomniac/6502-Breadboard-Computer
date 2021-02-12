class CPU
  # Registers
  # - Accumulator
  # - Index X
  # - Index Y
  # - Processor Status
  #    [ N V 1 B D I Z C ]
  #      | |   | | | | ^-- Carry          1 = true
  #      | |   | | | ^---- Zero           1 = true
  #      | |   | | ^------ IRQB Disable   1 = Disable
  #      | |   | ^-------- Decimal Mode   1 = true
  #      | |   ^---------- BRK            1 = BRK, 0 = IRQB
  #      | ^-------------- Overflow       1 = true
  #      ^---------------- Negative       1 = true
  # - Program Counter (16 bits internally PCH/PCL)
  # - Stack Pointer
  attr_reader :a, :x, :y, :p, :pc, :s

  # Pins
  attr_reader :rwb # Read / Write bit
  attr_accessor :be # Bus enable
  attr_accessor :irqb # Interrupt Request

  # - @param address_bus : Bus - 16
  # - @param data_bus    : Bus - 8
  # - @param clock       : Bus - 1
  def initialize(address_bus:, data_bus:, rwb:, clock:)
    @address_bus = address_bus
    @data_bus = data_bus
    @rwb = rwb
    @clock = clock

    # Init registers
    @a  = 0b0000_0000
    @x  = 0b0000_0000
    @y  = 0b0000_0000
    @p  = 0b0011_0100 # N,V,Z,C software initialized
    @pc = 0b0000_0000_0000_0000 # 16 bits
    @s  = 0b0000_0000

    # Connect clock on rising edge
    @clock.on_write { |value| tick if value == 1 }
  end

  def tick(value)
    pc += 1 # Increment program counter
    # TODO: Do cpu stuff
  end
end
