require_relative 'errors'

module Hivemind
  class Environment
    attr_reader :parent, :values, :top
    attr_accessor :current_self

    def initialize(parent, **values)
      @parent, @values, @top = parent, values, (parent.nil? ? values : parent.top)
    end

    def [](key)
      value = fetch key
      return value if value
      raise HivemindMissingNameError.new("#{key} is missing")
    end

    def fetch(key)
      current = self
      until current.nil? || current.values.key?(key)
        current = current.parent
      end
      return current.values[key] unless current.nil?
      nil
    end

    def []=(key, value)
      @values[key] = value
    end
  end
end

