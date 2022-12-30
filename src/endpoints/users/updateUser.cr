require "uri"

include CrystalGauntlet

# URI::Params{"gameVersion" => ["21"], "binaryVersion" => ["35"], "gdw" => ["0"], "accountID" => ["1"], "gjp" => ["XFZBX1NSW1xcUw=="], "targetAccountID" => ["1"], "secret" => ["Wmfd2893gb7"]}

CrystalGauntlet.endpoints["/updateGJUserScore22.php"] = ->(body : String): String {
  params = URI::Params.parse(body)
  puts params.inspect

  account_id = Accounts.get_ext_id_from_params(params)
  if !Accounts.verify_gjp(account_id, params["gjp"])
    return "-1"
  end

  user_id = Accounts.get_user_id(params["userName"], account_id)

  DATABASE.exec("update users set username=?, stars=?, demons=?, coins=?, user_coins=?, diamonds=?, icon_type=?, color1=?, color2=?, cube=?, ship=?, ball=?, ufo=?, wave=?, robot=?, spider=?, explosion=?, special=?, glow=?, last_played=? where id=?", params["userName"], params["stars"], params["demons"], params["coins"], params["userCoins"], params["diamonds"], params["iconType"], params["color1"], params["color2"], params["accIcon"], params["accShip"], params["accBall"], params["accBird"], params["accDart"], params["accRobot"], params["accSpider"], params["accExplosion"], params["special"], params["accGlow"], Time.utc.to_s("%Y-%m-%d %H:%M:%S"), user_id)

  user_id.to_s
}
