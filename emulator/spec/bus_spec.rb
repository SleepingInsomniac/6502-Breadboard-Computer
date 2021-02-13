require_relative "../bus.rb"

RSpec.describe Bus do
  let(:bus) { Bus.new(8) }

  describe "#write" do
    it "writes within the size" do
      bus.write(0xFFFF)
      expect(bus.read).to eq(0xFF)
    end
  end
end
