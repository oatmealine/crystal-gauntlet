require "uri"
require "base64"
require "crypto/bcrypt/password"

include CrystalGauntlet

CrystalGauntlet.endpoints["/getGJUsers20.php"] = ->(body : String): String {
  params = URI::Params.parse(body)
  LOG.debug { params.inspect }

  page = params["page"].to_i
  results = [] of String
  username = params["str"] + "%"

  DATABASE.query("select username, id, coins, user_coins, icon_type, cube, ship, ball, ufo, wave, robot, spider, color1, color2, special, udid, account_id, stars, creator_points, demons from users where id = ? or username like ? order by stars desc limit 10 offset #{page * 10}", params["str"], username) do |rs|
    rs.each do
      username = rs.read(String)
      id = rs.read(Int32)
      coins = rs.read(Int32)
      user_coins = rs.read(Int32)
      icon_type = rs.read(Int32)
      icon_value = [rs.read(Int32), rs.read(Int32), rs.read(Int32), rs.read(Int32), rs.read(Int32), rs.read(Int32), rs.read(Int32)][icon_type]
      color1 = rs.read(Int32)
      color2 = rs.read(Int32)
      special = rs.read(Int32)
      udid = rs.read(String | Nil)
      account_id = rs.read(Int32 | Nil)
      stars = rs.read(Int32)
      creator_points = rs.read(Int32)
      demons = rs.read(Int32)

      results << Format.fmt_hash({
        1 => username,
        2 => id,
        3 => stars,
        4 => demons,
        8 => creator_points,
        9 => icon_value,
        10 => color1,
        11 => color2,
        13 => coins,
        14 => icon_type,
        15 => special,
        16 => account_id || udid,
        17 => user_coins,
      })
    end
  end

  amount = DATABASE.scalar("select count(*) from users where id = ? or username like ?", params["str"], username)
  response = [results.join("|"), "#{amount}:#{page * 10}:10"].join("#")

  response
}
