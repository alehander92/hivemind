require_relative 'environment'

module Hivemind
  module Runtime
    class HivemindObject
      attr_reader :data, :klass

      def initialize(data, klass)
      	@data, @klass = data, klass
      end
    end

    class HivemindClass
      attr_reader :label, :methods, :parent

      def initialize(label, parent = nil, methods = {})
      	@label, @parent, @methods = label, parent, methods
      end

      def define_hivemind_method(label, &handler)
        @methods[label] = handler
      end

      def dispatch_method(label)
        current = self
        until current.nil? || current.methods.key?(label)
          current = current.parent
        end
        !current ? nil : current.methods[label]
      end
    end

    class HivemindModule
      attr_reader :label, :elements

      def initialize(label, elements = [])
        @elements = elements
      end
    end

    def self.hivemind_string(value)
      HivemindObject.new({_value: value}, HivemindEnv[:String])
    end

    def self.hivemind_numbr(value)
      HivemindObject.new({_value: value}, HivemindEnv[value.is_a?(Fixnum) ? :Int : :Float])
    end

    def self.hivemind_object(data)
      HivemindObject.new(data, HivemindEnv[:Object])
    end

    HivemindEnv = Environment.new(nil, 
      Object: HivemindClass.new('Object')
    )

    HivemindEnv[:Class] = HivemindClass.new('Class', HivemindEnv[:Object])
    HivemindEnv[:String] = HivemindClass.new('String', HivemindEnv[:Object])
    HivemindEnv[:Int] = HivemindClass.new('Int', HivemindEnv[:Object])
    HivemindEnv[:Float] = HivemindClass.new('Float', HivemindEnv[:Object])
    HivemindEnv[:Boolean] = HivemindClass.new('Boolean', HivemindEnv[:Object])
    HivemindEnv[:@true] = HivemindObject.new({}, HivemindEnv[:Boolean])
    HivemindEnv[:NilClass] = HivemindClass.new('NilClass', HivemindEnv[:Object])
    HivemindEnv[:@nil] = HivemindObject.new({}, HivemindEnv[:NilClass])

    HivemindEnv[:Object].define_hivemind_method(:display) do |hivemind_self, *args, env|
      puts hivemind_self.call(hivemind_self.klass.dispatch_method(:to_string), args, env).data[:_value]
    end

    HivemindEnv[:Object].define_hivemind_method(:to_string) do |hivemind_self, *args, env|
      # p hivemind_self
      if [HivemindEnv[:Int], HivemindEnv[:Float], HivemindEnv[:String], HivemindEnv[:Boolean]].include? hivemind_self.klass
        hivemind_string(hivemind_self.data[:_value])
      elsif hivemind_self.klass == HivemindEnv[:NilClass]
        hivemind_string('null')
      else
        y = ''
        i = 0
        y2 = []
        hivemind_self.data.each do |key, value|
          y2 << key.to_s + ':' + value.call(value.klass.dispatch_method(:to_string), [], env).data[:_value].to_s
        end
        y = y2.join(', ') 
        hivemind_string("{#{y}}")
      end
    end
  end
end


