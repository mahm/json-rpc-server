# ref: http://robots.thoughtbot.com/catching-json-parse-errors-with-custom-middleware
class CatchJsonParseErrors
  def initialize(app)
    @app = app
  end

  def call(env)
    begin
      @app.call(env)
    rescue ActionDispatch::ParamsParser::ParseError => error
      if rpc_request?(env)
        return [
          400, { 'Content-Type' => 'application/json' },
          [
            {
              jsonrpc: '2.0',
              error: {
                code: -32700,
                message: 'Parse error'
              },
              id: nil
            }.to_json
          ]
        ]
      else
        raise error
      end
    end
  end

  def rpc_request?(env)
    env['HTTP_ACCEPT'] =~ /application\/json/ && env['PATH_INFO'] == '/endpoint'
  end
end