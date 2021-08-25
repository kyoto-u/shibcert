json.array!(@certs) do |cert|
  json.extract! cert, :id, :memo, :get_at, :expire_at, :pin, :pin_get_at, :user_id
  json.url cert_url(cert, format: :json)
end
