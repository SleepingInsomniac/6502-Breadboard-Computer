#!/usr/bin/env ruby

noops = [0xea] * 32768

File.open("noop.bin", 'wb') do |file|
  file.write noops.pack('C*')
end
