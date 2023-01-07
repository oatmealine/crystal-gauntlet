require "uri"

include CrystalGauntlet

CrystalGauntlet.endpoints["/updateGJAccSettings20.php"] = ->(context : HTTP::Server::Context): String {
  params = URI::Params.parse(context.request.body.not_nil!.gets_to_end)
  LOG.debug { params.inspect }

  user_id, account_id = Accounts.auth(params)
  if !(user_id && account_id)
    return "-1"
  end

  DATABASE.exec("update accounts set messages_enabled=?, friend_requests_enabled=?, comments_enabled=?, youtube_url=?, twitter_url=?, twitch_url=? where id=?", params["mS"].to_i.clamp(0..2), params["frS"].to_i.clamp(0..1), params["cS"].to_i.clamp(0..2), params["yt"][..30-1], params["twitter"][..20-1], params["twitch"][..20-1], account_id)

  "1"
}
