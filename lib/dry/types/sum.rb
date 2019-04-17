# frozen_string_literal: true

require 'dry/types/options'
require 'dry/types/meta'

module Dry
  module Types
    class Sum
      include Type
      include Builder
      include Options
      include Meta
      include Printable
      include Dry::Equalizer(:left, :right, :options, :meta, inspect: false)

      # @return [Type]
      attr_reader :left

      # @return [Type]
      attr_reader :right

      class Constrained < Sum
        # @return [Dry::Logic::Operations::Or]
        def rule
          left.rule | right.rule
        end

        # @return [true]
        def constrained?
          true
        end
      end

      # @param [Type] left
      # @param [Type] right
      # @param [Hash] options
      def initialize(left, right, options = {})
        super
        @left, @right = left, right
        freeze
      end

      # @return [String]
      def name
        [left, right].map(&:name).join(' | ')
      end

      # @return [false]
      def default?
        false
      end

      # @return [false]
      def constrained?
        false
      end

      # @return [Boolean]
      def optional?
        primitive?(nil)
      end

      # @param [Object] input
      # @return [Object]
      def call_unsafe(input)
        left.call_safe(input) { right.call_unsafe(input) }
      end

      # @param [Object] input
      # @return [Object]
      def call_safe(input, &block)
        left.call_safe(input) { right.call_safe(input, &block) }
      end

      def try(input)
        left.try(input) do
          right.try(input) do |failure|
            if block_given?
              yield(failure)
            else
              failure
            end
          end
        end
      end

      def success(input)
        if left.valid?(input)
          left.success(input)
        elsif right.valid?(input)
          right.success(input)
        else
          raise ArgumentError, "Invalid success value '#{input}' for #{inspect}"
        end
      end

      def failure(input, _error = nil)
        if !left.valid?(input)
          left.failure(input, left.try(input).error)
        else
          right.failure(input, right.try(input).error)
        end
      end

      # @param [Object] value
      # @return [Boolean]
      def primitive?(value)
        left.primitive?(value) || right.primitive?(value)
      end

      # @api public
      #
      # @see Nominal#to_ast
      def to_ast(meta: true)
        [:sum, [left.to_ast(meta: meta), right.to_ast(meta: meta), meta ? self.meta : EMPTY_HASH]]
      end

      # @param [Hash] options
      # @return [Constrained,Sum]
      # @see Builder#constrained
      def constrained(options)
        if optional?
          right.constrained(options).optional
        else
          super
        end
      end
    end
  end
end
