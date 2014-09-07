class RpcController < ApplicationController
  skip_before_filter :verify_authenticity_token

  def execute
    result_json = if batch_request?
                    params_requests.map do |rpc_request|
                      RPCDispatcher.new(rpc_request).execute.to_json
                    end.compact
                  else
                    RPCDispatcher.new(params).execute.to_json
                  end

    if result_json.blank?
      head :no_content
    else
      render json: result_json
    end
  end

  private

  def params_requests
    params.try(:[], '_json')
  end

  def batch_request?
    params_requests.try(:is_a?, Array)
  end
end