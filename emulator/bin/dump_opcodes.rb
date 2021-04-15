#!/usr/bin/env ruby

require 'json'

require_relative '../lib/cpu_65c02/op_codes'
require_relative '../lib/cpu_65c02/addressing_modes'
require_relative '../lib/cpu_65c02/instructions'

op_codes = {}

CPU65c02::OP_CODES.each.with_index do |mnemonic, code|
  next unless mnemonic
  mnemonic, mode = mnemonic.split(' ')
  op_codes[code] = {
    mnemonic: mnemonic,
    mode: mode,
    addressing: CPU65c02::ADDRESSING_MODES[mode],
    description: CPU65c02::INSTRUCTIONS[mnemonic],
    hex: "%02x" % code
  }
end

puts JSON.pretty_generate(op_codes)
