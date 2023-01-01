require "uri"

include CrystalGauntlet

CrystalGauntlet.endpoints["/updateGJUserScore22.php"] = ->(body : String): String {
  params = URI::Params.parse(body)
  puts params.inspect

  user_id, account_id = Accounts.auth(params)
  if !(user_id && account_id)
    return "-1"
  end

  # todo: prevent username change unless it's a capitalization change
  # todo: update account username casing w/ user username
  # todo: keep track of stat changes to look out for leaderboard cheating & whatnot
  # todo: cap out demon count at the current amount of uploaded demons? same for stars & user coins. could be expensive though
  # todo: cap icon type

  DATABASE.exec("update accounts set messages_enabled=?, friend_requests_enabled=?, comments_enabled=?, youtube_url=?, twitter_url=?, twitch_url=? where id=?", params["mS"].to_i32, params["frS"].to_i32, params["cS"].to_i32, params["yt"], params["twitter"], params["twitch"], account_id)

  "1"
}
