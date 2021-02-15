require_relative "../memory"
require_relative "../bus"
require_relative "../breadboard"

require 'stringio'

RSpec.describe Memory do
  let(:breadboard) { Breadboard.new }
  let(:address_bus) { Bus.new(16) }
  let(:data_bus) { Bus.new(8) }
  let(:rwb) { Bus.new(1) }
  let!(:memory) do
    Memory.new(
      address_bus: address_bus,
      data_bus: data_bus,
      rwb: rwb,
      addresses: 0x4000..0x4010,
      file: StringIO.new("\xAC\xFF")
    )
  end

  describe "::uid" do
    it "returns a sequential id at the class level" do
      expect(Memory::uid).to eq(1)
      expect(Memory::uid).to eq(2)
    end
  end

  describe "#update" do
    context "when rwb is high" do
      it "writes to the data bus within correct addresses" do
        breadboard.on_update { memory.update }

        breadboard.update do
          rwb.write(1)
          address_bus.write(0x4000) # memory start
        end

        expect(data_bus.read).to eq(0xAC) # first byte

        breadboard.update do
          address_bus.write(0x4001) # Netx byte
        end

        expect(data_bus.read).to eq(0xFF)
      end
    end

    context "when rwb is low" do
      it "does not write to the data bus" do
        breadboard.on_update { memory.update }

        memory.write(0x4000, 0xAC)

        breadboard.update do
          rwb.write(0)
          data_bus.write(0xAA)
          address_bus.write(0x4000) # memory start
        end

        expect(data_bus.read).not_to eq(0xAC)
        expect(memory.read(0x4000)).to eq(0xAA) # Data bus wrote this
      end
    end
  end
end
