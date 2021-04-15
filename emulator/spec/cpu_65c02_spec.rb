require_relative "../lib/cpu_65c02.rb"
require_relative "../lib/bus.rb"
require_relative "../lib/memory"
require_relative "../lib/clock"

require 'stringio'
require 'tempfile'
require 'digest/sha1'
require 'shellwords'

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
      addresses: 0x0000..0x5FFF,
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

  def assemble_rom(asm, file_name = nil)
    data = assemble(asm, file_name)
    Memory.new(
      **bus_connections,
      addresses: 0x8000..(0x8000 + data.length),
      file: StringIO.new(data),
      read_only: true
    )
  end

  def assemble(prog, file_name = nil)
    file_name ||= Digest::SHA1.hexdigest(prog)
    fixture = "spec/fixtures/#{file_name}.hex"
    unless File.exist?(fixture)
      file = Tempfile.new('spec.s')
      file.write(prog)
      file.close
      `vasm6502_oldstyle -Fbin -dotdir #{file.path} -o #{Shellwords.shellescape(fixture)}`
    end
    File.read(fixture)
  end

  def mem_set(memory, map)
    map.each { |(addr, val)| memor.write(addr, val) }
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
      instruction, mode = cpu.mnemonic(cpu.read(0x8000))
      expect(instruction).to eq('JMP')
      expect(mode).to eq('(a,x)')
      cpu.address = 0x8000
      expect(cpu.argument(mode)).to eq(0x8003)
      # expect(clock.cycles).to eq(6) # TODO
    end
  end

  describe "'Absolute Indexed with X' a,x Addressing" do
    it "returns 2 bytes ofset by x" do
      rom = assemble_rom(<<~ROM, "'Absolute Indexed with X' a,x Addressing")
          .org $8000
        main:
          ldy $8000, x
          .org $8003
          .byte $42
      ROM
      clock.on_tick { rom.update }
      cpu.x = 0x03
      cpu.address = 0x8000
      instruction, mode = cpu.mnemonic(cpu.read(0x8000))
      expect(instruction).to eq('LDY')
      expect(mode).to eq('a,x')
      expect("%02x" % cpu.argument(mode)).to eq('42')
    end
  end

  describe "Absolute Indexed with Y Addressing" do
    it "returns 2 bytes ofset by y" do
      rom = assemble_rom("  .org $8000\n  ldx $8000,y\n  .org $8003\n  .byte $42")
      clock.on_tick { rom.update }
      cpu.y = 0x03
      cpu.address = 0x8000
      instruction, mode = cpu.mnemonic(cpu.read(0x8000))
      expect(instruction).to eq('LDX')
      expect(mode).to eq('a,y')
      expect(cpu.argument(mode)).to eq(0x42)
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
      $800a: ROR A
      $800b: JMP a $8007
    PROG
  end

  # ==========================
  # = OP Code / Instructions =
  # ==========================

  describe "CPU Instructions" do
    describe "ADC" do
      # Status Register:
      #   7N 6V 51 41 3D 2I 1Z 0C
      #    N, V,  ,  ,  ,  , Z, C

      context "with addressing mode: '(zp,x), Zero Page Indexed Indirect'" do
        # op code: 61
      end

      context "with addressing mode: 'zp, Zero Page'" do
        # op code: 65
      end

      context "with addressing mode: '#, Immediate'" do
        # op code: 69
      end

      context "with addressing mode: 'a, Absolute'" do
        # op code: 6d
      end

      context "with addressing mode: '(zp),y, Zero Page Indirect Indexed with Y'" do
        # op code: 71
      end

      context "with addressing mode: '(zp), Zero Page Indirect'" do
        # op code: 72
      end

      context "with addressing mode: 'zp,x, Zero Page Indexed with X'" do
        # op code: 75
      end

      context "with addressing mode: 'a,y, Absolute Indexed with Y'" do
        # op code: 79
      end

      context "with addressing mode: 'a,x, Absolute Indexed with X'" do
        # op code: 7d
      end
    end

    describe "AND" do
      # Status Register:
      #   7N 6V 51 41 3D 2I 1Z 0C
      #    N,  ,  ,  ,  ,  , Z,

      context "with addressing mode: '(zp,x), Zero Page Indexed Indirect'" do
        # op code: 21
      end

      context "with addressing mode: 'zp, Zero Page'" do
        # op code: 25
      end

      context "with addressing mode: '#, Immediate'" do
        # op code: 29
      end

      context "with addressing mode: 'a, Absolute'" do
        # op code: 2d
      end

      context "with addressing mode: '(zp),y, Zero Page Indirect Indexed with Y'" do
        # op code: 31
      end

      context "with addressing mode: '(zp), Zero Page Indirect'" do
        # op code: 32
      end

      context "with addressing mode: 'zp,x, Zero Page Indexed with X'" do
        # op code: 35
      end

      context "with addressing mode: 'a,y, Absolute Indexed with Y'" do
        # op code: 39
      end

      context "with addressing mode: 'a,x, Absolute Indexed with X'" do
        # op code: 3d
      end
    end

    describe "ASL" do
      # Status Register:
      #   7N 6V 51 41 3D 2I 1Z 0C
      #    N,  ,  ,  ,  ,  , Z, C

      context "with addressing mode: 'zp, Zero Page'" do
        # op code: 06
      end

      context "with addressing mode: 'A, Accumulator'" do
        # op code: 0a
      end

      context "with addressing mode: 'a, Absolute'" do
        # op code: 0e
      end

      context "with addressing mode: 'zp,x, Zero Page Indexed with X'" do
        # op code: 16
      end

      context "with addressing mode: 'a,x, Absolute Indexed with X'" do
        # op code: 1e
      end
    end

    describe "BBR0" do
      # Status Register:
      #   7N 6V 51 41 3D 2I 1Z 0C
      #     ,  ,  ,  ,  ,  ,  ,

      context "with addressing mode: 'r, Program Counter Relative'" do
        # op code: 0f
      end
    end

    describe "BBR1" do
      # Status Register:
      #   7N 6V 51 41 3D 2I 1Z 0C
      #     ,  ,  ,  ,  ,  ,  ,

      context "with addressing mode: 'r, Program Counter Relative'" do
        # op code: 1f
      end
    end

    describe "BBR2" do
      # Status Register:
      #   7N 6V 51 41 3D 2I 1Z 0C
      #     ,  ,  ,  ,  ,  ,  ,

      context "with addressing mode: 'r, Program Counter Relative'" do
        # op code: 2f
      end
    end

    describe "BBR3" do
      # Status Register:
      #   7N 6V 51 41 3D 2I 1Z 0C
      #     ,  ,  ,  ,  ,  ,  ,

      context "with addressing mode: 'r, Program Counter Relative'" do
        # op code: 3f
      end
    end

    describe "BBR4" do
      # Status Register:
      #   7N 6V 51 41 3D 2I 1Z 0C
      #     ,  ,  ,  ,  ,  ,  ,

      context "with addressing mode: 'r, Program Counter Relative'" do
        # op code: 4f
      end
    end

    describe "BBR5" do
      # Status Register:
      #   7N 6V 51 41 3D 2I 1Z 0C
      #     ,  ,  ,  ,  ,  ,  ,

      context "with addressing mode: 'r, Program Counter Relative'" do
        # op code: 5f
      end
    end

    describe "BBR6" do
      # Status Register:
      #   7N 6V 51 41 3D 2I 1Z 0C
      #     ,  ,  ,  ,  ,  ,  ,

      context "with addressing mode: 'r, Program Counter Relative'" do
        # op code: 6f
      end
    end

    describe "BBR7" do
      # Status Register:
      #   7N 6V 51 41 3D 2I 1Z 0C
      #     ,  ,  ,  ,  ,  ,  ,

      context "with addressing mode: 'r, Program Counter Relative'" do
        # op code: 7f
      end
    end

    describe "BBS0" do
      # Status Register:
      #   7N 6V 51 41 3D 2I 1Z 0C
      #     ,  ,  ,  ,  ,  ,  ,

      context "with addressing mode: 'r, Program Counter Relative'" do
        # op code: 8f
      end
    end

    describe "BBS1" do
      # Status Register:
      #   7N 6V 51 41 3D 2I 1Z 0C
      #     ,  ,  ,  ,  ,  ,  ,

      context "with addressing mode: 'r, Program Counter Relative'" do
        # op code: 9f
      end
    end

    describe "BBS2" do
      # Status Register:
      #   7N 6V 51 41 3D 2I 1Z 0C
      #     ,  ,  ,  ,  ,  ,  ,

      context "with addressing mode: 'r, Program Counter Relative'" do
        # op code: af
      end
    end

    describe "BBS3" do
      # Status Register:
      #   7N 6V 51 41 3D 2I 1Z 0C
      #     ,  ,  ,  ,  ,  ,  ,

      context "with addressing mode: 'r, Program Counter Relative'" do
        # op code: bf
      end
    end

    describe "BBS4" do
      # Status Register:
      #   7N 6V 51 41 3D 2I 1Z 0C
      #     ,  ,  ,  ,  ,  ,  ,

      context "with addressing mode: 'r, Program Counter Relative'" do
        # op code: cf
      end
    end

    describe "BBS5" do
      # Status Register:
      #   7N 6V 51 41 3D 2I 1Z 0C
      #     ,  ,  ,  ,  ,  ,  ,

      context "with addressing mode: 'r, Program Counter Relative'" do
        # op code: df
      end
    end

    describe "BBS6" do
      # Status Register:
      #   7N 6V 51 41 3D 2I 1Z 0C
      #     ,  ,  ,  ,  ,  ,  ,

      context "with addressing mode: 'r, Program Counter Relative'" do
        # op code: ef
      end
    end

    describe "BBS7" do
      # Status Register:
      #   7N 6V 51 41 3D 2I 1Z 0C
      #     ,  ,  ,  ,  ,  ,  ,

      context "with addressing mode: 'r, Program Counter Relative'" do
        # op code: ff
      end
    end

    describe "BCC" do
      # Status Register:
      #   7N 6V 51 41 3D 2I 1Z 0C
      #     ,  ,  ,  ,  ,  ,  ,

      context "with addressing mode: 'r, Program Counter Relative'" do
        # op code: 90
      end
    end

    describe "BCS" do
      # Status Register:
      #   7N 6V 51 41 3D 2I 1Z 0C
      #     ,  ,  ,  ,  ,  ,  ,

      context "with addressing mode: 'r, Program Counter Relative'" do
        # op code: b0
      end
    end

    describe "BEQ" do
      # Status Register:
      #   7N 6V 51 41 3D 2I 1Z 0C
      #     ,  ,  ,  ,  ,  ,  ,

      context "with addressing mode: 'r, Program Counter Relative'" do
        # op code: f0
      end
    end

    describe "BIT" do
      # Status Register:
      #   7N 6V 51 41 3D 2I 1Z 0C
      #   m7,m6,  ,  ,  ,  , Z,

      context "with addressing mode: 'zp, Zero Page'" do
        # op code: 24
      end

      context "with addressing mode: 'a, Absolute'" do
        # op code: 2c
      end

      context "with addressing mode: 'zp,x, Zero Page Indexed with X'" do
        # op code: 34
      end

      context "with addressing mode: 'a,x, Absolute Indexed with X'" do
        # op code: 3c
      end

      context "with addressing mode: '#, Immediate'" do
        # op code: 89
      end
    end

    describe "BMI" do
      # Status Register:
      #   7N 6V 51 41 3D 2I 1Z 0C
      #     ,  ,  ,  ,  ,  ,  ,

      context "with addressing mode: 'r, Program Counter Relative'" do
        # op code: 30
      end
    end

    describe "BNE" do
      # Status Register:
      #   7N 6V 51 41 3D 2I 1Z 0C
      #     ,  ,  ,  ,  ,  ,  ,

      context "with addressing mode: 'r, Program Counter Relative'" do
        # op code: d0
      end
    end

    describe "BPL" do
      # Status Register:
      #   7N 6V 51 41 3D 2I 1Z 0C
      #     ,  ,  ,  ,  ,  ,  ,

      context "with addressing mode: 'r, Program Counter Relative'" do
        # op code: 10
      end
    end

    describe "BRA" do
      # Status Register:
      #   7N 6V 51 41 3D 2I 1Z 0C
      #     ,  ,  ,  ,  ,  ,  ,

      context "with addressing mode: 'r, Program Counter Relative'" do
        # op code: 80
      end
    end

    describe "BRK" do
      # Status Register:
      #   7N 6V 51 41 3D 2I 1Z 0C
      #     ,  ,  , 1, 0, 1,  ,

      context "with addressing mode: 's, Stack'" do
        # op code: 00
      end
    end

    describe "BVC" do
      # Status Register:
      #   7N 6V 51 41 3D 2I 1Z 0C
      #     ,  ,  ,  ,  ,  ,  ,

      context "with addressing mode: 'r, Program Counter Relative'" do
        # op code: 50
      end
    end

    describe "BVS" do
      # Status Register:
      #   7N 6V 51 41 3D 2I 1Z 0C
      #     ,  ,  ,  ,  ,  ,  ,

      context "with addressing mode: 'r, Program Counter Relative'" do
        # op code: 70
      end
    end

    describe "CLC" do
      # Status Register:
      #   7N 6V 51 41 3D 2I 1Z 0C
      #     ,  ,  ,  ,  ,  ,  , 0

      context "with addressing mode: 'i, Implied'" do
        # op code: 18
      end
    end

    describe "CLD" do
      # Status Register:
      #   7N 6V 51 41 3D 2I 1Z 0C
      #     ,  ,  ,  , 0,  ,  ,

      context "with addressing mode: 'i, Implied'" do
        # op code: d8
      end
    end

    describe "CLI" do
      # Status Register:
      #   7N 6V 51 41 3D 2I 1Z 0C
      #     ,  ,  ,  ,  , 0,  ,

      context "with addressing mode: 'i, Implied'" do
        # op code: 58
      end
    end

    describe "CLV" do
      # Status Register:
      #   7N 6V 51 41 3D 2I 1Z 0C
      #     , 0,  ,  ,  ,  ,  ,

      context "with addressing mode: 'i, Implied'" do
        # op code: b8
      end
    end

    describe "CMP" do
      # Status Register:
      #   7N 6V 51 41 3D 2I 1Z 0C
      #    N,  ,  ,  ,  ,  , Z, C

      context "with addressing mode: '(zp,x), Zero Page Indexed Indirect'" do
        # op code: c1
      end

      context "with addressing mode: 'zp, Zero Page'" do
        # op code: c5
      end

      context "with addressing mode: '#, Immediate'" do
        # op code: c9
        it "sets the zero flag when memory matches accumulator" do
          # lda #42 - a9 2a
          # cmp #42 - c9 2a
          rom = make_rom(%w[a9 2a c9 2a])
          clock.on_tick { rom.update }
          cpu.address = 0x7FFF # Set address to our rom location
          cpu.step
          expect(cpu.a).to eq(42)
          expect(cpu.pc).to eq(0x8001)
          cpu.step
          expect(cpu.flag?(CPU65c02::P_ZERO)).to eq(true)
        end
      end

      context "with addressing mode: 'a, Absolute'" do
        # op code: cd
      end

      context "with addressing mode: '(zp),y, Zero Page Indirect Indexed with Y'" do
        # op code: d1
      end

      context "with addressing mode: '(zp), Zero Page Indirect'" do
        # op code: d2
      end

      context "with addressing mode: 'zp,x, Zero Page Indexed with X'" do
        # op code: d5
      end

      context "with addressing mode: 'a,y, Absolute Indexed with Y'" do
        # op code: d9
      end

      context "with addressing mode: 'a,x, Absolute Indexed with X'" do
        # op code: dd
      end
    end

    describe "CPX" do
      # Status Register:
      #   7N 6V 51 41 3D 2I 1Z 0C
      #    N,  ,  ,  ,  ,  , Z, C

      context "with addressing mode: '#, Immediate'" do
        # op code: e0
      end

      context "with addressing mode: 'zp, Zero Page'" do
        # op code: e4
      end

      context "with addressing mode: 'a, Absolute'" do
        # op code: ec
      end
    end

    describe "CPY" do
      # Status Register:
      #   7N 6V 51 41 3D 2I 1Z 0C
      #    N,  ,  ,  ,  ,  , Z, C

      context "with addressing mode: '#, Immediate'" do
        # op code: c0
      end

      context "with addressing mode: 'zp, Zero Page'" do
        # op code: c4
      end

      context "with addressing mode: 'a, Absolute'" do
        # op code: cc
      end
    end

    describe "DEC" do
      # Status Register:
      #   7N 6V 51 41 3D 2I 1Z 0C
      #    N,  ,  ,  ,  ,  , Z,

      context "with addressing mode: 'A, Accumulator'" do
        # op code: 3a
      end

      context "with addressing mode: 'zp, Zero Page'" do
        # op code: c6
      end

      context "with addressing mode: 'a, Absolute'" do
        # op code: ce
      end

      context "with addressing mode: 'zp,x, Zero Page Indexed with X'" do
        # op code: d6
      end

      context "with addressing mode: 'a,x, Absolute Indexed with X'" do
        # op code: de
      end
    end

    describe "DEX" do
      # Status Register:
      #   7N 6V 51 41 3D 2I 1Z 0C
      #    N,  ,  ,  ,  ,  , Z,

      context "with addressing mode: 'i, Implied'" do
        # op code: ca
      end
    end

    describe "DEY" do
      # Status Register:
      #   7N 6V 51 41 3D 2I 1Z 0C
      #    N,  ,  ,  ,  ,  , Z,

      context "with addressing mode: 'i, Implied'" do
        # op code: 88
      end
    end

    describe "EOR" do
      # Status Register:
      #   7N 6V 51 41 3D 2I 1Z 0C
      #    N,  ,  ,  ,  ,  , Z,

      context "with addressing mode: '(zp,x), Zero Page Indexed Indirect'" do
        # op code: 41
      end

      context "with addressing mode: 'zp, Zero Page'" do
        # op code: 45
      end

      context "with addressing mode: '#, Immediate'" do
        # op code: 49
      end

      context "with addressing mode: 'a, Absolute'" do
        # op code: 4d
      end

      context "with addressing mode: '(zp),y, Zero Page Indirect Indexed with Y'" do
        # op code: 51
      end

      context "with addressing mode: '(zp), Zero Page Indirect'" do
        # op code: 52
      end

      context "with addressing mode: 'zp,x, Zero Page Indexed with X'" do
        # op code: 55
      end

      context "with addressing mode: 'a,y, Absolute Indexed with Y'" do
        # op code: 59
      end

      context "with addressing mode: 'a,x, Absolute Indexed with X'" do
        # op code: 5d
      end
    end

    describe "INC" do
      # Status Register:
      #   7N 6V 51 41 3D 2I 1Z 0C
      #    N,  ,  ,  ,  ,  , Z,

      context "with addressing mode: 'A, Accumulator'" do
        # op code: 1a
      end

      context "with addressing mode: 'zp, Zero Page'" do
        # op code: e6
      end

      context "with addressing mode: 'a, Absolute'" do
        # op code: ee
      end

      context "with addressing mode: 'zp,x, Zero Page Indexed with X'" do
        # op code: f6
      end

      context "with addressing mode: 'a,x, Absolute Indexed with X'" do
        # op code: fe
      end
    end

    describe "INX" do
      # Status Register:
      #   7N 6V 51 41 3D 2I 1Z 0C
      #    N,  ,  ,  ,  ,  , Z,

      context "with addressing mode: 'i, Implied'" do
        # op code: e8
      end
    end

    describe "INY" do
      # Status Register:
      #   7N 6V 51 41 3D 2I 1Z 0C
      #    N,  ,  ,  ,  ,  , Z,

      context "with addressing mode: 'i, Implied'" do
        # op code: c8
      end
    end

    describe "JMP" do
      # Status Register:
      #   7N 6V 51 41 3D 2I 1Z 0C
      #     ,  ,  ,  ,  ,  ,  ,

      context "with addressing mode: 'a, Absolute'" do
        # op code: 4c
      end

      context "with addressing mode: '(a), Absolute Indirect'" do
        # op code: 6c
      end

      context "with addressing mode: '(a,x), Absolute Indexed Indirect'" do
        # op code: 7c
      end
    end

    describe "JSR" do
      # Status Register:
      #   7N 6V 51 41 3D 2I 1Z 0C
      #    N,  ,  ,  ,  ,  , Z,

      context "with addressing mode: 'a, Absolute'" do
        # op code: 20
      end
    end

    describe "LDA" do
      # Status Register:
      #   7N 6V 51 41 3D 2I 1Z 0C
      #    N,  ,  ,  ,  ,  , Z,

      context "with addressing mode: '(zp,x), Zero Page Indexed Indirect'" do
        # op code: a1
        let!(:rom) do
          assemble_rom(<<~ASM, 'lda (zp,x)')
              .org 8000
            main:
              lda (1,x)
          ASM
        end

        before(:each) do
          clock.on_tick do
            rom.update
            memory.update
          end
        end

        it "loads a with the correct value" do
          cpu.address = 0x7FFF # ROM
          cpu.x = 0x05
          memory.write(0x0001, 0x03) # store $03 in $01
          memory.write(0x0008, 0x42) # store $42 in $08
          cpu.step
          # $0001 : 03 + 05 = $0008
          # $0008 : 42
          expect(cpu.a).to eq(0x42)
        end
      end

      context "with addressing mode: 'zp, Zero Page'" do
        # op code: a5
        let(:rom) do
          assemble_rom(<<~ASM, 'lda zp')
              .org 8000
            main:
              lda $10
          ASM
        end

        before(:each) do
          clock.on_tick do
            rom.update
            memory.update
          end
        end

        it "loads with the correct value" do
          cpu.address = 0x7FFF # ROM
          memory.write(0x0010, 0x42) # Put 0x42 in memory address $10
          cpu.step
          expect(cpu.a).to eq(0x42)
        end
      end

      context "with addressing mode: '#, Immediate'" do
        # op code: a9
        it "loads the a register" do
          rom = make_rom(%w[a9 42]) # lda #$42
          clock.on_tick { rom.update }
          cpu.address = 0x7FFF # ROM
          cpu.step
          expect(cpu.a).to eq(0x42)
        end
      end

      context "with addressing mode: 'a, Absolute'" do
        # op code: ad
        let(:rom) do
          assemble_rom(<<~ASM, 'lda a')
              .org 8000
            main:
              lda $4000
          ASM
        end

        before(:each) do
          clock.on_tick do
            rom.update
            memory.update
          end
        end

        it "loads a with the correct value" do
          cpu.address = 0x7FFF # ROM
          memory.write(0x4000, 0x42)
          cpu.step
          expect(cpu.a).to eq(0x42)
        end
      end

      context "with addressing mode: '(zp),y, Zero Page Indirect Indexed with Y'" do
        # op code: b1
        let(:rom) do
          assemble_rom("  lda ($01), y")
        end

        before(:each) do
          clock.on_tick do
            rom.update
            memory.update
          end
        end

        it "loads a with the correct value" do
          cpu.address = 0x7FFF # ROM
          memory.write(0x01, 0x40)
          cpu.y = 2
          cpu.step
          expect(cpu.a).to eq(0x42)
        end
      end

      context "with addressing mode: '(zp), Zero Page Indirect'" do
        # op code: b2
        let(:rom) do
          make_rom(%w[b2 01])
        end

        before(:each) do
          clock.on_tick do
            rom.update
            memory.update
          end
        end

        it "loads a with the correct value" do
          cpu.address = 0x7FFF # ROM
          memory.write(0x01, 0x42)
          cpu.step
          expect(cpu.a).to eq(0x42)
        end
      end

      context "with addressing mode: 'zp,x, Zero Page Indexed with X'" do
        # op code: b5
        let(:rom) do
          make_rom(%w[b5 01])
        end

        before(:each) do
          clock.on_tick do
            rom.update
            memory.update
          end
        end

        # lda $01,x ; $01 + x = $02 -> $42
        it "loads a with the correct value" do
          cpu.address = 0x7FFF # ROM
          memory.write(0x02, 0x42)
          cpu.x = 1
          cpu.step
          expect(cpu.a).to eq(0x42)
        end
      end

      context "with addressing mode: 'a,y'" do
        # op code: b9
        let(:rom) do
          make_rom(%w[b9 10 40])
        end

        before(:each) do
          clock.on_tick do
            rom.update
            memory.update
          end
        end

        # lda $8010,y ; $4010 + y = $4011 -> $42
        it "loads a with the correct value" do
          cpu.address = 0x7FFF # ROM
          memory.write(0x4011, 0x42)
          cpu.y = 1
          cpu.step
          expect("%02x" % cpu.a).to eq('42')
        end
      end

      context "with addressing mode: 'a,x, Absolute Indexed with X'" do
        # op code: bd
      end
    end

    describe "LDX" do
      # Status Register:
      #   7N 6V 51 41 3D 2I 1Z 0C
      #    N,  ,  ,  ,  ,  , Z,

      context "with addressing mode: '#, Immediate'" do
        # op code: a2
      end

      context "with addressing mode: 'zp, Zero Page'" do
        # op code: a6
      end

      context "with addressing mode: 'a, Absolute'" do
        # op code: ae
      end

      context "with addressing mode: 'zp,y, Zero Page Indexed with Y'" do
        # op code: b6
      end

      context "with addressing mode: 'a,y, Absolute Indexed with Y'" do
        # op code: be
      end
    end

    describe "LDY" do
      # Status Register:
      #   7N 6V 51 41 3D 2I 1Z 0C
      #    N,  ,  ,  ,  ,  , Z,

      context "with addressing mode: '#, Immediate'" do
        # op code: a0
      end

      context "with addressing mode: 'zp, Zero Page'" do
        # op code: a4
      end

      context "with addressing mode: 'A, Accumulator'" do
        # op code: ac
      end

      context "with addressing mode: 'zp,x, Zero Page Indexed with X'" do
        # op code: b4
      end

      context "with addressing mode: 'a,x, Absolute Indexed with X'" do
        # op code: bc
      end
    end

    describe "LSR" do
      # Status Register:
      #   7N 6V 51 41 3D 2I 1Z 0C
      #    0,  ,  ,  ,  ,  , Z, C

      context "with addressing mode: 'zp, Zero Page'" do
        # op code: 46
      end

      context "with addressing mode: 'A, Accumulator'" do
        # op code: 4a
      end

      context "with addressing mode: 'a, Absolute'" do
        # op code: 4e
      end

      context "with addressing mode: 'zp,x, Zero Page Indexed with X'" do
        # op code: 56
      end

      context "with addressing mode: 'a,x, Absolute Indexed with X'" do
        # op code: 5e
      end
    end

    describe "NOP" do
      # Status Register:
      #   7N 6V 51 41 3D 2I 1Z 0C
      #     ,  ,  ,  ,  ,  ,  ,

      context "with addressing mode: 'i, Implied'" do
        # op code: ea
      end
    end

    describe "ORA" do
      # Status Register:
      #   7N 6V 51 41 3D 2I 1Z 0C
      #    N,  ,  ,  ,  ,  , Z,

      context "with addressing mode: '(zp,x), Zero Page Indexed Indirect'" do
        # op code: 01
      end

      context "with addressing mode: 'zp, Zero Page'" do
        # op code: 05
      end

      context "with addressing mode: '#, Immediate'" do
        # op code: 09
      end

      context "with addressing mode: 'a, Absolute'" do
        # op code: 0d
      end

      context "with addressing mode: '(zp),y, Zero Page Indirect Indexed with Y'" do
        # op code: 11
      end

      context "with addressing mode: '(zp), Zero Page Indirect'" do
        # op code: 12
      end

      context "with addressing mode: 'zp,x, Zero Page Indexed with X'" do
        # op code: 15
      end

      context "with addressing mode: 'a,y, Absolute Indexed with Y'" do
        # op code: 19
      end

      context "with addressing mode: 'a,x, Absolute Indexed with X'" do
        # op code: 1d
      end
    end

    describe "PHA" do
      # Status Register:
      #   7N 6V 51 41 3D 2I 1Z 0C
      #     ,  ,  ,  ,  ,  ,  ,

      context "with addressing mode: 's, Stack'" do
        # op code: 48
      end
    end

    describe "PHP" do
      # Status Register:
      #   7N 6V 51 41 3D 2I 1Z 0C
      #     ,  ,  ,  ,  ,  ,  ,

      context "with addressing mode: 's, Stack'" do
        # op code: 08
      end
    end

    describe "PHX" do
      # Status Register:
      #   7N 6V 51 41 3D 2I 1Z 0C
      #     ,  ,  ,  ,  ,  ,  ,

      context "with addressing mode: 's, Stack'" do
        # op code: da
      end
    end

    describe "PHY" do
      # Status Register:
      #   7N 6V 51 41 3D 2I 1Z 0C
      #     ,  ,  ,  ,  ,  ,  ,

      context "with addressing mode: 's, Stack'" do
        # op code: 5a
      end
    end

    describe "PLA" do
      # Status Register:
      #   7N 6V 51 41 3D 2I 1Z 0C
      #    N,  ,  ,  ,  ,  , Z,

      context "with addressing mode: 's, Stack'" do
        # op code: 68
      end
    end

    describe "PLP" do
      # Status Register:
      #   7N 6V 51 41 3D 2I 1Z 0C
      #    N, V,  , 1, D, I, Z, C

      context "with addressing mode: 's, Stack'" do
        # op code: 28
      end
    end

    describe "PLX" do
      # Status Register:
      #   7N 6V 51 41 3D 2I 1Z 0C
      #    N,  ,  ,  ,  ,  , Z,

      context "with addressing mode: 's, Stack'" do
        # op code: fa
      end
    end

    describe "PLY" do
      # Status Register:
      #   7N 6V 51 41 3D 2I 1Z 0C
      #    N,  ,  ,  ,  ,  , Z,

      context "with addressing mode: 's, Stack'" do
        # op code: 7a
      end
    end

    describe "RMB0" do
      # Status Register:
      #   7N 6V 51 41 3D 2I 1Z 0C
      #     ,  ,  ,  ,  ,  ,  ,

      context "with addressing mode: 'zp, Zero Page'" do
        # op code: 07
      end
    end

    describe "RMB1" do
      # Status Register:
      #   7N 6V 51 41 3D 2I 1Z 0C
      #     ,  ,  ,  ,  ,  ,  ,

      context "with addressing mode: 'zp, Zero Page'" do
        # op code: 17
      end
    end

    describe "RMB2" do
      # Status Register:
      #   7N 6V 51 41 3D 2I 1Z 0C
      #     ,  ,  ,  ,  ,  ,  ,

      context "with addressing mode: 'zp, Zero Page'" do
        # op code: 27
      end
    end

    describe "RMB3" do
      # Status Register:
      #   7N 6V 51 41 3D 2I 1Z 0C
      #     ,  ,  ,  ,  ,  ,  ,

      context "with addressing mode: 'zp, Zero Page'" do
        # op code: 37
      end
    end

    describe "RMB4" do
      # Status Register:
      #   7N 6V 51 41 3D 2I 1Z 0C
      #     ,  ,  ,  ,  ,  ,  ,

      context "with addressing mode: 'zp, Zero Page'" do
        # op code: 47
      end
    end

    describe "RMB5" do
      # Status Register:
      #   7N 6V 51 41 3D 2I 1Z 0C
      #     ,  ,  ,  ,  ,  ,  ,

      context "with addressing mode: 'zp, Zero Page'" do
        # op code: 57
      end
    end

    describe "RMB6" do
      # Status Register:
      #   7N 6V 51 41 3D 2I 1Z 0C
      #     ,  ,  ,  ,  ,  ,  ,

      context "with addressing mode: 'zp, Zero Page'" do
        # op code: 67
      end
    end

    describe "RMB7" do
      # Status Register:
      #   7N 6V 51 41 3D 2I 1Z 0C
      #     ,  ,  ,  ,  ,  ,  ,

      context "with addressing mode: 'zp, Zero Page'" do
        # op code: 77
      end
    end

    describe "ROL" do
      # Status Register:
      #   7N 6V 51 41 3D 2I 1Z 0C
      #    N,  ,  ,  ,  ,  , Z, C

      context "with addressing mode: 'zp, Zero Page'" do
        # op code: 26
      end

      context "with addressing mode: 'A, Accumulator'" do
        # op code: 2a
      end

      context "with addressing mode: 'a, Absolute'" do
        # op code: 2e
      end

      context "with addressing mode: 'zp,x, Zero Page Indexed with X'" do
        # op code: 36
      end

      context "with addressing mode: 'a,x, Absolute Indexed with X'" do
        # op code: 3e
      end
    end

    describe "ROR" do
      # Status Register:
      #   7N 6V 51 41 3D 2I 1Z 0C
      #    N,  ,  ,  ,  ,  , Z, C

      context "with addressing mode: 'zp, Zero Page'" do
        # op code: 66
      end

      context "with addressing mode: 'A, Accumulator'" do
        # op code: 6a
      end

      context "with addressing mode: 'a, Absolute'" do
        # op code: 6e
      end

      context "with addressing mode: 'zp,x, Zero Page Indexed with X'" do
        # op code: 76
      end

      context "with addressing mode: 'a,x, Absolute Indexed with X'" do
        # op code: 7e
      end
    end

    describe "RTI" do
      # Status Register:
      #   7N 6V 51 41 3D 2I 1Z 0C
      #    N, V,  , 1, D, I, Z, C

      context "with addressing mode: 's, Stack'" do
        # op code: 40
      end
    end

    describe "RTS" do
      # Status Register:
      #   7N 6V 51 41 3D 2I 1Z 0C
      #     ,  ,  ,  ,  ,  ,  ,

      context "with addressing mode: 's, Stack'" do
        # op code: 60
      end
    end

    describe "SBC" do
      # Status Register:
      #   7N 6V 51 41 3D 2I 1Z 0C
      #    N, V,  ,  ,  ,  , Z, C

      context "with addressing mode: '(zp,x), Zero Page Indexed Indirect'" do
        # op code: e1
      end

      context "with addressing mode: 'zp, Zero Page'" do
        # op code: e5
      end

      context "with addressing mode: '#, Immediate'" do
        # op code: e9
      end

      context "with addressing mode: 'a, Absolute'" do
        # op code: ed
      end

      context "with addressing mode: '(zp),y, Zero Page Indirect Indexed with Y'" do
        # op code: f1
      end

      context "with addressing mode: '(zp), Zero Page Indirect'" do
        # op code: f2
      end

      context "with addressing mode: 'zp,x, Zero Page Indexed with X'" do
        # op code: f5
      end

      context "with addressing mode: 'a,y, Absolute Indexed with Y'" do
        # op code: f9
      end

      context "with addressing mode: 'a,x, Absolute Indexed with X'" do
        # op code: fd
      end
    end

    describe "SEC" do
      # Status Register:
      #   7N 6V 51 41 3D 2I 1Z 0C
      #     ,  ,  ,  ,  ,  ,  , 1

      context "with addressing mode: 'I, '" do
        # op code: 38
      end
    end

    describe "SED" do
      # Status Register:
      #   7N 6V 51 41 3D 2I 1Z 0C
      #     ,  ,  ,  , 1,  ,  ,

      context "with addressing mode: 'i, Implied'" do
        # op code: f8
      end
    end

    describe "SEI" do
      # Status Register:
      #   7N 6V 51 41 3D 2I 1Z 0C
      #     ,  ,  ,  ,  , 1,  ,

      context "with addressing mode: 'i, Implied'" do
        # op code: 78
      end
    end

    describe "SMB0" do
      # Status Register:
      #   7N 6V 51 41 3D 2I 1Z 0C
      #     ,  ,  ,  ,  ,  ,  ,

      context "with addressing mode: 'zp, Zero Page'" do
        # op code: 87
      end
    end

    describe "SMB1" do
      # Status Register:
      #   7N 6V 51 41 3D 2I 1Z 0C
      #     ,  ,  ,  ,  ,  ,  ,

      context "with addressing mode: 'zp, Zero Page'" do
        # op code: 97
      end
    end

    describe "SMB2" do
      # Status Register:
      #   7N 6V 51 41 3D 2I 1Z 0C
      #     ,  ,  ,  ,  ,  ,  ,

      context "with addressing mode: 'zp, Zero Page'" do
        # op code: a7
      end
    end

    describe "SMB3" do
      # Status Register:
      #   7N 6V 51 41 3D 2I 1Z 0C
      #     ,  ,  ,  ,  ,  ,  ,

      context "with addressing mode: 'zp, Zero Page'" do
        # op code: b7
      end
    end

    describe "SMB4" do
      # Status Register:
      #   7N 6V 51 41 3D 2I 1Z 0C
      #     ,  ,  ,  ,  ,  ,  ,

      context "with addressing mode: 'zp, Zero Page'" do
        # op code: c7
      end
    end

    describe "SMB5" do
      # Status Register:
      #   7N 6V 51 41 3D 2I 1Z 0C
      #     ,  ,  ,  ,  ,  ,  ,

      context "with addressing mode: 'zp, Zero Page'" do
        # op code: d7
      end
    end

    describe "SMB6" do
      # Status Register:
      #   7N 6V 51 41 3D 2I 1Z 0C
      #     ,  ,  ,  ,  ,  ,  ,

      context "with addressing mode: 'zp, Zero Page'" do
        # op code: e7
      end
    end

    describe "SMB7" do
      # Status Register:
      #   7N 6V 51 41 3D 2I 1Z 0C
      #     ,  ,  ,  ,  ,  ,  ,

      context "with addressing mode: 'zp, Zero Page'" do
        # op code: f7
      end
    end

    describe "STA" do
      # Status Register:
      #   7N 6V 51 41 3D 2I 1Z 0C
      #     ,  ,  ,  ,  ,  ,  ,

      context "with addressing mode: '(zp,x), Zero Page Indexed Indirect'" do
        # op code: 81
      end

      context "with addressing mode: 'zp, Zero Page'" do
        # op code: 85
      end

      context "with addressing mode: 'a, Absolute'" do
        # op code: 8d
      end

      context "with addressing mode: '(zp),y, Zero Page Indirect Indexed with Y'" do
        # op code: 91
      end

      context "with addressing mode: '(zp), Zero Page Indirect'" do
        # op code: 92
      end

      context "with addressing mode: 'zp,x, Zero Page Indexed with X'" do
        # op code: 95
      end

      context "with addressing mode: 'a,y, Absolute Indexed with Y'" do
        # op code: 99
      end

      context "with addressing mode: 'a,x, Absolute Indexed with X'" do
        # op code: 9d
      end
    end

    describe "STP" do
      # Status Register:
      #   7N 6V 51 41 3D 2I 1Z 0C
      #     ,  ,  ,  ,  ,  ,  ,

      context "with addressing mode: 'I, '" do
        # op code: db
      end
    end

    describe "STX" do
      # Status Register:
      #   7N 6V 51 41 3D 2I 1Z 0C
      #     ,  ,  ,  ,  ,  ,  ,

      context "with addressing mode: 'zp, Zero Page'" do
        # op code: 86
      end

      context "with addressing mode: 'a, Absolute'" do
        # op code: 8e
      end

      context "with addressing mode: 'zp,y, Zero Page Indexed with Y'" do
        # op code: 96
      end
    end

    describe "STY" do
      # Status Register:
      #   7N 6V 51 41 3D 2I 1Z 0C
      #     ,  ,  ,  ,  ,  ,  ,

      context "with addressing mode: 'zp, Zero Page'" do
        # op code: 84
      end

      context "with addressing mode: 'a, Absolute'" do
        # op code: 8c
      end

      context "with addressing mode: 'zp,x, Zero Page Indexed with X'" do
        # op code: 94
      end
    end

    describe "STZ" do
      # Status Register:
      #   7N 6V 51 41 3D 2I 1Z 0C
      #     ,  ,  ,  ,  ,  ,  ,

      context "with addressing mode: 'zp, Zero Page'" do
        # op code: 64
      end

      context "with addressing mode: 'zp,x, Zero Page Indexed with X'" do
        # op code: 74
      end

      context "with addressing mode: 'a, Absolute'" do
        # op code: 9c
      end

      context "with addressing mode: 'a,x, Absolute Indexed with X'" do
        # op code: 9e
      end
    end

    describe "TAX" do
      # Status Register:
      #   7N 6V 51 41 3D 2I 1Z 0C
      #    N,  ,  ,  ,  ,  , Z,

      context "with addressing mode: 'i, Implied'" do
        # op code: aa
      end
    end

    describe "TAY" do
      # Status Register:
      #   7N 6V 51 41 3D 2I 1Z 0C
      #    N,  ,  ,  ,  ,  , Z,

      context "with addressing mode: 'i, Implied'" do
        # op code: a8
      end
    end

    describe "TRB" do
      # Status Register:
      #   7N 6V 51 41 3D 2I 1Z 0C
      #     ,  ,  ,  ,  ,  , Z,

      context "with addressing mode: 'zp, Zero Page'" do
        # op code: 14
      end

      context "with addressing mode: 'a, Absolute'" do
        # op code: 1c
      end
    end

    describe "TSB" do
      # Status Register:
      #   7N 6V 51 41 3D 2I 1Z 0C
      #     ,  ,  ,  ,  ,  , Z,

      context "with addressing mode: 'zp, Zero Page'" do
        # op code: 04
      end

      context "with addressing mode: 'a, Absolute'" do
        # op code: 0c
      end
    end

    describe "TSX" do
      # Status Register:
      #   7N 6V 51 41 3D 2I 1Z 0C
      #    N,  ,  ,  ,  ,  , Z,

      context "with addressing mode: 'i, Implied'" do
        # op code: ba
      end
    end

    describe "TXA" do
      # Status Register:
      #   7N 6V 51 41 3D 2I 1Z 0C
      #    N,  ,  ,  ,  ,  , Z,

      context "with addressing mode: 'i, Implied'" do
        # op code: 8a
      end
    end

    describe "TXS" do
      # Status Register:
      #   7N 6V 51 41 3D 2I 1Z 0C
      #     ,  ,  ,  ,  ,  ,  ,

      context "with addressing mode: 'i, Implied'" do
        # op code: 9a
      end
    end

    describe "TYA" do
      # Status Register:
      #   7N 6V 51 41 3D 2I 1Z 0C
      #    N,  ,  ,  ,  ,  , Z,

      context "with addressing mode: 'i, Implied'" do
        # op code: 98
      end
    end

    describe "WAI" do
      # Status Register:
      #   7N 6V 51 41 3D 2I 1Z 0C
      #     ,  ,  ,  ,  ,  ,  ,

      context "with addressing mode: 'I, '" do
        # op code: cb
      end
    end
  end
end
