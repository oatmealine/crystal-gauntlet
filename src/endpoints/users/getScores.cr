require "uri"

include CrystalGauntlet

# if you're wondering why this is called "getGJScores", honestly same
CrystalGauntlet.endpoints["/getGJScores20.php"] = ->(context : HTTP::Server::Context): String {
  params = URI::Params.parse(context.request.body.not_nil!.gets_to_end)
  LOG.debug { params.inspect }

  count = Clean.clean_number(params["count"]).to_i32
  sort = "stars desc"
  offset = 0
  filter = ""
  case params["type"]
  when "top", "week"
    sort = "stars desc"
    offset = 0
  when "creators"
    sort = "creator_points desc"
    offset = 0
  when "relative"
    sort = "stars desc"

    stars = 0
    if params.has_key?("accountID")
      stars = DATABASE.scalar("select stars from users where account_id = ?", params["accountID"].to_i).as(Int64)
    else
      stars = DATABASE.scalar("select stars from users where udid = ?", params["udid"]).as(Int64)
    end

    offset = DATABASE.scalar("select count(*) from users where stars > ?", stars).as(Int64)
    offset = Math.max(offset - 10, 0)
  when "friends"
    user_id, account_id = Accounts.auth(params)
    if !(user_id && account_id)
      return "-1"
    end

    sort = "stars desc"
    filter = "join friend_links friend on (friend.account_id_1 = #{account_id} or friend.account_id_2 = #{account_id}) where users.account_id = friend.account_id_1 or users.account_id = friend.account_id_2"
  else
    raise "unknown type: #{params["type"]}"
  end

  results = [] of String
  DATABASE.query("select distinct username, id, coins, user_coins, icon_type, cube, ship, ball, ufo, wave, robot, spider, color1, color2, special, udid, account_id, stars, creator_points, demons, diamonds from users #{filter} order by #{sort} limit #{count} offset #{offset}") do |rs|
    rank = offset
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
      diamonds = rs.read(Int32)
      rank += 1

      results << Format.fmt_hash({
        1 => username,
        2 => id,
        3 => stars,
        4 => demons,
        6 => rank,
        7 => account_id || udid,
        8 => creator_points,
        9 => icon_value,
        10 => color1,
        11 => color2,
        13 => coins,
        14 => icon_type,
        15 => special,
        16 => account_id || udid,
        17 => user_coins,
        46 => diamonds
      })
    end
  end

  results.join("|")
}

CrystalGauntlet.endpoints["/getGJScores19.php"] = CrystalGauntlet.endpoints["/getGJScores20.php"]

CrystalGauntlet.endpoints["/getGJCreators19.php"] = ->(context : HTTP::Server::Context): String {
  params = URI::Params.parse(context.request.body.not_nil!.gets_to_end)
  LOG.debug { params.inspect }

  count = Clean.clean_number(params["count"]).to_i32
  results = [] of String
  DATABASE.query("select username, id, coins, user_coins, icon_type, cube, ship, ball, ufo, wave, robot, spider, color1, color2, special, udid, account_id, stars, creator_points, demons, diamonds from users order by creator_points desc limit #{count}") do |rs|
    rank = 0
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
      diamonds = rs.read(Int32)
      rank += 1

      results << Format.fmt_hash({
        1 => username,
        2 => id,
        3 => stars,
        4 => demons,
        6 => rank,
        7 => account_id || udid,
        8 => creator_points,
        9 => icon_value,
        10 => color1,
        11 => color2,
        13 => coins,
        14 => icon_type,
        15 => special,
        16 => account_id || udid,
        17 => user_coins,
        46 => diamonds
      })
    end
  end

  results.join("|")
}
