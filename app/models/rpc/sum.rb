module RPC
  class Sum
    def initialize(params)
      case params
      when Array
        @array_for_sum = params.map(&:to_i)
      else
        raise
      end
    rescue
      raise RPCDispatcher::InvalidParams
    end

    def execute
      @array_for_sum.inject(&:+)
    end
  end
end