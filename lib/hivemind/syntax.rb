require 'phoenix'

module Hivemind

  BaseGrammar = Phoenix::Grammar.new
  BaseGrammar.rules = {
    segment: ref(:keyword_structure),
    keyword_structure: ref(:module) | ref(:class) | ref(:method)
  }
  end

  class Syntax
    def self.generate_syntax(bidirectional_grammar)
      new(bidirectional_grammar).generate
    end

    def initialize(grammar)
      @grammar_source = grammar
    end

    def generate
      # parse grammar
      # combine into base grammar
      rules = parse_rules(grammar)
      grammar = BaseGrammar.clone
      rules.each do |name, rule|
        grammar.rules[name] = extract_rule rule
      end
    end

    def extract_rule(rule)
      # state = :expect
      # <..> -> ref(name, as: label)
      # <<..>> -> many(ref(name), as: label)
      # <<..:' '> -> join(ref(name), as: label)
    end
          
    def parse_rules(grammar)
      lines = grammar.split("\n")
      rules = {}
      current_rule = nil
      rule_body = ''
      lines.each do |line|
        if line.start_with? '#'
          if not current_rule.nil?
            rules[current_rule] = '\n'.join(rule_body)
          end
          current_rule = line[1..-1].strip.to_sym
        else
          rule_body += line
        end
      end
      rules
    end
  end
end
