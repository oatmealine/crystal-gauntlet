require "uri"

include CrystalGauntlet

CrystalGauntlet.endpoints["/updateGJUserScore22.php"] = ->(context : HTTP::Server::Context): String {
  params = URI::Params.parse(context.request.body.not_nil!.gets_to_end)
  LOG.debug { params.inspect }

  user_id, account_id = Accounts.auth(params)
  if !(user_id && account_id)
    return "-1"
  end

  DATABASE.exec("update accounts set messages_enabled=?, friend_requests_enabled=?, comments_enabled=?, youtube_url=?, twitter_url=?, twitch_url=? where id=?", params["mS"].to_i32, params["frS"].to_i32, params["cS"].to_i32, params["yt"], params["twitter"], params["twitch"], account_id)

  "1"
}
