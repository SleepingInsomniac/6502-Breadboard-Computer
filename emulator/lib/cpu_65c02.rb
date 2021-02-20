class CPU65c02
  VECTORS = {
    BRK:  0xFFFE,
    IRKB: 0xFFFE,
    RESB: 0xFFFC,
    NMIB: 0xFFFA,
  }

  ADDRESSING_MODES = {
    'a'      => 'Absolute',
    '(a,x)'  => 'Absolute Indexed Indirect',
    'a,x'    => 'Absolute Indexed with X',
    'a,y'    => 'Absolute Indexed with Y',
    '(a)'    => 'Absolute Indirect',
    'A'      => 'Accumulator',
    '#'      => 'Immediate',
    'i'      => 'Implied',
    'r'      => 'Program Counter Relative',
    's'      => 'Stack',
    'zp'     => 'Zero Page',
    '(zp,x)' => 'Zero Page Indexed Indirect',
    'zp,x'   => 'Zero Page Indexed with X',
    'zp,y'   => 'Zero Page Indexed with Y',
    '(zp)'   => 'Zero Page Indirect',
    '(zp),y' => 'Zero Page Indirect Indexed with Y',
  }

  INSTRUCTIONS = {
    'ADC' =>  'ADd memory to accumulator with Carry',
    'AND' =>  '"AND" memory with accumulator',
    'ASL' =>  'Arithmetic Shift one bit Left, memory or accumulator',
    'BBR' =>  'Branch on Bit Reset',
    'BBS' =>  'Branch of Bit Set',
    'BCC' =>  'Branch on Carry Clear (Pc=0)',
    'BCS' =>  'Branch on Carry Set (Pc=1)',
    'BEQ' =>  'Branch if EQual (Pz=1)',
    'BIT' =>  'BIt Test',
    'BMI' =>  'Branch if result MInus (Pn=1)',
    'BNE' =>  'Branch if Not Equal (Pz=0)',
    'BPL' =>  'Branch if result PLus (Pn=0)',
    'BRA' =>  'BRanch Always',
    'BRK' =>  'BReaK instruction',
    'BVC' =>  'Branch on oVerflow Clear (Pv=0)',
    'BVS' =>  'Branch on oVerflow Set (Pv=1)',
    'CLC' =>  'CLear Cary flag',
    'CLD' =>  'CLear Decimal mode',
    'CLI' =>  'CLear Interrupt disable bit',
    'CLV' =>  'CLear oVerflow flag',
    'CMP' =>  'CoMPare memory and accumulator',
    'CPX' =>  'ComPare memory and X register',
    'CPY' =>  'ComPare memory and Y register',
    'DEC' =>  'DECrement memory or accumulate by one',
    'DEX' =>  'DEcrement X by one',
    'DEY' =>  'DEcrement Y by one',
    'EOR' =>  '"Exclusive OR" memory with accumulate',
    'INC' =>  'INCrement memory or accumulate by one',
    'INX' =>  'INcrement X register by one',
    'INY' =>  'INcrement Y register by one',
    'JMP' =>  'JuMP to new location',
    'JSR' =>  'Jump to new location Saving Return (Jump to SubRoutine)',
    'LDA' =>  'LoaD Accumulator with memory',
    'LDX' =>  'LoaD the X register with memory',
    'LDY' =>  'LoaD the Y register with memory',
    'LSR' =>  'Logical Shift one bit Right memory or accumulator',
    'NOP' =>  'No OPeration',
    'ORA' =>  '"OR" memory with Accumulator',
    'PHA' =>  'PusH Accumulator on stack',
    'PHP' =>  'PusH Processor status on stack',
    'PHX' =>  'PusH X register on stack',
    'PHY' =>  'PusH Y register on stack',
    'PLA' =>  'PuLl Accumulator from stack',
    'PLP' =>  'PuLl Processor status from stack',
    'PLX' =>  'PuLl X register from stack',
    'PLY' =>  'PuLl Y register from stack',
    'RMB' =>  'Reset Memory Bit',
    'ROL' =>  'ROtate one bit Left memory or accumulator',
    'ROR' =>  'ROtate one bit Right memory or accumulator',
    'RTI' =>  'ReTurn from Interrupt',
    'RTS' =>  'ReTurn from Subroutine',
    'SBC' =>  'SuBtract memory from accumulator with borrow (Carry bit)',
    'SEC' =>  'SEt Carry',
    'SED' =>  'SEt Decimal mode',
    'SEI' =>  'SEt Interrupt disable status',
    'SMB' =>  'Set Memory Bit',
    'STA' =>  'STore Accumulator in memory',
    'STP' =>  'SToP mode',
    'STX' =>  'STore the X register in memory',
    'STY' =>  'STore the Y register in memory',
    'STZ' =>  'STore Zero in memory',
    'TAX' =>  'Transfer the Accumulator to the X register',
    'TAY' =>  'Transfer the Accumulator to the Y register',
    'TRB' =>  'Test and Reset memory Bit',
    'TSB' =>  'Test and Set memory Bit',
    'TSX' =>  'Transfer the Stack pointer to the X register',
    'TXA' =>  'Transfer the X register to the Accumulator',
    'TXS' =>  'Transfer the X register to the Stack pointer register',
    'TYA' =>  'Transfer Y register to the Accumulator',
    'WAI' =>  'WAit for Interrupt',
  }

  OP_CODES = [
  #  0        1             2           3    4           5           6           7           8       9          A        B        C            D          E          F
    'BRK s', 'ORA (zp,x)', nil,        nil, 'TSB zp',   'ORA zp',   'ASL zp',   'RMB0 zp', 'PHP s', 'ORA #',   'ASL A', nil,     'TSB a',     'ORA a',   'ASL a',   'BBR0 r', # 0
    'BPL r', 'ORA (zp),y', 'ORA (zp)', nil, 'TRB zp',   'ORA zp,x', 'ASL zp,x', 'RMB1 zp', 'CLC i', 'ORA a,y', 'INC A', nil,     'TRB a',     'ORA a,x', 'ASL a,x', 'BBR1 r', # 1
    'JSR a', 'AND (zp,x)', nil,        nil, 'BIT zp',   'AND zp',   'ROL zp',   'RMB2 zp', 'PLP s', 'AND #',   'ROL A', nil,     'BIT a',     'AND a',   'ROL a',   'BBR2 r', # 2
    'BMI r', 'AND (zp),y', 'AND (zp)', nil, 'BIT zp,x', 'AND zp,x', 'ROL zp,x', 'RMB3 zp', 'SEC I', 'AND a,y', 'DEC A', nil,     'BIT a,x',   'AND a,x', 'ROL a,x', 'BBR3 r', # 3
    'RTI s', 'EOR (zp,x)', nil,        nil, nil,        'EOR zp',   'LSR zp',   'RMB4 zp', 'PHA s', 'EOR #',   'LSR A', nil,     'JMP a',     'EOR a',   'LSR a',   'BBR4 r', # 4
    'BVC r', 'EOR (zp),y', 'EOR (zp)', nil, nil,        'EOR zp,x', 'LSR zp,x', 'RMB5 zp', 'CLI i', 'EOR a,y', 'PHY s', nil,     nil,         'EOR a,x', 'LSR a,x', 'BBR5 r', # 5
    'RTS s', 'ADC (zp,x)', nil,        nil, 'STZ zp',   'ADC zp',   'ROR zp',   'RMB6 zp', 'PLA s', 'ADC #',   'ROR A', nil,     'JMP (a)',   'ADC a',   'ROR a',   'BBR6 r', # 6
    'BVS r', 'ADC (zp),y', 'ADC (zp)', nil, 'STZ zp,x', 'ADC zp,x', 'ROR zp,x', 'RMB7 zp', 'SEI i', 'ADC a,y', 'PLY s', nil,     'JMP (a,x)', 'ADC a,x', 'ROR a,x', 'BBR7 r', # 7
    'BRA r', 'STA (zp,x)', nil,        nil, 'STY zp',   'STA zp',   'STX zp',   'SMB0 zp', 'DEY i', 'BIT #',   'TXA i', nil,     'STY a',     'STA a',   'STX a',   'BBS0 r', # 8
    'BCC r', 'STA (zp),y', 'STA (zp)', nil, 'STY zp,x', 'STA zp,x', 'STX zp,y', 'SMB1 zp', 'TYA i', 'STA a,y', 'TXS i', nil,     'STZ a',     'STA a,x', 'STZ a,x', 'BBS1 r', # 9
    'LDY #', 'LDA (zp,x)', 'LDX #',    nil, 'zp LDY',   'LDA zp',   'LDX zp',   'SMB2 zp', 'TAY i', 'LDA #',   'TAX i', nil,     'LDY A',     'LDA a',   'LDX a',   'BBS2 r', # A
    'BCS r', 'LDA (zp),y', 'LDA (zp)', nil, 'LDY zp,x', 'LDA zp,x', 'LDX zp,y', 'SMB3 zp', 'CLV i', 'LDA A,y', 'TSX i', nil,     'LDY a,x',   'LDA a,x', 'LDX a,y', 'BBS3 r', # B
    'CPY #', 'CMP (zp,x)', nil,        nil, 'zp CPY',   'CMP zp',   'DEC zp',   'SMB4 zp', 'INY i', 'CMP #',   'DEX i', 'WAI I', 'CPY a',     'CMP a',   'DEC a',   'BBS4 r', # C
    'BNE r', 'CMP (zp),y', 'CMP (zp)', nil, nil,        'CMP zp,x', 'DEC zp,x', 'SMB5 zp', 'CLD i', 'CMP a,y', 'PHX s', 'STP I', nil,         'CMP a,x', 'DEC a,x', 'BBS5 r', # D
    'CPX #', 'SBC (zp,x)', nil,        nil, 'CPX zp',   'SBC zp',   'INC zp',   'SMB6 zp', 'INX i', 'SBC #',   'NOP i', nil,     'CPX a',     'SBC a',   'INC a',   'BBS6 r', # E
    'BEQ r', 'SBC (zp),y', 'SBC (zp)', nil, nil,        'SBC zp,x', 'INC zp,x', 'SMB7 zp', 'SED i', 'SBC a,y', 'PLX s', nil,     nil,         'SBC a,x', 'INC a,x', 'BBS7 r', # F
  ]

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
    mnemonic, mode = mnemonic(read)
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

  # Add with carry
  def adc(mode) # N V Z C
    value = operand(mode)
    flag_set P_NEGATIVE, (@a + value)[7] == 1
    flag_set P_OVERFLOW, (@a + value)[7] == 1 && @a[7] == 1 && value[7] == 1
    flag_set P_ZERO,     (@a + value) & 0xFF == 0
    flag_set P_CARRY,    @a > 0xFF
    @a = (@a + value) & 0xFF
  end

  # And accumulator with memory
  def and(mode) # N Z
    @a &= operand(mode)
  end

  # Shift left one bit
  def asl(mode) # N Z C
    if mode == 'Implied'
      @a <<= 1
      flag_set(P_CARRY, @a[8])
      @a &= 0xF
    else
      address = operand(mode)
      memory = read(address)
      memory <<= 1
      flag_set(P_CARRY, memory[8])
      write(memory, to: address)
    end
  end

  # Branch bit reset
  def bbr(mode)
    # TODO 0-7
  end

  # Branch bit set
  def bbs(mode)
    # TODO : 0-7
  end

  # Branch carry clear
  def bcc(mode)
    @pc = addr unless flag?(P_CARRY)
  end

  # Branch carry set
  def bcs(mode)
    @pc = operand(mode) if flag?(P_CARRY)
  end

  # Branch if equal
  def beq(mode)
    @pc = operand(mode) if flag?(P_ZERO)
  end

  # Bit test
  def bit(mode) # N:M7 V:M6 Z
    value = operand(mode)
    value ^= @a
    # Does not affect the NV flags
    # This is the only instruction with addressing dependent flags
    if mode != "Immediate"
      flag_set P_NEGATIVE, value[7] == 1
      flag_set P_OVERFLOW, value[6] == 1 # TODO: check if overflow 2's compliment correctly?
    end
    flag_set P_ZERO,     value & @a == 0
  end

  # Branch on result minus
  def bmi(mode)
    @pc = operand(mode) if flag?(P_NEGATIVE)
  end

  # Branch on result not zero
  def bne(mode)
    @pc = operand(mode) unless flag?(P_ZERO)
  end

  # Branch on result plus
  def bpl(mode)
    @pc = operand(mode) unless flag?(P_NEGATIVE)
  end

  def bra(mode)
    @pc = operand(mode)
  end

  def brk(mode) # B D I
    flag_set(P_BRK,          true)
    flag_set(P_DECIMAL_MODE, false)
    flag_set(P_IRQB_DISABLE, true)
  end

  def bvc(mode)
    @pc = operand(mode) unless flag?(P_OVERFLOW)
  end

  def bvs(mode)
    @pc = operand(mode) if flag?(P_OVERFLOW)
  end

  def clc(mode)
    flag_set(P_CARRY, 0)
  end

  def cld(mode)
    flag_set(P_DECIMAL_MODE, 0)
  end

  def cli(mode)
    flag_set(P_IRQB_DISABLE, 0)
  end

  def clv(mode)
    flag_set(P_OVERFLOW, 0)
  end

  def cmp(mode)
  end

  def cpx(mode)
  end

  def cpy(mode)
  end

  def dec(mode)
  end

  def dex(mode)
  end

  def dey(mode)
  end

  def eor(mode)
  end

  def inc(mode)
  end

  def inx(mode)
  end

  def iny(mode)
  end

  def jmp(mode)
  end

  def jsr(mode)
    write(@p,        to: @s += 1) # Store processor status on stack
    write(@pc & 0xF, to: @s += 1) # Store program counter (low order)
    write(@pc >> 8,  to: @s += 1) # Store PC (High order)
    @pc = operand(mode) # Set program counter
    flag_set P_ZERO, @pc.zero? # datasheet says these get set?
    flag_set P_NEGATIVE, @pc[15] == 1 # TODO: Is this even right??
  end

  def lda(mode)
    @a = operand(mode) & 0xFF
    flag_set P_ZERO,     @a.zero?
    flag_set P_NEGATIVE, @a[7] == 1
  end

  def ldx(mode)
    @x = operand(mode) & 0xFF
    flag_set P_ZERO      @x.zero?
    flag_set P_NEGATIVE, @x[7] == 1
  end

  def ldy(mode)
    @y = operand(mode) & 0xFF
    flag_set P_ZERO,     @y.zero?
    flag_set P_NEGATIVE, @y[7] == 1
  end

  def lsr(mode)
  end

  def nop(mode)
  end

  def ora(mode)
  end

  def pha(mode)
  end

  def php(mode)
  end

  def phx(mode)
  end

  def phy(mode)
  end

  def pla(mode)
  end

  def plp(mode)
  end

  def plx(mode)
  end

  def ply(mode)
  end

  def rmb(mode)
  end

  def rol(mode)
  end

  def ror(mode)
  end

  def rti(mode)
  end

  def rts(mode)
  end

  def sbc(mode)
  end

  def sec(mode)
  end

  def sed(mode)
  end

  def sei(mode)
  end

  def smb(mode)
  end

  def sta(mode)
  end

  def stp(mode)
  end

  def stx(mode)
  end

  def sty(mode)
  end

  def stz(mode)
  end

  def tax(mode)
  end

  def tay(mode)
  end

  def trb(mode)
  end

  def tsb(mode)
  end

  def tsx(mode)
  end

  def txa(mode)
  end

  def txs(mode)
  end

  def tya(mode)
  end

  def wai(mode)
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
