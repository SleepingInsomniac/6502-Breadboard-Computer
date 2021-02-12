require_relative "../memory.rb"
require_relative "../bus.rb"

RSpec.describe Memory do
  let(:address_bus) { Bus.new(16) }
  let(:data_bus) { Bus.new(8) }
  let(:rwb) { Bus.new(1) }
  let(:memory) do
    Memory.new(
      address_bus: address_bus,
      data_bus: data_bus,
      rwb: rwb,
      enable: 0b11000000_00000000 # Enable for addresses > $8000
    )
  end

  describe "#update" do
    it "writes from the data bus within correct addresses" do
      memory # init
      address_bus.write(0b1100_0000_0000_0000)
      data_bus.write(0b0101_0101)
      rwb.write(1)
      expect(memory.read(0b1100_0000_0000_0000)).to eq(0b0101_0101)
    end
  end
end
