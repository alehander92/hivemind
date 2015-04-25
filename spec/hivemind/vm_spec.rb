require 'spec_helper'

module Hivemind
  describe VM do
    it 'should work for a program with a single number' do
      vm = VM.new UniversalAST::Number.new(44)
      expect(vm.run(Runtime::HivemindEnv).data[:_value]).to eq 44
    end
  end
end
