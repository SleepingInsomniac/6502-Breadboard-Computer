require_relative "../memory.rb"
require_relative "../bus.rb"

RSpec.describe Memory do
  let!(:address_bus) { Bus.new(16) }
  let!(:data_bus) { Bus.new(8) }
  let!(:rwb) { Bus.new(1) }
  let!(:memory) do
    Memory.new(
      address_bus: address_bus,
      data_bus: data_bus,
      rwb: rwb,
      enable: 0b1000_0000_0000_0000, # Enable for addresses > $8000
      file_path: "test_memory"
    )
  end

  def destroy_memory
    FileUtils.rm("test_memory") if File.exist?("test_memory")
  end

  before(:all) { destroy_memory }
  after(:all) { destroy_memory }

  describe "#update" do
    it "writes from the data bus within correct addresses" do
      addr = 0b1000_0000_0000_1000
      dat  = 0xFF

      rwb.write(1)
      address_bus.write(addr)
      data_bus.write(dat)
      rwb.write(0)

      expect(memory.read(addr)).to eq(dat)
    end
  end
end
