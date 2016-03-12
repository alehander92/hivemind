require 'spec_helper'

module Hivemind
  module UniversalAST
    describe Element do
      it 'fields initializes a class with given labels' do
        class A < Element
          fields :a
        end
        
        expect(A.new(2).a).to eq(2)
      end
    end
    
    describe ModuleStatement do
      it 'is initialized with an elements attribute' do
        mod = ModuleStatement.new('ha', [])
        expect(mod.elements).to eq([])
      end
    end
  end
end
