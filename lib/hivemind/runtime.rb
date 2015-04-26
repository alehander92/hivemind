require_relative 'environment'

module Hivemind
  module Runtime
    class HivemindObject
      attr_reader :data, :type

      def initialize(data, klass)
      	@data, @klass = data, klass
      end
    end

    class HivemindClass
      attr_reader :label, :methods

      def initialize(label, parent = nil, methods = {})
      	@labels, @parent, @methods = label, parent, methods
      end

      def define_hivemind_method(label, &handler)
        @methods[label] = handler
      end
    end

    class HivemindModule
      attr_reader :label, :elements

      def initialize(label, elements = [])
        @elements = elements
      end
    end

    def hivemind_string(value)
      HivemindEnv[:Object].new({_value: value}, HivemindEnv[:String])
    end

    HivemindEnv = Environment.new(nil, 
      Object: HivemindClass.new('Object')
    )

    HivemindEnv[:Class] = HivemindClass.new('Class', HivemindEnv[:Object])
    HivemindEnv[:String] = HivemindClass.new('String', HivemindEnv[:Object])
    HivemindEnv[:Number] = HivemindClass.new('Number', HivemindEnv[:Object])
    HivemindEnv[:Boolean] = HivemindClass.new('Boolean', HivemindEnv[:Object])
    HivemindEnv[:@true] = HivemindObject.new({}, HivemindEnv[:Boolean])
    HivemindEnv[:NilClass] = HivemindClass.new('NilClass', HivemindEnv[:Object])
    HivemindEnv[:@nil] = HivemindObject.new({}, HivemindEnv[:NilClass])

    HivemindEnv[:Object].define_hivemind_method(:display) do |hivemind_self, *args, env|
      p hivemind_self.call(hivemind_self.klass.methods[:to_string], *args, env).data[:_value]
    end

    HivemindEnv[:Object].define_hivemind_method(:to_string) do |hivemind_self, *args, env|
      if [HivemindEnv[:Number], HivemindEnv[:String], HivemindEnv[:Boolean]].include? hivemind_self.klass
        hivemind_string(hivemind_self.data[:_value])
      else
        'object'
      end
    end
  end
end


