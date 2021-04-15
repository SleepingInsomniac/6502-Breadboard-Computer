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
  contexts = info[:modes].map do |i|
    <<~RUBY
      context "with addressing mode: '#{i[:symbol]}, #{i[:mode]}'" do
          # op code: #{i[:hex]}
        end
    RUBY
  end

  puts <<~RUBY
    describe "#{mnemonic}" do
      # Status Register:
      #   7N 6V 51 41 3D 2I 1Z 0C
      #   #{info[:status]}

      #{contexts.map(&:chomp).join("\n\n  ")}
    end

  RUBY
end
