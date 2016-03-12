require_relative 'combinators'

module Hivemind

  # BaseGrammar = Phoenix::Grammar.new
  # BaseGrammar.rules = {
  #   segment: many(ref(:keyword_structure), as: :elements),
  #   keyword_structure: ref(:module) | ref(:class) | ref(:method),
  #   method: lit('module') & some(ws) & ref(:name, as: :module_name) & 
  #           many(ref(:expr), as: :body),
  #   expr:   ref(:if) | ref(:sequence) | ref(:attribute) | ref(:attribute_assign) |
  #           ref(:assign) | ref(:literal),
  #   sequence: ref(:list) | ref(:dictionary),
  #   list:   lit('[') & join(ref(:expr), ', ', as: :elements) & lit(']'),
  #   dictionary: lit('{') & join(ref(:pair), ', ', as: :elements) & lit('}'),
  #   pair: ref(:expr, as: :key) & some(ws) & '=>' & some(ws) & ref(:expr, as: :value),
  #   attribute: ref(:expr, as: :object, except: :attribute) & '.' & ref(:name, as: :label),
  #   attribute_assign: ref(:expr, as: :object, except: :attribute) & '.' & ref(:name, as: :label) & some(ws) & lit('=') & some(ws) & ref(:expr, as: :right),
  #   assign: ref(:name, as: :left) & some(ws) & lit('=') & some(ws) & ref(:expr, as: :right),
  #   literal: ref(:string) | ref(:boolean) | ref(:nil_literal) | ref(:number) | ref(:name)
  #   name: regex(/[a-zA-Z_]+/, as: :value),
  #   string: lit('"') & regex(/[^"]*/, as: :value) + lit('"'),
  #   number: regex(/[0-9]+(\.[0-9]+)?/, as: :value),
  #   boolean: ref(:true_literal) | ref(:false_literal),
  #   true_literal: 'true',
  #   false_literal: 'false',
  #   nil_literal: 'nil',
  #   :if => lit('if') & some(ws) & ref(:expr, as: :test) & lit(':') & nl & indent & join(ref(:expr), "\n", as: :true_branch) &
  #          nl & dedent & lit('else') & lit(':') & nl & indent & join(ref(:expr), "\n", as: :else_branch) & nl & dedent,
  #   :class => lit('class') & some(ws) & ref(:name, as: :class_name) &
  #             many(ref(:ex)

  # }


  TYPES = {
    assign: {
      left: :name,
      right: :expr
    },

    attribute: {
      object: :expr_no_attr,
      label: :name_or_attr
    },

    image: {
      statements: :class_statement
    },

    binary: {
      left: :expr_no_binary,
      operation: :operation,
      right: :expr
    },

    attribute_assign: {
      object: :expr_no_attr,
      label: :name_or_attr,
      right: :expr
    },

    call: {
      function: :expr_no_call,
      args: :expr
    },

    list: {
      elements: :expr
    },

    dictionary: {
      pair: :pair
    },

    pair: {
      key: :string,
      value: :expr
    },

    method_statement: {
      method_name: :name,
      args: :name,
      body: :expr
    },

    class_statement: {
      class_name: :name,
      methods: :method_statement
    },

    module_statement: {
      module_name: :name,
      elements: :statement
    },

    if_statement: {
      test: :expr,
      true_branch: :expr,
      else_branch: :expr
    }
  }

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
      rules = self.class.load_rules(@grammar_source)
      refs = {}

      rules.each do |name, rule|
        refs[:"_#{name}"] = parse_rule rule, TYPES[name]
      end

      [REFS[:image], REFS.merge(refs)]
    end

    def parse_rule(rule, types)
      parsers = []
      tokens = []
      token = ''
      i = 0
      while i < rule.length
        z = rule[i]
        if '<>'.include?(z)
          tokens << token unless token.empty?
          token = ''
          if z == '>'
            if rule[i + 1] == '>'
              tokens << '>>'
              i += 1
            else
              tokens << '>'
            end
          elsif z == '<'
            if rule[i + 1] == '<'
              tokens << '<<'
              i += 1
            else
              tokens << '<'
            end
          end
        elsif z == "'"
          tokens << token unless token.empty?
          token = ''
          j = i
          i += 1
          while rule[i] != "'"
            i += 1
          end
          tokens << rule[j..i]
        elsif z == ' '
          tokens << token unless token.empty?
          token = ''
          j = i
          while rule[i] == ' '
            i += 1
          end
          tokens << rule[j..i - 1]
          i -= 1
        elsif z == "\n"
          tokens << token unless token.empty?
          tokens << "\n"
        elsif z.match /[a-zA-Z_0-9]/
          token += z
        else
          tokens << token unless token.empty?
          token = ''
          tokens << z
        end
        i += 1
      end
      tokens << token unless token.empty?

      r = 0
      in_var = false

      tokens.each_with_index do |token, i|
        if token == '>>'
          if tokens[i - 2] == ':'
            parsers << Join.new(
                Ref.new(types[tokens[i - 3].to_sym]),
                tokens[i - 1][1..-2], as: tokens[i - 3])
          else
            parsers << Join.new(Ref.new(types[tokens[i - 1].to_sym]), "\n#{'    ' * r}", as: tokens[i - 1])
            #Many.new(Ref.new(types[tokens[i - 1].to_sym]), as: tokens[i - 1])
          end
          in_var = false
        elsif token == '>'
          parsers << Ref.new(types[tokens[i - 1].to_sym])
          in_var = false
        elsif token == "\n"
          parsers << Ref.new(:nl)
          if tokens[i + 1] == "\n"
            e = 2
          elsif tokens[i + 1]
            match = tokens[i + 1].match /([    ]+)/
            if match.nil? || match.captures.empty?
              indent = 0
            else
              indent = match.captures.first.size / 4
            end
            if indent > r
              parsers << Ref.new(:indent)
            elsif indent < r
              parsers << Ref.new(:dedent)
            end
            r = indent
          end 
        elsif token.match(/\A +\z/) 
          parsers << Ref.new(:ws)
        elsif (token == '<<' || token == '<') && tokens[i + 1] >= 'a' && tokens[i + 1] <= 'z'
          in_var = true
        elsif !in_var 
          parsers << Lit.new(token)
        end
      end
      # parsers.map { |pa| puts pa.inspect }
      parsers.reduce(:&)
    end

    def self.load_rules(grammar)
      lines = grammar.split("\n")
      rules = {}
      current_rule = nil
      rule_body = []
      lines.each do |line|
        if line.start_with? '#'
          if not current_rule.nil?
            rule_body << "\n" if rule_body.length > 1
            rules[current_rule.to_sym] = rule_body.join("\n")
            rule_body = []
          end
          current_rule = line[1..-1].strip
        elsif line.strip != ''
          rule_body << line
        end
      end
      rule_body << "\n" if rule_body.length > 1
      rules[current_rule.to_sym] = rule_body.join("\n")
      rules
    end
  end
  
  Name = UniversalAST::Name
  Number = UniversalAST::Number
  Assign = UniversalAST::Assign
  Element = UniversalAST::Element
  Call = UniversalAST::Call
  List = UniversalAST::List
  Dictionary = UniversalAST::Dictionary
  Pair = UniversalAST::Pair
  Attribute = UniversalAST::Attribute
  AttributeAssign = UniversalAST::AttributeAssign
  IfStatement = UniversalAST::IfStatement
  MethodStatement = UniversalAST::MethodStatement
  ClassStatement = UniversalAST::ClassStatement
  Image = UniversalAST::Image
  Operation = UniversalAST::Operation
  Float = UniversalAST::Float
  Int = UniversalAST::Int

  REFS = {
    name: Apply.new(Mat.new(/[a-zA-Z][a-zA-Z_]*/)) do |result|
      Name.new(result.to_sym)
    end,
    
    image: Apply.new(Join.new(Ref.new(:class_statement), "", as: :statements)) do |children|
      # d = children.select { |child| child.is_a?(MethodStatement) }
      e = children.select { |child| child.is_a?(ClassStatement) }
      # obj = e.find { |element| element.is_a?(ClassStatement) && element.class_name == :Object }
      # p e[0].class_name
      # if obj.nil? && !d.empty?
      #   obj = ClassStatement.new(Name.new(:Object), d)
      #   e << obj
      # elsif obj
      #   obj.methods += d
      # end
      Image.new(e)
    end,

    statement: Ref.new(:module_statement) | Ref.new(:class_statement) | Ref.new(:method_statement), 

    number: Ref.new(:float) | Ref.new(:int),

    float: Apply.new(Mat.new(/[0-9]+\.[0-9]+/)) do |result|
      Float.new(result.to_f)
    end,

    int: Apply.new(Mat.new(/[0-9]+/)) do |result|
      Int.new(result.to_i)
    end,

    string: Apply.new(Mat.new(/\"[^\"]*\"/)) do |result|
      String.new(result[1..-2])
    end,

    ws: Mat.new(/ +/),

    nl: Mat.new(/\n*/),

    indent: Lit.new(''),

    dedent: Lit.new(''),

    expr: Ref.new(:attribute_assign) | Ref.new(:assign) | Ref.new(:binary) | Ref.new(:call) | Ref.new(:attribute) | Ref.new(:number) | Ref.new(:name) | Ref.new(:string),

    expr_no_attr: Ref.new(:number) | Ref.new(:nil) | Ref.new(:name) | Ref.new(:string),

    expr_no_call: Ref.new(:binary) | Ref.new(:attribute) | Ref.new(:number) | Ref.new(:name) | Ref.new(:string),

    nil: Lit.new('nil'),

    name_or_attr: Ref.new(:name) | Ref.new(:attribute), 

    assign: Apply.new(Ref.new(:_assign)) do |results|
      Assign.new(*results.select { |r| r.is_a?(Element) })
    end,

    attribute_assign: Apply.new(Ref.new(:_attribute_assign)) do |results|
      AttributeAssign.new(*results.select { |r| r.is_a?(Element) })
    end,

    call: Apply.new(Ref.new(:_call)) do |results|
      function, args = results.select { |r| r.is_a?(Element) || r.is_a?(Array) }
      Call.new(function, args)
    end,

    list: Apply.new(Ref.new(:_list)) do |results|
      List.new(results[1])
    end,

    dictionary: Apply.new(Ref.new(:_dictionary)) do |results|
      Dictionary.new(results[1])
    end,

    pair: Apply.new(Ref.new(:_pair)) do |results|
      key, value = results.select { |r| r.is_a?(Element) }
      Pair.new(key, value)
    end,

    binary: Apply.new(Ref.new(:_binary)) do |results|
      if results[0].is_a?(String)
        results = results[1..-1]
      end
      # detect operation intelligently
      tokens = results[0], results[2], results[4]      
      if tokens[0].is_a?(UniversalAST::Operation)
        operation, left, right = tokens
      elsif tokens[1].is_a?(UniversalAST::Operation)
        left, operation, right = tokens
      else
        left, right, operation = tokens
      end
      # p results
      UniversalAST::Binary.new(left, operation, right)
    end,

    expr_no_binary: Ref.new(:attribute) | Ref.new(:number) | Ref.new(:name) | Ref.new(:string),

    operation: Apply.new(Lit.new('+') | Lit.new('-') | Lit.new('**') | Lit.new('/') | Lit.new('*') | Lit.new('||')) do |result|
      Operation.new(result)
    end, 

    attribute: Apply.new(Ref.new(:_attribute)) do |results|
      object, label = results.select { |r| r.is_a?(Element) }
      Attribute.new(object, label)
    end, 

    if_statement: Apply.new(Ref.new(:_if_statement)) do |results|
      test, true_branch, else_branch = results.select { |r| r.is_a?(Element) || r.is_a?(Array) }
      IfStatement.new(test, true_branch, else_branch)
    end,

    method_statement: Apply.new(Ref.new(:_method_statement)) do |results|
      method_name, args, body = results.select { |r| r.is_a?(Element) || r.is_a?(Array) }
      MethodStatement.new(method_name, args, body)
    end,
    
    class_statement: Apply.new(Ref.new(:_class_statement)) do |results|
      class_name, methods = results.select { |r| r.is_a?(Element) || r.is_a?(Array) }
      ClassStatement.new(class_name, methods)
    end,

    module_statement: Apply.new(Ref.new(:_module_statement)) do |results|
      module_name, classes = results.select { |r| r.is_a?(Element) || r.is_a?(Array) }
      ModuleStatement.new(module_name, classes)
    end
  }

end





