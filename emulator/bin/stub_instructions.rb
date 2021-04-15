#!/usr/bin/env ruby

require 'json'

require_relative '../lib/cpu_65c02/op_codes'
require_relative '../lib/cpu_65c02/addressing_modes'
require_relative '../lib/cpu_65c02/instructions'

mnemonics = {}

CPU65c02::OP_CODES.each.with_index do |mnemonic_mode, code|
  next unless mnemonic_mode
  mnemonic, mode = mnemonic_mode.split(' ')
  istr = CPU65c02::INSTRUCTIONS[mnemonic] || CPU65c02::INSTRUCTIONS[mnemonic[0..-2]]
  mnemonics[mnemonic] ||= {
    modes: [],
    **istr,
  }
  mnemonics[mnemonic][:modes] << {
    symbol: mode,
    mode: CPU65c02::ADDRESSING_MODES[mode],
    code: code,
    hex: "%02x" % code,
  }
end

mnemonics.sort.each do |mnemonic, info|
  modes_info = info[:modes].map do |i|
    "# #{i[:hex]}: #{i[:symbol]}, #{i[:mode]}"
  end

  puts <<~RUBY
    # #{info[:desc]}
    # Status Register:
    #   7N 6V 51 41 3D 2I 1Z 0C
    #   #{info[:status]}
    def #{mnemonic.downcase}(mode)
      #{modes_info.join("\n  ")}
      # TODO
    end

  RUBY
end
