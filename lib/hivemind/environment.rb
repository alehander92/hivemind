require_relative 'errors'

module Hivemind
  class Environment
    attr_reader :parent, :values, :top

    def initialize(parent, **values)
      @parent, @values, @top = parent, values, parent.nil? ? self : @parent.top
    end

    def [](key)
      current = self
      until current.values.key? key
        current = current.parent
      end
      raise HivemindMissingNameError.new("#{key} is missing")
    end

    def []=(key, value)
      @values[key] = value
    end
  end
end

