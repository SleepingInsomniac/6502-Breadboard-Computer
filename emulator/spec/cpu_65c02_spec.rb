require_relative "../cpu_65c02.rb"
require_relative "../bus.rb"
require_relative "../memory"
require_relative "../breadboard"

require 'stringio'

RSpec.describe CPU65c02 do
  let(:breadboard) { Breadboard.new }
  let!(:address_bus) { Bus.new(16) }
  let!(:data_bus) { Bus.new(8) }
  let!(:rwb) { Bus.new(1) }

  let(:bus_connections) do
    {
      address_bus: address_bus,
      data_bus: data_bus,
      rwb: rwb,
    }
  end

  let!(:cpu) do
    CPU65c02.new(**bus_connections, breadboard: breadboard)
  end

  let!(:memory) do
    Memory.new(
      **bus_connections,
      enable: 0x4000,
      address_mask: 0x3FFF,
      file: StringIO.new('', 'r+b'),
      size: 0xFF
    )
  end

  describe "#mnemonic" do
    it "returns the cooresponding mnemonic for a given opcode" do
      expect(cpu.mnemonic(0xa9)).to eq(['LDA', '#'])
    end
  end

  describe "#read" do
    it "reads the current byte and increments the address" do
      memory.write(0x4000, 0xaa) # Set memory address 4000 to aa
      breadboard.on_update { memory.update }

      breadboard.update do
        rwb.write(1) # Set read mode
        cpu.address = 0x4000
      end

      expect(cpu.read).to eq(0xaa)
      expect(address_bus.read).to eq(0x4001)
    end
  end

  describe "#operand" do
    it "returns a 2 byte address for Absolute a addressing" do
      rom = Memory.new(
        **bus_connections,
        enable: 0x8000, # Enable for addresses > $8000
        address_mask: 0x7FFF,
        file: StringIO.new("\xAD\x02\x40"),
        size: 0xF,
        read_only: true
      )

      breadboard.on_update do
        memory.update
        rom.update
      end

      # memory.write(0x4002, 0xAA) # Store value
      breadboard.update do
        rwb.write(1) # Read mode
        cpu.address = 0x8000 # Set to location of rom
      end

      instruction, mode = cpu.mnemonic(cpu.read)

      expect(instruction).to eq('LDA')
      expect(mode).to eq('a')
      expect(cpu.operand(mode)).to eq(0x4002)
    end
  end
end
