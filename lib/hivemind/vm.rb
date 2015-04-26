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

  class Runtime::HivemindObject
    def call(function, args, env)
      if function.is_a?(UniversalAST::MethodStatement)
        args_values = {:self => self}
        function.args[1..-1].zip(args) do |label, arg|
          args_values[label.value.to_sym] = arg
        end
        body_env = Environment.new(env, **args_values)
        function.body.map { |expr| expr.run(body_env) }[-1] || env.top[:@nil]
      else
        function.call self, *args, env
      end
    end
  end

  class Runtime::HivemindClass
    def call(function, args, env)
      h = Runtime::HivemindObject.new({}, self)
      function = dispatch_method(:init)
      if function.is_a?(UniversalAST::MethodStatement)
        args_values = {:self => h}
        function.args[1..-1].zip(args) do |label, arg|
          args_values[label.value.to_sym] = arg
        end
        body_env = Environment.new(env, **args_values)
        function.body.map { |expr| expr.run(body_env) }[-1] || env.top[:@nil]
      else
        function.call h, *args, env
      end
      h
    end
  end
    
  module UniversalAST
    class Image
      def run(env)
        @statements.each do |statement|
          statement.run(env)
        end
        # puts env.top[:Object].methods.keys
        if env.top[:Object].methods.key? :start
          weird_object = Runtime::hivemind_object({})
          weird_object.call(env.top[:Object].methods[:start], [], env)
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
        env.current_self = obj

        if obj.respond_to?(:data) 
          if obj.data.key? @label.value
            obj.data[@label.value]
          else
            method = obj.klass.dispatch_method(@label.value)
            if method
              method
            else
              raise HivemindAccessError.new("No #{@label.value} in obj")
            end
          end
        else
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
        if !@function.is_a?(Attribute)
          function = @function.run(env)
          env.current_self.call(function, @args.map { |arg| arg.run(env) }, env)
        elsif @function.label.value != :new
          obj = @function.object.run(env)
          function = obj.klass.dispatch_method(@function.label.value)
          obj.call(function, @args.map { |arg| arg.run(env) }, env)
        else
          obj = @function.object.run(env)
          function == obj.dispatch_method(:init)
          obj.call(function, @args.map { |arg| arg.run(env) }, env)
        end
      end
    end

    class Binary
      def run(env)
        Runtime::hivemind_numbr(@left.run(env).data[:_value].send(@operation.value, @right.run(env).data[:_value]))
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
        Runtime::HivemindObject.new({_value: @value}, env.top[self.class.name.split('::').last.to_sym])
      end
    end

    class ClassStatement
      def run(env)
        definition = env.fetch(@class_name.value) || Runtime::HivemindClass.new(@class_name.value, env.top[:Object], {})
        @methods.each do |method|
          definition.methods[method.method_name.value] = method
        end
        env[@class_name.value] = definition
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
