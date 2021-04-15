require_relative './cpu_65c02/op_codes'
require_relative './cpu_65c02/addressing_modes'
require_relative './cpu_65c02/instructions'

class CPU65c02
  VECTORS = {
    BRK:  0xFFFE,
    IRKB: 0xFFFE,
    RESB: 0xFFFC,
    NMIB: 0xFFFA,
  }

  # Registers
  # - Accumulator
  # - Index X
  # - Index Y
  # - Processor Status
  # - Program Counter (16 bits internally PCH/PCL)
  # - Stack Pointer
  attr_accessor :a, :x, :y, :p, :pc, :s

  # Pins
  attr_accessor :be # Bus enable
  attr_accessor :irqb # Interrupt Request

  # - @param address_bus : Bus - 16
  # - @param data_bus    : Bus - 8
  # - @param rwb         : Bus - 1
  # - @param clock       : Clock
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
  end

  def address=(value)
    @pc = value & 0xFFFF
    @address_bus.write(@pc)
  end

  def step
    # Get the instruction from the current address on the databus
    mnemonic, mode = mnemonic(read(@pc))
    # Call the instruction with the correct addressing mode
    send(mnemonic.downcase, mode)
  end

  def read(address)
    @clock.tick do
      @rwb.write(1) # Set read mode
      @address_bus.write(address) # Write address to bus, with update
    end
    @data_bus.read # Read data bus
  end

  def write(data, to:)
    @clock.tick do
      @rwb.write(0) # Set write mode
      @data_bus.write(data) # Output on data bus
      @address_bus.write(to) # Write address to bus
    end
    @rwb.write(1)
  end

  # Read the next byte at the program counter
  def read_next
    @pc += 1
    read(@pc)
  end

  # Decode the instruction and addressing mode of the given byte
  def mnemonic(opcode)
    _mnemonic, _mode = OP_CODES[opcode].split(' ')
  end

  # Get the operand of the current instruction based on addressing mode
  def operand(mode)
    self.send("addr_" + ADDRESSING_MODES[mode].downcase.gsub(/\s/, '_'))
  end

  # ==== Addressing Modes ====

  # a : 4 cycles (Read-Modify-Write, add 2 cycles)
  def addr_absolute
    adl = read_next # Read low order byte
    adh = read_next # Read high order byte
    (adh << 8) | adl # Combine to get 16 bit address
  end

  # (a,x) : 6 cycles
  def addr_absolute_indexed_indirect
    adl = read_next
    adh = read_next # Fetch next two bytes for indirect base address
    ind_addr = ((adh << 8) | adl) + @x # Combine to get 16 bit address + x reg
    adl = read(ind_addr)
    adh = read(ind_addr + 1)
    ((adh << 8) | adl)
  end

  # a,x
  def addr_absolute_indexed_with_x
    adl = read_next
    adh = read_next
    ((adh << 8) | adl) + @x
  end

  def addr_absolute_indexed_with_y
    adl = read_next; adh = read_next
    ((adh << 8) | adl) + @y
  end

  def addr_absolute_indirect
    adl = read_next; adh = read_next
    ind_address = ((adh << 8) | adl)
    adl = read(ind_address)
    adh = read(ind_address + 1)
    ((adh << 8) | adl)
  end

  def addr_accumulator
    @a
  end

  def addr_immediate
    read_next # return the next byte
  end

  def addr_implied
    # Nothing to do here.
  end

  def addr_program_counter_relative
    offset = read_next
    @pc + offset
  end

  def addr_stack
    @s
  end

  def addr_zero_page
    read_next
  end

  def addr_zero_page_indexed_indirect
    read_next + @x
  end

  def addr_zero_page_indexed_with_x
    read_next + @x
  end

  def addr_zero_page_indexed_with_y
    read_next + @y
  end

  def addr_zero_page_indirect
    read_next
  end

  def addr_zero_page_indirect_indexed_with_y
    read_next + @y
  end

  # ==== Instructions ====

  # ADd memory to accumulator with Carry
  # Status Register:
  #   7N 6V 51 41 3D 2I 1Z 0C
  #    N, V,  ,  ,  ,  , Z, C
  def adc(mode)
    # 61: (zp,x), Zero Page Indexed Indirect
    # 65: zp, Zero Page
    # 69: #, Immediate
    # 6d: a, Absolute
    # 71: (zp),y, Zero Page Indirect Indexed with Y
    # 72: (zp), Zero Page Indirect
    # 75: zp,x, Zero Page Indexed with X
    # 79: a,y, Absolute Indexed with Y
    # 7d: a,x, Absolute Indexed with X
    value = operand(mode)
    flag_set P_NEGATIVE, (@a + value)[7] == 1
    flag_set P_OVERFLOW, (@a + value)[7] == 1 && @a[7] == 1 && value[7] == 1
    flag_set P_ZERO,     (@a + value) & 0xFF == 0
    flag_set P_CARRY,    @a > 0xFF
    @a = (@a + value) & 0xFF
  end

  # "AND" memory with accumulator
  # Status Register:
  #   7N 6V 51 41 3D 2I 1Z 0C
  #    N,  ,  ,  ,  ,  , Z,
  def and(mode)
    # 21: (zp,x), Zero Page Indexed Indirect
    # 25: zp, Zero Page
    # 29: #, Immediate
    # 2d: a, Absolute
    # 31: (zp),y, Zero Page Indirect Indexed with Y
    # 32: (zp), Zero Page Indirect
    # 35: zp,x, Zero Page Indexed with X
    # 39: a,y, Absolute Indexed with Y
    # 3d: a,x, Absolute Indexed with X
    @a &= operand(mode)
    flag_set P_NEGATIVE, @a[7] == 1
    flag_set P_ZERO,     @a.zero?
  end

  # Arithmetic Shift one bit Left, memory or accumulator
  # Status Register:
  #   7N 6V 51 41 3D 2I 1Z 0C
  #    N,  ,  ,  ,  ,  , Z, C
  def asl(mode)
    # 06: zp, Zero Page
    # 0a: A, Accumulator
    # 0e: a, Absolute
    # 16: zp,x, Zero Page Indexed with X
    # 1e: a,x, Absolute Indexed with X
    if mode == 'i' # Implied
      @a <<= 1
      flag_set P_CARRY,     @a[8] == 1
      flag_set P_ZERO,      @a.zero?
      flag_set P_NEGATIVE,  @a[7] == 1
      @a &= 0xF
    else
      address = operand(mode)
      memory = read(address)
      memory <<= 1
      flag_set(P_CARRY,     memory[8] == 1)
      flag_set P_ZERO,      memory.zero?
      flag_set P_NEGATIVE,  memory[7] == 1
      write(memory, to: address)
    end
  end

  (0..7).each do |bit|
    define_method(:"bbr#{bit}") do |mode|
      bbr(bit, mode)
    end
  end

  # Branch on Bit Reset
  # Status Register:
  #   7N 6V 51 41 3D 2I 1Z 0C
  #     ,  ,  ,  ,  ,  ,  ,
  def bbr(bit, mode)
    # 0f: r, Program Counter Relative
    # 1f: r, Program Counter Relative
    # 2f: r, Program Counter Relative
    # 3f: r, Program Counter Relative
    # 4f: r, Program Counter Relative
    # 5f: r, Program Counter Relative
    # 6f: r, Program Counter Relative
    # 7f: r, Program Counter Relative
    # TODO
  end

  (0..7).each do |bit|
    define_method(:"bbs#{bit}") do |mode|
      bbs(bit, mode)
    end
  end

  # Branch of Bit Set
  # Status Register:
  #   7N 6V 51 41 3D 2I 1Z 0C
  #     ,  ,  ,  ,  ,  ,  ,
  def bbs(bit, mode)
    # 8f: r, Program Counter Relative
    # 9f: r, Program Counter Relative
    # af: r, Program Counter Relative
    # bf: r, Program Counter Relative
    # cf: r, Program Counter Relative
    # df: r, Program Counter Relative
    # ef: r, Program Counter Relative
    # ff: r, Program Counter Relative
    # TODO
  end

  # Branch on Carry Clear (Pc=0)
  # Status Register:
  #   7N 6V 51 41 3D 2I 1Z 0C
  #     ,  ,  ,  ,  ,  ,  ,
  def bcc(mode)
    # 90: r, Program Counter Relative
    @pc = addr unless flag?(P_CARRY)
  end

  # Branch on Carry Set (Pc=1)
  # Status Register:
  #   7N 6V 51 41 3D 2I 1Z 0C
  #     ,  ,  ,  ,  ,  ,  ,
  def bcs(mode)
    # b0: r, Program Counter Relative
    @pc = operand(mode) if flag?(P_CARRY)
  end

  # Branch if EQual (Pz=1)
  # Status Register:
  #   7N 6V 51 41 3D 2I 1Z 0C
  #     ,  ,  ,  ,  ,  ,  ,
  def beq(mode)
    # f0: r, Program Counter Relative
    @pc = operand(mode) if flag?(P_ZERO)
  end

  # BIt Test
  # Status Register:
  #   7N 6V 51 41 3D 2I 1Z 0C
  #   m7,m6,  ,  ,  ,  , Z,
  def bit(mode)
    # 24: zp, Zero Page
    # 2c: a, Absolute
    # 34: zp,x, Zero Page Indexed with X
    # 3c: a,x, Absolute Indexed with X
    # 89: #, Immediate
    value = operand(mode)
    value ^= @a
    # Does not affect the NV flags
    # This is the only instruction with addressing dependent flags
    if mode != '#' # Immediate
      flag_set P_NEGATIVE, value[7] == 1
      flag_set P_OVERFLOW, value[6] == 1 # TODO: check if overflow 2's compliment correctly?
    end
    flag_set P_ZERO,     value & @a == 0
  end

  # Branch if result MInus (Pn=1)
  # Status Register:
  #   7N 6V 51 41 3D 2I 1Z 0C
  #     ,  ,  ,  ,  ,  ,  ,
  def bmi(mode)
    # 30: r, Program Counter Relative
    @pc = operand(mode) if flag?(P_NEGATIVE)
  end

  # Branch if Not Equal (Pz=0)
  # Status Register:
  #   7N 6V 51 41 3D 2I 1Z 0C
  #     ,  ,  ,  ,  ,  ,  ,
  def bne(mode)
    # d0: r, Program Counter Relative
    @pc = operand(mode) unless flag?(P_ZERO)
  end

  # Branch if result PLus (Pn=0)
  # Status Register:
  #   7N 6V 51 41 3D 2I 1Z 0C
  #     ,  ,  ,  ,  ,  ,  ,
  def bpl(mode)
    # 10: r, Program Counter Relative
    @pc = operand(mode) unless flag?(P_NEGATIVE)
  end

  # BRanch Always
  # Status Register:
  #   7N 6V 51 41 3D 2I 1Z 0C
  #     ,  ,  ,  ,  ,  ,  ,
  def bra(mode)
    # 80: r, Program Counter Relative
    @pc = operand(mode)
  end

  # BReaK instruction
  # Status Register:
  #   7N 6V 51 41 3D 2I 1Z 0C
  #     ,  ,  , 1, 0, 1,  ,
  def brk(mode)
    # 00: s, Stack
    flag_set(P_BRK,          true)
    flag_set(P_DECIMAL_MODE, false)
    flag_set(P_IRQB_DISABLE, true)
  end

  # Branch on oVerflow Clear (Pv=0)
  # Status Register:
  #   7N 6V 51 41 3D 2I 1Z 0C
  #     ,  ,  ,  ,  ,  ,  ,
  def bvc(mode)
    # 50: r, Program Counter Relative
    @pc = operand(mode) unless flag?(P_OVERFLOW)
  end

  # Branch on oVerflow Set (Pv=1)
  # Status Register:
  #   7N 6V 51 41 3D 2I 1Z 0C
  #     ,  ,  ,  ,  ,  ,  ,
  def bvs(mode)
    # 70: r, Program Counter Relative
    @pc = operand(mode) if flag?(P_OVERFLOW)
  end

  # CLear Cary flag
  # Status Register:
  #   7N 6V 51 41 3D 2I 1Z 0C
  #     ,  ,  ,  ,  ,  ,  , 0
  def clc(mode)
    # 18: i, Implied
    flag_set(P_CARRY, false)
  end

  # CLear Decimal mode
  # Status Register:
  #   7N 6V 51 41 3D 2I 1Z 0C
  #     ,  ,  ,  , 0,  ,  ,
  def cld(mode)
    # d8: i, Implied
    flag_set(P_DECIMAL_MODE, false)
  end

  # CLear Interrupt disable bit
  # Status Register:
  #   7N 6V 51 41 3D 2I 1Z 0C
  #     ,  ,  ,  ,  , 0,  ,
  def cli(mode)
    # 58: i, Implied
    flag_set(P_IRQB_DISABLE, false)
  end

  # CLear oVerflow flag
  # Status Register:
  #   7N 6V 51 41 3D 2I 1Z 0C
  #     , 0,  ,  ,  ,  ,  ,
  def clv(mode)
    # b8: i, Implied
    flag_set(P_OVERFLOW, false)
  end

  # CoMPare memory and accumulator
  # Status Register:
  #   7N 6V 51 41 3D 2I 1Z 0C
  #    N,  ,  ,  ,  ,  , Z, C
  def cmp(mode)
    # c1: (zp,x), Zero Page Indexed Indirect
    # c5: zp, Zero Page
    # c9: #, Immediate
    # cd: a, Absolute
    # d1: (zp),y, Zero Page Indirect Indexed with Y
    # d2: (zp), Zero Page Indirect
    # d5: zp,x, Zero Page Indexed with X
    # d9: a,y, Absolute Indexed with Y
    # dd: a,x, Absolute Indexed with X
    value = operand(mode)
    result = @a - value
    flag_set P_NEGATIVE, result[7] == 1 # Bit 7 indicates sign for two's compliment
    flag_set P_ZERO,     (result & 0xFF).zero?
    flag_set P_CARRY,    result[8]
  end

  # ComPare memory and X register
  # Status Register:
  #   7N 6V 51 41 3D 2I 1Z 0C
  #    N,  ,  ,  ,  ,  , Z, C
  def cpx(mode)
    # e0: #, Immediate
    # e4: zp, Zero Page
    # ec: a, Absolute
    value = operand(mode)
    result = @x - value
    flag_set P_NEGATIVE, result[7] == 1 # Bit 7 indicates sign for two's compliment
    flag_set P_ZERO,     (result & 0xFF).zero?
    flag_set P_CARRY,    result[8]
  end

  # ComPare memory and Y register
  # Status Register:
  #   7N 6V 51 41 3D 2I 1Z 0C
  #    N,  ,  ,  ,  ,  , Z, C
  def cpy(mode)
    # c0: #, Immediate
    # c4: zp, Zero Page
    # cc: a, Absolute
    value = operand(mode)
    result = @y - value
    flag_set P_NEGATIVE, result[7] == 1 # Bit 7 indicates sign for two's compliment
    flag_set P_ZERO,     (result & 0xFF).zero?
    flag_set P_CARRY,    result[8]
  end

  # DECrement memory or accumulate by one
  # Status Register:
  #   7N 6V 51 41 3D 2I 1Z 0C
  #    N,  ,  ,  ,  ,  , Z,
  def dec(mode)
    # 3a: A, Accumulator
    # c6: zp, Zero Page
    # ce: a, Absolute
    # d6: zp,x, Zero Page Indexed with X
    # de: a,x, Absolute Indexed with X
    value = operand(mode)
    # TODO
  end

  # DEcrement X by one
  # Status Register:
  #   7N 6V 51 41 3D 2I 1Z 0C
  #    N,  ,  ,  ,  ,  , Z,
  def dex(mode)
    # ca: i, Implied
    # TODO
  end

  # DEcrement Y by one
  # Status Register:
  #   7N 6V 51 41 3D 2I 1Z 0C
  #    N,  ,  ,  ,  ,  , Z,
  def dey(mode)
    # 88: i, Implied
    # TODO
  end

  # "Exclusive OR" memory with accumulate
  # Status Register:
  #   7N 6V 51 41 3D 2I 1Z 0C
  #    N,  ,  ,  ,  ,  , Z,
  def eor(mode)
    # 41: (zp,x), Zero Page Indexed Indirect
    # 45: zp, Zero Page
    # 49: #, Immediate
    # 4d: a, Absolute
    # 51: (zp),y, Zero Page Indirect Indexed with Y
    # 52: (zp), Zero Page Indirect
    # 55: zp,x, Zero Page Indexed with X
    # 59: a,y, Absolute Indexed with Y
    # 5d: a,x, Absolute Indexed with X
    # TODO
  end

  # INCrement memory or accumulate by one
  # Status Register:
  #   7N 6V 51 41 3D 2I 1Z 0C
  #    N,  ,  ,  ,  ,  , Z,
  def inc(mode)
    # 1a: A, Accumulator
    # e6: zp, Zero Page
    # ee: a, Absolute
    # f6: zp,x, Zero Page Indexed with X
    # fe: a,x, Absolute Indexed with X
    # TODO
  end

  # INcrement X register by one
  # Status Register:
  #   7N 6V 51 41 3D 2I 1Z 0C
  #    N,  ,  ,  ,  ,  , Z,
  def inx(mode)
    # e8: i, Implied
    # TODO
  end

  # INcrement Y register by one
  # Status Register:
  #   7N 6V 51 41 3D 2I 1Z 0C
  #    N,  ,  ,  ,  ,  , Z,
  def iny(mode)
    # c8: i, Implied
    # TODO
  end

  # JuMP to new location
  # Status Register:
  #   7N 6V 51 41 3D 2I 1Z 0C
  #     ,  ,  ,  ,  ,  ,  ,
  def jmp(mode)
    # 4c: a, Absolute
    # 6c: (a), Absolute Indirect
    # 7c: (a,x), Absolute Indexed Indirect
    # TODO
  end

  # Jump to new location Saving Return (Jump to SubRoutine)
  # Status Register:
  #   7N 6V 51 41 3D 2I 1Z 0C
  #    N,  ,  ,  ,  ,  , Z,
  def jsr(mode)
    # 20: a, Absolute
    write(@p,        to: @s += 1) # Store processor status on stack
    write(@pc & 0xF, to: @s += 1) # Store program counter (low order)
    write(@pc >> 8,  to: @s += 1) # Store PC (High order)
    @pc = operand(mode) # Set program counter
    flag_set P_ZERO, @pc.zero? # datasheet says these get set?
    flag_set P_NEGATIVE, @pc[15] == 1 # TODO: Is this even right??
  end

  # LoaD Accumulator with memory
  # Status Register:
  #   7N 6V 51 41 3D 2I 1Z 0C
  #    N,  ,  ,  ,  ,  , Z,
  def lda(mode)
    # a1: (zp,x), Zero Page Indexed Indirect
    # a5: zp, Zero Page
    # a9: #, Immediate
    # ad: a, Absolute
    # b1: (zp),y, Zero Page Indirect Indexed with Y
    # b2: (zp), Zero Page Indirect
    # b5: zp,x, Zero Page Indexed with X
    # b9: A,y,
    # bd: a,x, Absolute Indexed with X
    @a = operand(mode) & 0xFF
    flag_set P_ZERO,     @a.zero?
    flag_set P_NEGATIVE, @a[7] == 1
  end

  # LoaD the X register with memory
  # Status Register:
  #   7N 6V 51 41 3D 2I 1Z 0C
  #    N,  ,  ,  ,  ,  , Z,
  def ldx(mode)
    # a2: #, Immediate
    # a6: zp, Zero Page
    # ae: a, Absolute
    # b6: zp,y, Zero Page Indexed with Y
    # be: a,y, Absolute Indexed with Y
    @x = operand(mode) & 0xFF
    flag_set P_ZERO      @x.zero?
    flag_set P_NEGATIVE, @x[7] == 1
  end

  # LoaD the Y register with memory
  # Status Register:
  #   7N 6V 51 41 3D 2I 1Z 0C
  #    N,  ,  ,  ,  ,  , Z,
  def ldy(mode)
    # a0: #, Immediate
    # a4: zp, Zero Page
    # ac: A, Accumulator
    # b4: zp,x, Zero Page Indexed with X
    # bc: a,x, Absolute Indexed with X
    @y = operand(mode) & 0xFF
    flag_set P_ZERO,     @y.zero?
    flag_set P_NEGATIVE, @y[7] == 1
  end

  # Logical Shift one bit Right memory or accumulator
  # Status Register:
  #   7N 6V 51 41 3D 2I 1Z 0C
  #    0,  ,  ,  ,  ,  , Z, C
  def lsr(mode)
    # 46: zp, Zero Page
    # 4a: A, Accumulator
    # 4e: a, Absolute
    # 56: zp,x, Zero Page Indexed with X
    # 5e: a,x, Absolute Indexed with X
    # TODO
  end

  # No OPeration
  # Status Register:
  #   7N 6V 51 41 3D 2I 1Z 0C
  #     ,  ,  ,  ,  ,  ,  ,
  def nop(mode)
    # ea: i, Implied
    # TODO
  end

  # "OR" memory with Accumulator
  # Status Register:
  #   7N 6V 51 41 3D 2I 1Z 0C
  #    N,  ,  ,  ,  ,  , Z,
  def ora(mode)
    # 01: (zp,x), Zero Page Indexed Indirect
    # 05: zp, Zero Page
    # 09: #, Immediate
    # 0d: a, Absolute
    # 11: (zp),y, Zero Page Indirect Indexed with Y
    # 12: (zp), Zero Page Indirect
    # 15: zp,x, Zero Page Indexed with X
    # 19: a,y, Absolute Indexed with Y
    # 1d: a,x, Absolute Indexed with X
    # TODO
  end

  # PusH Accumulator on stack
  # Status Register:
  #   7N 6V 51 41 3D 2I 1Z 0C
  #     ,  ,  ,  ,  ,  ,  ,
  def pha(mode)
    # 48: s, Stack
    # TODO
  end

  # PusH Processor status on stack
  # Status Register:
  #   7N 6V 51 41 3D 2I 1Z 0C
  #     ,  ,  ,  ,  ,  ,  ,
  def php(mode)
    # 08: s, Stack
    # TODO
  end

  # PusH X register on stack
  # Status Register:
  #   7N 6V 51 41 3D 2I 1Z 0C
  #     ,  ,  ,  ,  ,  ,  ,
  def phx(mode)
    # da: s, Stack
    # TODO
  end

  # PusH Y register on stack
  # Status Register:
  #   7N 6V 51 41 3D 2I 1Z 0C
  #     ,  ,  ,  ,  ,  ,  ,
  def phy(mode)
    # 5a: s, Stack
    # TODO
  end

  # PuLl Accumulator from stack
  # Status Register:
  #   7N 6V 51 41 3D 2I 1Z 0C
  #    N,  ,  ,  ,  ,  , Z,
  def pla(mode)
    # 68: s, Stack
    # TODO
  end

  # PuLl Processor status from stack
  # Status Register:
  #   7N 6V 51 41 3D 2I 1Z 0C
  #    N, V,  , 1, D, I, Z, C
  def plp(mode)
    # 28: s, Stack
    # TODO
  end

  # PuLl X register from stack
  # Status Register:
  #   7N 6V 51 41 3D 2I 1Z 0C
  #    N,  ,  ,  ,  ,  , Z,
  def plx(mode)
    # fa: s, Stack
    # TODO
  end

  # PuLl Y register from stack
  # Status Register:
  #   7N 6V 51 41 3D 2I 1Z 0C
  #    N,  ,  ,  ,  ,  , Z,
  def ply(mode)
    # 7a: s, Stack
    # TODO
  end

  (0..7).each do |bit|
    define_method(:"rmb#{bit}") do |mode|
      rmb(bit, mode)
    end
  end

  # Reset Memory Bit
  # Status Register:
  #   7N 6V 51 41 3D 2I 1Z 0C
  #     ,  ,  ,  ,  ,  ,  ,
  def rmb(bit, mode)
    # 07: zp, Zero Page
    # 17: zp, Zero Page
    # 27: zp, Zero Page
    # 37: zp, Zero Page
    # 47: zp, Zero Page
    # 57: zp, Zero Page
    # 67: zp, Zero Page
    # 77: zp, Zero Page
    # TODO
  end

  # ROtate one bit Left memory or accumulator
  # Status Register:
  #   7N 6V 51 41 3D 2I 1Z 0C
  #    N,  ,  ,  ,  ,  , Z, C
  def rol(mode)
    # 26: zp, Zero Page
    # 2a: A, Accumulator
    # 2e: a, Absolute
    # 36: zp,x, Zero Page Indexed with X
    # 3e: a,x, Absolute Indexed with X
    # TODO
  end

  # ROtate one bit Right memory or accumulator
  # Status Register:
  #   7N 6V 51 41 3D 2I 1Z 0C
  #    N,  ,  ,  ,  ,  , Z, C
  def ror(mode)
    # 66: zp, Zero Page
    # 6a: A, Accumulator
    # 6e: a, Absolute
    # 76: zp,x, Zero Page Indexed with X
    # 7e: a,x, Absolute Indexed with X
    # TODO
  end

  # ReTurn from Interrupt
  # Status Register:
  #   7N 6V 51 41 3D 2I 1Z 0C
  #    N, V,  , 1, D, I, Z, C
  def rti(mode)
    # 40: s, Stack
    # TODO
  end

  # ReTurn from Subroutine
  # Status Register:
  #   7N 6V 51 41 3D 2I 1Z 0C
  #     ,  ,  ,  ,  ,  ,  ,
  def rts(mode)
    # 60: s, Stack
    # TODO
  end

  # SuBtract memory from accumulator with borrow (Carry bit)
  # Status Register:
  #   7N 6V 51 41 3D 2I 1Z 0C
  #    N, V,  ,  ,  ,  , Z, C
  def sbc(mode)
    # e1: (zp,x), Zero Page Indexed Indirect
    # e5: zp, Zero Page
    # e9: #, Immediate
    # ed: a, Absolute
    # f1: (zp),y, Zero Page Indirect Indexed with Y
    # f2: (zp), Zero Page Indirect
    # f5: zp,x, Zero Page Indexed with X
    # f9: a,y, Absolute Indexed with Y
    # fd: a,x, Absolute Indexed with X
    # TODO
  end

  # SEt Carry
  # Status Register:
  #   7N 6V 51 41 3D 2I 1Z 0C
  #     ,  ,  ,  ,  ,  ,  , 1
  def sec(mode)
    # 38: I,
    # TODO
  end

  # SEt Decimal mode
  # Status Register:
  #   7N 6V 51 41 3D 2I 1Z 0C
  #     ,  ,  ,  , 1,  ,  ,
  def sed(mode)
    # f8: i, Implied
    # TODO
  end

  # SEt Interrupt disable status
  # Status Register:
  #   7N 6V 51 41 3D 2I 1Z 0C
  #     ,  ,  ,  ,  , 1,  ,
  def sei(mode)
    # 78: i, Implied
    # TODO
  end

  (0..7).each do |bit|
    define_method(:"smb#{bit}") do |mode|
      smb(bit, mode)
    end
  end

  # Set Memory Bit
  # Status Register:
  #   7N 6V 51 41 3D 2I 1Z 0C
  #     ,  ,  ,  ,  ,  ,  ,
  def smb(bit, mode)
    # 87: zp, Zero Page
    # 97: zp, Zero Page
    # a7: zp, Zero Page
    # b7: zp, Zero Page
    # c7: zp, Zero Page
    # d7: zp, Zero Page
    # e7: zp, Zero Page
    # f7: zp, Zero Page
    # TODO
  end

  # STore Accumulator in memory
  # Status Register:
  #   7N 6V 51 41 3D 2I 1Z 0C
  #     ,  ,  ,  ,  ,  ,  ,
  def sta(mode)
    # 81: (zp,x), Zero Page Indexed Indirect
    # 85: zp, Zero Page
    # 8d: a, Absolute
    # 91: (zp),y, Zero Page Indirect Indexed with Y
    # 92: (zp), Zero Page Indirect
    # 95: zp,x, Zero Page Indexed with X
    # 99: a,y, Absolute Indexed with Y
    # 9d: a,x, Absolute Indexed with X
    # TODO
  end

  # SToP mode
  # Status Register:
  #   7N 6V 51 41 3D 2I 1Z 0C
  #     ,  ,  ,  ,  ,  ,  ,
  def stp(mode)
    # db: I,
    # TODO
  end

  # STore the X register in memory
  # Status Register:
  #   7N 6V 51 41 3D 2I 1Z 0C
  #     ,  ,  ,  ,  ,  ,  ,
  def stx(mode)
    # 86: zp, Zero Page
    # 8e: a, Absolute
    # 96: zp,y, Zero Page Indexed with Y
    # TODO
  end

  # STore the Y register in memory
  # Status Register:
  #   7N 6V 51 41 3D 2I 1Z 0C
  #     ,  ,  ,  ,  ,  ,  ,
  def sty(mode)
    # 84: zp, Zero Page
    # 8c: a, Absolute
    # 94: zp,x, Zero Page Indexed with X
    # TODO
  end

  # STore Zero in memory
  # Status Register:
  #   7N 6V 51 41 3D 2I 1Z 0C
  #     ,  ,  ,  ,  ,  ,  ,
  def stz(mode)
    # 64: zp, Zero Page
    # 74: zp,x, Zero Page Indexed with X
    # 9c: a, Absolute
    # 9e: a,x, Absolute Indexed with X
    # TODO
  end

  # Transfer the Accumulator to the X register
  # Status Register:
  #   7N 6V 51 41 3D 2I 1Z 0C
  #    N,  ,  ,  ,  ,  , Z,
  def tax(mode)
    # aa: i, Implied
    # TODO
  end

  # Transfer the Accumulator to the Y register
  # Status Register:
  #   7N 6V 51 41 3D 2I 1Z 0C
  #    N,  ,  ,  ,  ,  , Z,
  def tay(mode)
    # a8: i, Implied
    # TODO
  end

  # Test and Reset memory Bit
  # Status Register:
  #   7N 6V 51 41 3D 2I 1Z 0C
  #     ,  ,  ,  ,  ,  , Z,
  def trb(mode)
    # 14: zp, Zero Page
    # 1c: a, Absolute
    # TODO
  end

  # Test and Set memory Bit
  # Status Register:
  #   7N 6V 51 41 3D 2I 1Z 0C
  #     ,  ,  ,  ,  ,  , Z,
  def tsb(mode)
    # 04: zp, Zero Page
    # 0c: a, Absolute
    # TODO
  end

  # Transfer the Stack pointer to the X register
  # Status Register:
  #   7N 6V 51 41 3D 2I 1Z 0C
  #    N,  ,  ,  ,  ,  , Z,
  def tsx(mode)
    # ba: i, Implied
    # TODO
  end

  # Transfer the X register to the Accumulator
  # Status Register:
  #   7N 6V 51 41 3D 2I 1Z 0C
  #    N,  ,  ,  ,  ,  , Z,
  def txa(mode)
    # 8a: i, Implied
    # TODO
  end

  # Transfer the X register to the Stack pointer register
  # Status Register:
  #   7N 6V 51 41 3D 2I 1Z 0C
  #     ,  ,  ,  ,  ,  ,  ,
  def txs(mode)
    # 9a: i, Implied
    # TODO
  end

  # Transfer Y register to the Accumulator
  # Status Register:
  #   7N 6V 51 41 3D 2I 1Z 0C
  #    N,  ,  ,  ,  ,  , Z,
  def tya(mode)
    # 98: i, Implied
    # TODO
  end

  # WAit for Interrupt
  # Status Register:
  #   7N 6V 51 41 3D 2I 1Z 0C
  #     ,  ,  ,  ,  ,  ,  ,
  def wai(mode)
    # cb: I,
    # TODO
  end

  # ==== P Flags ====

  P_CARRY        = 1 << 0
  P_ZERO         = 1 << 1
  P_IRQB_DISABLE = 1 << 2
  P_DECIMAL_MODE = 1 << 3
  P_BRK          = 1 << 4
  P_OVERFLOW     = 1 << 6
  P_NEGATIVE     = 1 << 7

  # - Processor Status
  #      7 6 5 4 3 2 1 0
  #    [ N V 1 B D I Z C ]
  #      | |   | | | | ^-- Carry          1 = true
  #      | |   | | | ^---- Zero           1 = true
  #      | |   | | ^------ IRQB Disable   1 = Disable
  #      | |   | ^-------- Decimal Mode   1 = true
  #      | |   ^---------- BRK            1 = BRK, 0 = IRQB
  #      | ^-------------- Overflow       1 = true
  #      ^---------------- Negative       1 = true

  def flag?(n)
    p & n == n
  end

  def flag_set(n, set = true)
    @p |= n
    @p ^= n unless set
  end
end
