require_relative "../bus.rb"

RSpec.describe Bus do
  describe "#on_write" do
    let(:bus) { Bus.new(8) }

    it "triggers a callback with the correct mask" do
      callback_triggered = false
      bus.on_write(0b1100_0000) { |val| callback_triggered = true }
      bus.write(0b1111_0000) # Should trigger
      expect(callback_triggered).to be(true)
    end

    it "does not trigger a callback with mismatched mask" do
      callback_triggered = false
      bus.on_write(0b1100_0000) { |val| callback_triggered = true }
      bus.write(0b0011_0000) # Should not trigger
      expect(callback_triggered).to be(false)
    end
  end
end
