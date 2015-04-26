require_relative 'runtime'
require_relative 'universal_ast'

module Hivemind
  class VM
    def initialize(ast)
      @ast = ast
    end

    def run(env)
      @ast.run env
    end
  end

  class Runtime::HivemindClass
    def call(function, args, env)
      if function.is_a?(UniversalAST::Function)
        args_values = {:self => self}
        function.args.zip(args) do |label, arg|
          args_values[label] = arg
        end
        body_env = Environment.new(env, args_values)
        function.body.map { |expr| expr.run(body_env) }[-1] || env.top[:@nil]
      else
        function.call self, *args, env
      end
    end
  end

    
  module UniversalAST
    class Image
      def run(env)
        @statements.each do |statement|
          statement.run(env)
        end
        puts env.top[:Object].methods.keys
        if env.top[:Object].methods.key? :start
          env.top[:Object].call(env.top[:Object].methods[:start], [env.top[:Object].new], env)
        else
          env.top[:@nil]
        end
      end
    end

    class ModuleStatement
      def run(env)
        module_statement = Runtime::HivemindModule.new(@module_name)
        @statements.each do |statement|
          module_statement.elements[@statement.is_a?(ModuleStatement) ? @statement.module_name : @statement.class_name] =
            statement.run(env)
        end
        env
      end
    end

    class If
      def run(env)
        if @test.run(env) == env.top[:@true]
          @true_branch.run env
        else
          @else_branch.run env
        end
      end
    end

    class Assign
      def run(env)
        env[@left.value.to_sym] = @right.run(env)
      end
    end

    class Attribute
      def run(env)
        obj = @object.run(env)
        if obj.respond_to?(:data) 
          obj.data[@label.value]
        else
          env[:current_class] = obj
          obj.methods[@label.value]
        end
      end
    end

    class AttributeAssign
      def run(env)
        @object.run(env).data[@label.value] = @right.run(env)
      end
    end

    class Call
      def run(env)
        function = @function.run(env)
        env[:current_class].call(function, @args, env)
      end
    end

    class List
      def run(env)
        Runtime::HivemindObject.new({_elements: @elements.map { |elem| elem.run(env) }}, env.top[:List])
      end
    end

    class Dictionary
      def run(env)
        dict = {}
        @pairs.each do |pair|
          dict[pair.key.value.to_sym] = pair.value.run(env)
        end
        Runtime::HivemindObject.new({_dict: dict}, env.top[:Dict])
      end
    end

    class Value
      def run(env)
        p env
        Runtime::HivemindObject.new({_value: @value}, env.top[self.class.name.to_sym])
      end
    end

    class ClassStatement
      def run(env)
        definition = Runtime::HivemindClass.new(@class_name, {})
        @methods.each do |method|
          definition.methods[method.method_name] = method
        end
        env[@class_name] = definition
      end
    end

    class MethodStatement
      def run(env)
        self
      end
    end

    class Name
      def run(env)
        env[@value]
      end
    end
  end
end
