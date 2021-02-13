require_relative "../cpu_65c02.rb"
require_relative "../bus.rb"

RSpec.describe CPU65c02 do
  describe "#mnemonic" do
    it "returns the cooresponding mnemonic for a given opcode" do
      cpu = CPU65c02.new(
        address_bus: Bus.new(16),
        data_bus: Bus.new(8),
        rwb: Bus.new(1),
        clock: Bus.new(1)
      )
      expect(cpu.mnemonic(0xa9)).to eq('LDA #')
    end
  end
end
