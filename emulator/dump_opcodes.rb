#!/usr/bin/env ruby

require 'json'

op_codes = [
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

mnemonics = {}
modes = {}

op_codes.each.with_index do |row, y|
  row.each.with_index do |mnemonic, x|
    next unless mnemonic
    code = "#{y.to_s(16)}#{x.to_s(16)}" #.to_i(16)
    mnemonic, mode = mnemonic.split(' ')
    mnemonics[mnemonic] ||= []
    mnemonics[mnemonic] << code
    modes[mode] ||= []
    modes[mode] << code
  end
end

puts JSON.pretty_generate(mnemonics)
puts JSON.pretty_generate(modes)
