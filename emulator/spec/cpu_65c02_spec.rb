require_relative "../lib/cpu_65c02.rb"
require_relative "../lib/bus.rb"
require_relative "../lib/memory"
require_relative "../lib/clock"

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

  # Convert an array of hex strings into a memory representation
  def make_rom(data = [])
    Memory.new(
      **bus_connections,
      addresses: 0x8000..(0x8000 + data.length),
      file: StringIO.new(data.map{ |b| b.to_i(16) }.pack('C*')),
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
      rom = make_rom(%w[AD 03 80 42])

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
      expect(cpu.operand(mode)).to eq(0x8003)
      expect(clock.cycles).to eq(4)
    end
  end

  describe "Absolute Indexed Indirect Addressing" do
    it "returns 2 byte address at pointer + x reg" do
      rom = make_rom(%w[7C 00 80 05 80])
      clock.on_tick { rom.update }
      cpu.x = 0x03
      cpu.address = 0x8000
      instruction, mode = cpu.mnemonic(cpu.read(0x8000))
      expect(instruction).to eq('JMP')
      expect(mode).to eq('(a,x)')
      expect(cpu.operand(mode)).to eq(0x8005)
      # expect(clock.cycles).to eq(6) # TODO
    end
  end

  describe "Absolute Indexed with X Addressing" do
    it "returns 2 bytes ofset by x" do
      rom = make_rom(%w[BC 00 80])
      clock.on_tick { rom.update }
      cpu.x = 0x03
      cpu.address = 0x8000
      instruction, mode = cpu.mnemonic(cpu.read(0x8000))
      expect(instruction).to eq('LDY')
      expect(mode).to eq('a,x')
      expect(cpu.operand(mode)).to eq(0x8003)
    end
  end

  describe "Absolute Indexed with Y Addressing" do
    it "returns 2 bytes ofset by y" do
      rom = make_rom(%w[BE 00 80])
      clock.on_tick { rom.update }
      cpu.y = 0x03
      cpu.address = 0x8000
      instruction, mode = cpu.mnemonic(cpu.read(0x8000))
      expect(instruction).to eq('LDX')
      expect(mode).to eq('a,y')
      expect(cpu.operand(mode)).to eq(0x8003)
    end
  end

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

  it "disassembles a simple program" do
    rom = make_rom(%w[a9 ff 8d 02 60 a9 55 8d 00 60 6a 4c 07 80])

    clock.on_tick { rom.update }
    cpu.address = 0x7FFF
    buffer = ""
    6.times do
      instruction, mode = cpu.mnemonic(cpu.read_next)
      buffer << "$#{cpu.pc.to_s(16)}: #{instruction} #{mode}"
      operand = cpu.operand(mode)
      buffer << " $#{operand.to_s(16)}" if operand
      buffer << "\n"
    end
    expect(buffer).to eq(<<~PROG)
      $8000: LDA # $ff
      $8002: STA a $6002
      $8005: LDA # $55
      $8007: STA a $6000
      $800a: ROR A $0
      $800b: JMP a $8007
    PROG
  end

  describe "CPU Instructions" do
    describe 'ADC'
    describe 'AND'
    describe 'ASL'
    describe 'BBR'
    describe 'BBS'
    describe 'BCC'
    describe 'BCS'
    describe 'BEQ'
    describe 'BIT'
    describe 'BMI'
    describe 'BNE'
    describe 'BPL'
    describe 'BRA'
    describe 'BRK'
    describe 'BVC'
    describe 'BVS'
    describe 'CLC'
    describe 'CLD'
    describe 'CLI'
    describe 'CLV'

    describe "CMP" do
      context "with immediate addressing" do
        it "sets the zero flag when memory matches accumulator" do
          # lda #42 - a9 2a
          # cmp #42 - c9 2a
          rom = make_rom(%w[a9 2a c9 2a])
          clock.on_tick { rom.update }
          cpu.address = 0x8000 # Set address to our rom location
          cpu.step
          expect(cpu.a).to eq(42)
        end
      end
    end

    describe 'CPX'
    describe 'CPY'
    describe 'DEC'
    describe 'DEX'
    describe 'DEY'
    describe 'EOR'
    describe 'INC'
    describe 'INX'
    describe 'INY'
    describe 'JMP'
    describe 'JSR'

    describe "LDA" do
      context "with immediate addressing" do
        it "loads the a register" do
          rom = make_rom(%w[a9 42]) # lda #$42
          clock.on_tick { rom.update }
          cpu.address = 0x8000 # ROM
          cpu.step
          expect(cpu.a).to eq(0x42)
        end
      end
    end

    describe 'LDX'
    describe 'LDY'
    describe 'LSR'
    describe 'NOP'
    describe 'ORA'
    describe 'PHA'
    describe 'PHP'
    describe 'PHX'
    describe 'PHY'
    describe 'PLA'
    describe 'PLP'
    describe 'PLX'
    describe 'PLY'
    describe 'RMB'
    describe 'ROL'
    describe 'ROR'
    describe 'RTI'
    describe 'RTS'
    describe 'SBC'
    describe 'SEC'
    describe 'SED'
    describe 'SEI'
    describe 'SMB'
    describe 'STA'
    describe 'STP'
    describe 'STX'
    describe 'STY'
    describe 'STZ'
    describe 'TAX'
    describe 'TAY'
    describe 'TRB'
    describe 'TSB'
    describe 'TSX'
    describe 'TXA'
    describe 'TXS'
    describe 'TYA'
    describe 'WAI'
  end
end
