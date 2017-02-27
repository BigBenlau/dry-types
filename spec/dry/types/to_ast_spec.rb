require 'spec_helper'

RSpec.describe Dry::Types, '#to_ast' do
  context 'with a definition' do
    subject(:type) { Dry::Types::Definition.new(String) }

    specify do
      expect(type.to_ast).
        to eql([:definition, [:primitive, String]])
    end
  end

  context 'with a sum' do
    subject(:type) { Dry::Types['string'] | Dry::Types['int'] }

    specify do
      expect(type.to_ast).
        to eql([:sum, [
                  [:definition, [:primitive, String]],
                  [:definition, [:primitive, Integer]]
                ]])
    end
  end

  context 'with a constrained type' do
    subject(:type) { Dry::Types['strict.int'] }

    specify do
      expect(type.to_ast).
        to eql([:constrained, [
                  [:definition, [:primitive, Integer]],
                  [:predicate, [:type?, [[:type, Integer], [:input, Undefined]]]]
               ]])
    end
  end

  context 'Hash' do
    subject(:type) { Dry::Types['hash'] }

    specify do
      expect(type.to_ast).
        to eql([:hash, [:primitive, Hash]])
    end

    %i(schema weak permissive strict strict_with_defaults symbolized).each do |schema|
      context "#{schema.capitalize}" do
        subject(:type) { Dry::Types['hash'].send(schema, { name: Dry::Types['string'], age: Dry::Types['int'] }) }

        specify do
          expect(type.to_ast).
            to eql([:hash, [schema, [:member_types, [[[:definition, [:primitive, String]], [:definition, [:primitive, Integer]]]]]]])
        end
      end
    end
  end
end
