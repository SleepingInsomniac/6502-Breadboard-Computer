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
    ['BRK s', 'ORA (zp,x)', nil,        nil, 'TSB zp',   'ORA zp',   'ASL zp',   'RMB0 zp', 'PHP s', 'ORA #',   'ASL A', nil,     'TSB a',     'ORA a',   'ASL a',   'BBR0 r'], # 0
    ['BPL r', 'ORA (zp),y', 'ORA (zp)', nil, 'TRB zp',   'ORA zp,x', 'ASL zp,x', 'RMB1 zp', 'CLC i', 'ORA a,y', 'INC A', nil,     'TRB a',     'ORA a,x', 'ASL a,x', 'BBR1 r'], # 1
    ['JSR a', 'AND (zp,x)', nil,        nil, 'BIT zp',   'AND zp',   'ROL zp',   'RMB2 zp', 'PLP s', 'AND #',   'ROL A', nil,     'BIT a',     'AND a',   'ROL a',   'BBR2 r'], # 2
    ['BMI r', 'AND (zp),y', 'AND (zp)', nil, 'BIT zp,x', 'AND zp,x', 'ROL zp,x', 'RMB3 zp', 'SEC I', 'AND a,y', 'DEC A', nil,     'BIT a,x',   'AND a,x', 'ROL a,x', 'BBR3 r'], # 3
    ['RTI s', 'EOR (zp,x)', nil,        nil, nil,        'EOR zp',   'LSR zp',   'RMB4 zp', 'PHA s', 'EOR #',   'LSR A', nil,     'JMP a',     'EOR a',   'LSR a',   'BBR4 r'], # 4
    ['BVC r', 'EOR (zp),y', 'EOR (zp)', nil, nil,        'EOR zp,x', 'LSR zp,x', 'RMB5 zp', 'CLI i', 'EOR a,y', 'PHY s', nil,     nil,         'EOR a,x', 'LSR a,x', 'BBR5 r'], # 5
    ['RTS s', 'ADC (zp,x)', nil,        nil, 'STZ zp',   'ADC zp',   'ROR zp',   'RMB6 zp', 'PLA s', 'ADC #',   'ROR A', nil,     'JMP (a)',   'ADC a',   'ROR a',   'BBR6 r'], # 6
    ['BVS r', 'ADC (zp),y', 'ADC (zp)', nil, 'STZ zp,x', 'ADC zp,x', 'ROR zp,x', 'RMB7 zp', 'SEI i', 'ADC a,y', 'PLY s', nil,     'JMP (a.x)', 'ADC a,x', 'ROR a,x', 'BBR7 r'], # 7
    ['BRA r', 'STA (zp,x)', nil,        nil, 'STY zp',   'STA zp',   'STX zp',   'SMB0 zp', 'DEY i', 'BIT #',   'TXA i', nil,     'STY a',     'STA a',   'STX a',   'BBS0 r'], # 8
    ['BCC r', 'STA (zp),y', 'STA (zp)', nil, 'STY zp,x', 'STA zp,x', 'STX zp,y', 'SMB1 zp', 'TYA i', 'STA a,y', 'TXS i', nil,     'STZ a',     'STA a,x', 'STZ a,x', 'BBS1 r'], # 9
    ['LDY #', 'LDA (zp,x)', 'LDX #',    nil, 'zp LDY',   'LDA zp',   'LDX zp',   'SMB2 zp', 'TAY i', 'LDA #',   'TAX i', nil,     'LDY A',     'LDA a',   'LDX a',   'BBS2 r'], # A
    ['BCS r', 'LDA (zp),y', 'LDA (zp)', nil, 'LDY zp,x', 'LDA zp,x', 'LDX zp,y', 'SMB3 zp', 'CLV i', 'LDA A,y', 'TSX i', nil,     'LDY a,x',   'LDA a,x', 'LDX a,y', 'BBS3 r'], # B
    ['CPY #', 'CMP (zp,x)', nil,        nil, 'zp CPY',   'CMP zp',   'DEC zp',   'SMB4 zp', 'INY i', 'CMP #',   'DEX i', 'WAI I', 'CPY a',     'CMP a',   'DEC a',   'BBS4 r'], # C
    ['BNE r', 'CMP (zp),y', 'CMP (zp)', nil, nil,        'CMP zp,x', 'DEC zp,x', 'SMB5 zp', 'CLD i', 'CMP a,y', 'PHX s', 'STP I', nil,         'CMP a,x', 'DEC a,x', 'BBS5 r'], # D
    ['CPX #', 'SBC (zp,x)', nil,        nil, 'CPX zp',   'SBC zp',   'INC zp',   'SMB6 zp', 'INX i', 'SBC #',   'NOP i', nil,     'CPX a',     'SBC a',   'INC a',   'BBS6 r'], # E
    ['BEQ r', 'SBC (zp),y', 'SBC (zp)', nil, nil,        'SBC zp,x', 'INC zp,x', 'SMB7 zp', 'SED i', 'SBC a,y', 'PLX s', nil,     nil,         'SBC a,x', 'INC a,x', 'BBS7 r'], # F
  ]

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
  # - @param rwb         : Bus - 1
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

  def mnemonic(opcode)
    y, x = opcode.to_s(16).chars.map { |c| c.to_i(16) }
    OP_CODES[y][x]
  end

  def addressing_mode(mnemonic)
    ADDRESSING_MODES[mnemonic]
  end
end
