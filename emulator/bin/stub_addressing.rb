#!/usr/bin/env ruby

require_relative '../lib/cpu_65c02/addressing_modes'

puts "case mode"
CPU65c02::ADDRESSING_MODES.sort{ |(_, v1), (_, v2)| v1 <=> v2 }.each do |name, desc|
  print "when #{"'#{name}'".ljust(10)} then".ljust(30)
  puts "# #{desc}"
end
puts "end"
