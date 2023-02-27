class Accounts::Apps::WppConnects::Create

  def self.call(account, wpp_connect_params)
    params = wpp_connect_params.merge({
      endpoint_url: ENV['WP_CONNECT_ENDPOINT'],
      secretkey: ENV['WP_CONNECT_SECRET_KEY'],
      account_id: account.id
    })
    wpp_connect = Apps::WppConnect.new(params)

    if wpp_connect.save
      return { ok: wpp_connect }
    else
      return { error: wpp_connect }
    end
  end
end