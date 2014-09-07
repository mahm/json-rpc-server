require 'rails_helper'

#----------------------------------------------------------
# Spec Helpers
#----------------------------------------------------------
def response_json
  JSON.parse(response.body)
end

def result
  response_json['result']
end

#----------------------------------------------------------
# Shared Examples
#----------------------------------------------------------
shared_examples 'JSON-RPCのレスポンス形式に従っていること' do
  it 'レスポンスに含まれるjsonrpcの値が2.0であること' do
    expect(response_json['jsonrpc']).to eq '2.0'
  end
  it 'レスポンスにresultが含まれること' do
    expect(response_json).to include 'result'
  end
  it 'レスポンスにidが含まれること' do
    expect(response_json).to include 'id'
  end
end

#----------------------------------------------------------
# Spec
#----------------------------------------------------------
describe 'JSON-RPC Spec', type: :request do
  JSON_CONTENT_TYPE = { 'CONTENT_TYPE' => 'application/json', 'ACCEPT' => 'application/json' }
  let(:rpc_params) { nil }
  let(:request) { post '/endpoint', rpc_params }
  let(:head_before_hook) { nil }
  before do
    head_before_hook
    request
  end

  describe 'RPC Methods Test' do
    let(:rpc_params) do
      {
        jsonrpc: '2.0',
        method: method_name,
        params: method_params,
        id: 1
      }
    end

    describe '#subtract' do
      let(:method_name) { 'subtract' }
      context 'パラメータを配列で受け取った場合' do
        let(:method_params) { [42, 23] }
        it_behaves_like 'JSON-RPCのレスポンス形式に従っていること'
        it '第1引数から第2引数を引いた値が返ること' do
          expect(result).to eq 19
        end
      end
      context 'パラメータを名前付きパラメータで受け取った場合' do
        let(:method_params) do
          {
            subtrahend: 23,
            minuend: 42
          }
        end
        it_behaves_like 'JSON-RPCのレスポンス形式に従っていること'
        it 'minuendからsubtrahendを引いた値が返ること' do
          expect(result).to eq 19
        end
      end
    end

    describe '#sum' do
      let(:method_name) { 'sum' }
      context 'パラメータを配列で受け取った場合' do
        let(:method_params) { (1..10).to_a }
        it_behaves_like 'JSON-RPCのレスポンス形式に従っていること'
        it '1から10まで足した値が返ること' do
          expect(result).to eq (1..10).sum
        end
      end
    end
  end

  describe 'JSON-RPC Request Patterns' do
    let(:request) do
      post '/endpoint', rpc_params.to_json, JSON_CONTENT_TYPE
    end
    context 'Notification Request' do
      let(:rpc_params) do
        { jsonrpc: '2.0', method: 'sum', params: [1, 2, 4] }
      end
      it 'レスポンス内容が返らないこと' do
        expect(response.body).to be_blank
      end
    end
    context 'Batch Request' do
      let(:rpc_params) do
        [
          { jsonrpc: '2.0', method: 'sum', params: [1, 2, 4], id: 1 },
          { jsonrpc: '2.0', method: 'sum', params: [1, 2, 4] },
          { foo: 'bar' },
          { jsonrpc: '2.0', method: 'subtract', params: [18, 32], id: 2 },
        ]
      end
      let(:expected) do
        [
          { 'jsonrpc' => '2.0', 'result' => 7, 'id' => 1 },
          {'jsonrpc' => '2.0', 'error' => {'code' => -32600, 'message' => 'Invalid Request'}, 'id' => nil},
          { 'jsonrpc' => '2.0', 'result' => -14, 'id' => 2 },
        ]
      end
      specify { expect(response_json).to eq expected }
    end
    context 'Batch Request (All notifications)' do
      let(:rpc_params) do
        [
          { jsonrpc: '2.0', method: 'sum', params: [1, 2, 4] },
          { jsonrpc: '2.0', method: 'sum', params: [1, 2, 4] },
          { jsonrpc: '2.0', method: 'subtract', params: [18, 32] },
        ]
      end
      it 'レスポンス内容が返らないこと' do
        expect(response.body).to be_blank
      end
    end
  end

  describe 'JSON-RPC Error Patterns' do
    context 'Parse Error' do
      let(:request) do
        post '/endpoint', %Q({"jsonrpc": "2.0", "method": "foobar, "params": "bar", "baz]), JSON_CONTENT_TYPE
      end
      let(:expected) do
        {'jsonrpc' => '2.0', 'error' => {'code' => -32700, 'message' => 'Parse error'}, 'id' => nil}
      end
      specify { expect(response_json).to eq expected }
    end
    context 'Method not found' do
      let(:rpc_params) do
        { jsonrpc: '2.0', method: 'notfound', params: [1], id: 1 }
      end
      let(:expected) do
        {'jsonrpc' => '2.0', 'error' => {'code' => -32601, 'message' => 'Method not found'}, 'id' => '1'}
      end
      specify { expect(response_json).to eq expected }
    end
    context 'Invalid Request' do
      let(:rpc_params) do
        { foo: 'bar' }
      end
      let(:expected) do
        {'jsonrpc' => '2.0', 'error' => {'code' => -32600, 'message' => 'Invalid Request'}, 'id' => nil}
      end
      specify { expect(response_json).to eq expected }
    end
    context 'Invalid Params' do
      let(:rpc_params) do
        { jsonrpc: '2.0', method: 'sum', params: 'string', id: 1 }
      end
      let(:expected) do
        {'jsonrpc' => '2.0', 'error' => {'code' => -32602, 'message' => 'Invalid Params'}, 'id' => '1'}
      end
      specify { expect(response_json).to eq expected }
    end
    context 'Internal Error' do
      let(:head_before_hook) do
        allow_any_instance_of(RPC::Sum).to receive(:execute).and_raise(StandardError)
      end
      let(:rpc_params) do
        { jsonrpc: '2.0', method: 'sum', params: [1, 2, 3], id: 1 }
      end
      let(:expected) do
        {'jsonrpc' => '2.0', 'error' => {'code' => -32603, 'message' => 'Internal Error'}, 'id' => '1'}
      end
      specify { expect(response_json).to eq expected }
    end
  end
end