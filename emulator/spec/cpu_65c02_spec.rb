require_relative "../cpu_65c02.rb"
require_relative "../bus.rb"
require_relative "../memory"
require_relative "../clock"

require 'stringio'

RSpec.describe CPU65c02 do
  let(:clock) { Clock.new }
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
    CPU65c02.new(**bus_connections, clock: clock)
  end

  let!(:memory) do
    Memory.new(
      **bus_connections,
      addresses: 0x4000..0x5FFF,
      file: StringIO.new('', 'r+b')
    )
  end

  def make_rom(data = [])
    Memory.new(
      **bus_connections,
      addresses: 0x8000..(0x8000 + data.length),
      file: StringIO.new(data.pack('C*')),
      read_only: true
    )
  end

  describe "#mnemonic" do
    it "returns the cooresponding mnemonic for a given opcode" do
      expect(cpu.mnemonic(0xa9)).to eq(['LDA', '#'])
    end
  end

  describe "#read_next" do
    it "reads the current byte and increments the address" do
      memory.write(0x4001, 0xaa) # Set memory address 4000 to aa
      clock.on_tick { memory.update }

      clock.tick do
        rwb.write(1) # Set read mode
        cpu.address = 0x4000 # Set program counter
      end

      expect(cpu.read_next).to eq(0xaa)
      expect(address_bus.read).to eq(0x4001)
    end
  end

  describe "Absolute Addressing" do
    it "returns a 2 byte address for Absolute a addressing" do
      rom = make_rom([0xAD, 0x03, 0x80, 0x42])

      clock.on_tick do
        memory.update
        rom.update
      end

      # memory.write(0x4002, 0xAA) # Store value
      clock.tick do
        rwb.write(1) # Read mode
        cpu.address = 0x8000 # Set to location of rom
      end

      instruction, mode = cpu.mnemonic(cpu.read(0x8000))

      expect(instruction).to eq('LDA')
      expect(mode).to eq('a')
      expect(cpu.operand(mode)).to eq(0x42)
    end
  end

  describe "Absolute Indexed Indirect Addressing" do
    it "returns 2 byte address at pointer + x reg" do
      rom = make_rom([0x7C, 0x00, 0x80, 0x42])
      clock.on_tick { rom.update }
      cpu.x = 0x03
      cpu.address = 0x8000
      instruction, mode = cpu.mnemonic(cpu.read(0x8000))
      expect(instruction).to eq('JMP')
      expect(mode).to eq('(a,x)')
      expect(cpu.operand(mode)).to eq(0x42)
    end
  end

  describe "Absolute Indexed with X Addressing"
  describe "Absolute Indexed with Y Addressing"
  describe "Absolute Indirect Addressing"
  describe "Accumulator Addressing"
  describe "Immediate Addressing"
  describe "Implied Addressing"
  describe "Program Counter Relative Addressing"
  describe "Stack Addressing"
  describe "Zero Page Addressing"
  describe "Zero Page Indexed Indirect Addressing"
  describe "Zero Page Indexed with X Addressing"
  describe "Zero Page Indexed with Y Addressing"
  describe "Zero Page Indirect Addressing"
  describe "Zero Page Indirect Indexed with Y Addressing"
end
