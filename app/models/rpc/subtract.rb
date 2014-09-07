module RPC
  class Subtract
    def initialize(params)
      case params
      when Hash
        @minuend = params.delete(:minuend).to_i
        @subtrahend = params.delete(:subtrahend).to_i
      when Array
        @minuend, @subtrahend = params.map(&:to_i)
      else
        raise
      end
    rescue
      raise RPCDispatcher::InvalidParams
    end

    def execute
      @minuend - @subtrahend
    end
  end
end