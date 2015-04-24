module Hivemind
  module UniversalAST
     class Element
       def self.fields(**labels)
         define_method(:initialize) do |*args|
           args.zip(labels).each do |arg, label|
             instance_variable_set "@#{label}" = arg
          end
          attr_reader *labels
       end
     end

     class If < Element
       fields :test, :true_branch, :else_branch
     end
  end
end

