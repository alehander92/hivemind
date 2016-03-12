#  'universal_ast'

# module Hivemind
#   class CodeViewer
#     def initialize(tree)
#       @tree = tree
#     end

#     def view_as(query)
#       hierarchy = QueryAnalyzer.parse(query)
#       rebuild_tree(hierarchy)
#     end

#     def rebuild_tree(hierarchy)
#       if hierarchy[0].type == @code_view.hierarchy[0].type
#         # only sorting maybe
#         # and sorting still not supported
#         @tree
#       else
#         # method > code
#         new_tree = UniversalAST::Image.new([])
#         top = {}
#         if hierarchy[0].type == :method
#           @tree.statements.each do |statement|
#             statement.methods.each do |method|
#               top[method.method_name.value] ||= {}
#               top[method.method_name.value][statement.class_name.value] = [args, method.body]
#             end
#           end
#         else
#            @tree.statements.each do |statement|
#              statement.body.each do |method|
#                top[method.class_name.value] ||= {}
#                top[method.class_name.value][statement.method_name.value] = [args, method.body]
#              end
#            end
#         end
#       end
#     end
#   end
# end
