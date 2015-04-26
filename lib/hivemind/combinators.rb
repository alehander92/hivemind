require_relative 'universal_ast'

class Combinator
  def &(other)
    And.new(self, other)
  end

  def |(other)
    Or.new(self, other)
  end
end

class Lit < Combinator
  attr_reader :value

  def initialize(value)
    @value = value
  end

  def parse(input, refs)
    if input.start_with?(@value)
      [true, @value, input[@value.length.. -1]]
    else
      [false, '', input]
    end
  end
end

class Mat < Combinator
  attr_reader :regex

  def initialize(regex)
    @regex = /\A#{regex}/
  end

  def parse(input, refs)
    match = @regex.match(input)
    if match
      [true, input[0..match.to_s.size - 1], input[match.to_s.size.. -1]]
    else
      [false, '', input]
    end
  end
end

class Binary < Combinator
  attr_accessor :first, :second

  def initialize(first, second)
    @first, @second = first, second
  end
end

class And < Binary
  def parse(input, refs)
    first_success, first_result, remaining = @first.parse(input, refs)
    if first_success
      second_success, second_result, remaining  = @second.parse(remaining, refs)
      if second_success
        return [true, combine(first_result, second_result), remaining]
      end
    end
    [false, [], input]
  end

  def combine(first_result, second_result)
    if @first.is_a?(And)
      first_result + [second_result]
    else
      [first_result, second_result]
    end
  end
end

class Or < Binary
  def parse(input, refs)
    [@first, @second].each do |combinator|
      success, result, remaining = combinator.parse(input, refs)
      return [true, result, remaining] if success
    end
    [false, '', input]
  end
end

class Many < Combinator
  attr_accessor :parser

  def initialize(parser, as: nil)
    @parser = parser
  end

  def parse(input, refs)
    success = true
    remaining = input
    results = []
    while success
      success, result, remaining = @parser.parse(remaining, refs)
      results.push(result) if success
    end
    [true, results, remaining]
  end
end

class Join < Combinator
  attr_accessor :parser, :as

  def initialize(parser, separator, as: nil)
    @parser = parser
    @separator = separator
    @as = as.to_sym
    @separator_parser = Lit.new(@separator) & Mat.new(/ */) #workaround hivemind
  end

  def parse(input, refs)
    success = true
    remaining = input
    results = []
    while success
      success, result, remaining = @parser.parse(remaining, refs)
      
      results.push(result) if success
      if success
        success, result, remaining = @separator_parser.parse(remaining, refs)
      end
    end
    [true, results, remaining]
  end
end

class Ref < Combinator
  attr_accessor :label

  def initialize(label, as: nil)
    @label = label
    @as = as
  end

  def parse(input, refs)
    ref_parser = refs[@label.to_sym]
    ref_parser.parse(input, refs)
  end
end

class Maybe < Combinator
  attr_accessor :parser

  def initialize(parser)
    @parser = parser
  end

  def parse(input, refs)
    _, result, remaining = @parser.parse(input, refs)
    [true, result, remaining]
  end
end

class Apply < Combinator
  attr_accessor :parser
  attr_reader :transformation

  def initialize(parser, &transformation)
    @parser, @transformation = parser, transformation
  end

  def parse(input, refs)
    success, result, remaining = @parser.parse(input, refs)
    result = @transformation.call(result) if success
    [success, result, remaining]
  end
end

def literal(value)
  Literal.new(value)
end

def many(combinator)
  Many.new(combinator)
end

def maybe(combinator)
  Maybe.new(combinator)
end

def apply(combinator, &transformation)
  Apply.new(combinator, &transformation)
end

def match(regex)
  Match.new(regex)
end
  