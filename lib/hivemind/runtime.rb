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
    end

    HivemindEnv = Environment.new(nil, 
      Object: HivemindClass.new('Object')
    )

    HivemindEnv[:Class] = HivemindClass.new('Class', HivemindEnv[:Object])
    HivemindEnv[:String] = HivemindClass.new('String', HivemindEnv[:Object])
    HivemindEnv[:Number] = HivemindClass.new('Number', HivemindEnv[:Object])
    HivemindEnv[:Boolean] = HivemindClass.new('Boolean', HivemindEnv[:Object])
    HivemindEnv[:@true] = HivemindObject.new({}, HivemindEnv[:Boolean])
  end
end


