class RPCDispatcher
  ERROR_INVALID_REQUEST  = -32600
  ERROR_METHOD_NOT_FOUND = -32601
  ERROR_INVALID_PARAMS   = -32602
  ERROR_INTERNAL         = -32603

  class InvalidRequest < StandardError
  end
  class InvalidParams < StandardError
  end
  class InternalError < StandardError
  end

  def initialize(rpc_request = {})
    @jsonrpc     = rpc_request.delete(:jsonrpc)
    @method_name = rpc_request.delete(:method)
    @params      = rpc_request.delete(:params)
    @request_id  = rpc_request.delete(:id)
  end

  def execute
    begin
      raise InvalidRequest unless valid?
      @result = Object.const_get("RPC::#{@method_name.camelize}").new(@params).execute
    rescue InvalidRequest
      @error_code = ERROR_INVALID_REQUEST
    rescue NameError
      @error_code = ERROR_METHOD_NOT_FOUND
    rescue InvalidParams
      @error_code = ERROR_INVALID_PARAMS
    rescue
      @error_code = ERROR_INTERNAL
    end
    self
  end

  def to_json
    return generate_error_json if has_error?
    return nil if notification?
    base_json.merge({ result: @result })
  end

  def valid?
    return false if @jsonrpc != '2.0'
    return false if @method_name.blank?
    true
  end

  def notification?
    @request_id.nil?
  end

  def has_error?
    @error_code.present?
  end

  private

  def generate_error_json
    error_content = case @error_code
                    when ERROR_INVALID_REQUEST
                      { error: { code: -32600, message: 'Invalid Request' } }
                    when ERROR_METHOD_NOT_FOUND
                      { error: { code: -32601, message: 'Method not found' } }
                    when ERROR_INVALID_PARAMS
                      { error: { code: -32602, message: 'Invalid Params' } }
                    when ERROR_INTERNAL
                      { error: { code: -32603, message: 'Internal Error' } }
                    else
                      { error: { code: -32000, message: 'Unexpected Error' } }
                    end
    base_json.merge(error_content)
  end

  def base_json
    {
      jsonrpc: '2.0',
      id:      @request_id
    }
  end
end