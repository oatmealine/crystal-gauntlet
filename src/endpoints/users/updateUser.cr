require "uri"

include CrystalGauntlet

# URI::Params{"gameVersion" => ["21"], "binaryVersion" => ["35"], "gdw" => ["0"], "accountID" => ["1"], "gjp" => ["XFZBX1NSW1xcUw=="], "targetAccountID" => ["1"], "secret" => ["Wmfd2893gb7"]}

CrystalGauntlet.endpoints["/updateGJUserScore22.php"] = ->(body : String): String {
  params = URI::Params.parse(body)
  puts params.inspect

  account_id = Accounts.get_account_id_from_params(params)
  if !account_id || !Accounts.verify_gjp(account_id, params["gjp"])
    return "-1"
  end

  user_id = Accounts.get_user_id(account_id.to_s)

  # todo: prevent username change unless it's a capitalization change
  # todo: update account username casing w/ user username
  # todo: keep track of stat changes to look out for leaderboard cheating & whatnot
  # todo: cap out demon count at the current amount of uploaded demons? same for stars & user coins. could be expensive though
  # todo: cap icon type

  DATABASE.exec("update users set username=?, stars=?, demons=?, coins=?, user_coins=?, diamonds=?, icon_type=?, color1=?, color2=?, cube=?, ship=?, ball=?, ufo=?, wave=?, robot=?, spider=?, explosion=?, special=?, glow=?, last_played=? where id=?", params["userName"], params["stars"].to_i32, params["demons"].to_i32, params["coins"].to_i32, params["userCoins"].to_i32, params["diamonds"].to_i32, params["iconType"].to_i32, params["color1"].to_i32, params["color2"].to_i32, params["accIcon"].to_i32, params["accShip"].to_i32, params["accBall"].to_i32, params["accBird"].to_i32, params["accDart"].to_i32, params["accRobot"].to_i32, params["accSpider"].to_i32, params["accExplosion"].to_i32, params["special"].to_i32, params["accGlow"].to_i32, Time.utc.to_s(Format::TIME_FORMAT), user_id)

  user_id.to_s
}
