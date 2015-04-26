require_relative 'syntax'

module Hivemind
  
  BASE_RULES = {
    image: -> element, depth = 0 do
      element.statements.map { |s| render_element(s) }.join("\n")
    end,

    int: -> element, depth = 0 do
      element.value.to_s
    end,

    float: -> element, depth = 0 do
      element.value.to_s
    end,

    string: -> element, depth = 0 do
      '"' + element.value.to_s + '"'
    end,

    name: -> element, depth = 0 do
      element.value.to_s
    end,

    operation: -> element, depth = 0 do
      element.value.to_s
    end
  }

  class Renderer
    def initialize(tree, syntax)
      @tree, @syntax = tree, syntax
      @rules = BASE_RULES.merge(Syntax.load_rules(syntax))
    end

    def render(depth = 0)
      render_element(@tree, depth).gsub(/\n\n+/, "\n\n").gsub(/\)\s+\)/, '))').gsub(/\}\s+\}/, '}}')
    end

    def offset(depth = 0)
      '    ' * depth
    end

    def render_element(element, depth = 0)
      rule = @rules[element.class.name.split('::').last.downcase.gsub('attributeassign', 'attribute_assign').gsub('statement', '_statement').to_sym]
      depth += 1 if element.class.name.end_with?('MethodStatement')
      p "for #{element.class.name.split('::').last.downcase.gsub('statement', '_statement').to_sym} #{depth}"
      offset(depth) + if rule.is_a?(String)
        render_template rule, element, depth
      elsif rule.is_a?(Proc)
        instance_exec element, depth, &rule
      end
    end

    def render_template(plan, element, depth = 0)
      plan = plan.gsub(/\<\<([a-zA-Z_]+)\:'([^\']*)'\>\>/) do
        element.send(Regexp.last_match[1]).map(&method(:render_element)).join(Regexp.last_match[2])
      end
      p plan
      plan = plan.gsub(/\<\<([a-zA-Z_]+)\>\>/) do
        element.send(Regexp.last_match[1]).map { |e| render_element(e, depth) }.join("\n")
      end
      p plan
      plan = plan.gsub(/\<([a-zA-Z_]+)\>/) do
        render_element(element.send(Regexp.last_match[1]))
      end
      plan
    end
  end
end
