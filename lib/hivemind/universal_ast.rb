module Hivemind
  module UniversalAST
    class Element
      def self.fields(*labels)
        define_method(:initialize) do |*args|
          args.zip(labels).each do |arg, label|
            instance_variable_set "@#{label}", arg
          end
        end
        attr_reader *labels
      end

      def offset(depth)
        '    ' * depth
      end
    end

    class IfStatement < Element
      # if <test>:
      #   <<true-branch>>
      # else:
      #   <<else-branch>>

      fields :test, :true_branch, :else_branch

      def render(depth = 0)
        "#{offset(depth)}If\n#{offset(depth + 1)}#{@test.render(depth + 1)}\n"
        "#{@true_branch.render(depth + 1)}\n#{@else_branch.render(depth + 1)}\n"
      end
    end

    class Assign < Element
      # <left> = <right>

      fields :left, :right

      def render(depth = 0)
        "#{offset(depth)}Assign left: #{@left.render} right: #{@right.render}"
      end
    end

    class Attribute < Element
      # <object>.<label>

      fields :object, :label

      def render(depth = 0)
        "#{offset(depth)}Attribute : #{@object.render} #{@label.render}"
      end
    end

    class AttributeAssign < Element
      # <object>.<label> = <right>

      fields :object, :label, :right

      def render(depth = 0)
        "#{offset(depth)}AttributeAssign : #{@object.render} #{@label.render} #{@right.render}"
      end
    end

    class Call < Element
      # <function>(<<args:', '>>)

      fields :function, :args

      def render(depth = 0)
        "#{offset(depth)}Call\n#{@function.render(depth + 1)}\n#{offset(depth + 1)}#{@args.map(&:render).join(' ')}\n"
      end
    end

    class List < Element
      # [el1, el2..]

      fields :elements

      def render(depth = 0)
        "#{offset(depth)}List\n#{@elements.map { |e| e.render(depth + 1) }.join("\n")}"
      end
    end

    class Dictionary < Element
      # {key1: val1, key2: val2..}

      fields :pairs
    end

    class Binary < Element
      # <left> <operation> <right>

      fields :left, :operation, :right

      def render(depth = 0)
        "#{offset(depth)}Binary #{@left.render} #{@operation.value} #{@right.render}"
      end
    end

    class MethodStatement < Element
      # method <method-name>(<<args:', '):
      #   <<body>>

      fields :method_name, :args, :body

      def render(depth = 0)
        "#{offset(depth)}MethodStatement #{@method_name.value} #{@args.map(&:render).join(' ')}\n" +
        "#{@body.map { |e| e.render(depth + 1) }.join("\n")}\n"
      end
    end

    class ClassStatement < Element
      # type <class-name>:
      #   <<methods>>

      fields :class_name, :methods

      def render(depth = 0)
        "#{offset(depth)}ClassStatement #{@class_name.value}\n" + 
        "#{@methods.map { |e| e.render(depth + 1) }.join("\n")}\n"
      end
    end

    class Value < Element
      fields :value

      def render(depth = 0)
        "#{offset(depth)}#{@value}"
      end
    end

    class Name < Value
    end

    class String < Value
    end

    class Number < Value
    end

    class Int < Number
    end

    class Float < Number
    end

    class Operation < Value
    end

    class ModuleStatement < Element
      # module <module-name>:
      #   <<children>>

      fields :module_name, :elements
    end

    class Pair < Element
      # key => value
      fields :key, :value
    end

    class Image < Element
      fields :statements

      def render(depth = 0)
        @statements.map(&:render).join "\n"
      end
    end
  end
end

