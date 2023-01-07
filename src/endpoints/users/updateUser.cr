require "uri"

include CrystalGauntlet

CrystalGauntlet.endpoints["/updateGJUserScore22.php"] = ->(context : HTTP::Server::Context): String {
  params = URI::Params.parse(context.request.body.not_nil!.gets_to_end)
  LOG.debug { params.inspect }

  user_id, account_id = Accounts.auth(params)
  if !(user_id && account_id)
    return "-1"
  end

  # todo: keep track of stat changes to look out for leaderboard cheating & whatnot
  # todo: cap out demon count at the current amount of uploaded demons? same for stars & user coins. could be expensive though

  old_username = DATABASE.query_one("select username from users where id = ?", user_id, as: {String})
  new_username = old_username

  # only change username if casing is the same
  if params["userName"].compare(old_username, case_insensitive: true) == 0
    new_username = params["userName"]
  end

  DATABASE.exec("update users set username=?, stars=?, demons=?, coins=?, user_coins=?, diamonds=?, icon_type=?, color1=?, color2=?, cube=?, ship=?, ball=?, ufo=?, wave=?, robot=?, spider=?, explosion=?, special=?, glow=?, last_played=? where id=?", new_username, params["stars"].to_i32, params["demons"].to_i32, params["coins"].to_i32, params["userCoins"].to_i32, params["diamonds"].to_i32, params["iconType"].to_i32.clamp(0..6), params["color1"].to_i32, params["color2"].to_i32, params["accIcon"].to_i32, params["accShip"].to_i32, params["accBall"].to_i32, params["accBird"].to_i32, params["accDart"].to_i32, params["accRobot"].to_i32, params["accSpider"].to_i32, params["accExplosion"].to_i32, params["special"].to_i32, params["accGlow"].to_i32, Time.utc.to_s(Format::TIME_FORMAT), user_id)

  if old_username != new_username && account_id
    DATABASE.exec("update accounts set username = ? where id = ?", new_username, account_id)
  end

  user_id.to_s
}
