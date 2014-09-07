Rails.application.routes.draw do
  post 'endpoint' => 'rpc#execute'
end
