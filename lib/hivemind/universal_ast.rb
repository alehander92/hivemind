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
    end

    class If < Element
      # if <test>:
      #   <<true-branch>>
      # else:
      #   <<else-branch>>

      fields :test, :true_branch, :else_branch
    end

    class Assign < Element
      # <left> = <right>

      fields :left, :right
    end

    class Attribute < Element
      # <object>.<label>

      fields :object, :label
    end

    class Call < Element
      # <function>(<<args:', '>>)

      fields :function, :args
    end

    class List < Element
      # [el1, el2..]

      fields :elements
    end

    class Dictionary < Element
      # {key1: val1, key2: val2..}

      fields :keys, :values
    end

    class Function < Element
      # function <function-name>(<<args:', '):
      #   <<body>>

      fields :function_name, :args, :body
    end

    class TypeDefinition < Element
      # type <type-name>:
      #   <<methods>>

      fields :type_name, :methods
    end

    class Value < Element
      fields :value
    end

    class Name < Value
    end

    class String < Value
    end

    class Number < Value
    end

    class Module < Element
      # module <module-name>:
      #   <<children>>

      fields :elements
    end
  end
end

