require "uri"

include CrystalGauntlet

CrystalGauntlet.endpoints["/getGJLevelScores211.php"] = ->(context : HTTP::Server::Context): String {
  params = URI::Params.parse(context.request.body.not_nil!.gets_to_end)
  LOG.debug { params.inspect }

  user_id, account_id = Accounts.auth(params)

  level_id = params["levelID"].to_i32
  daily_id = params["s10"].to_i32
  if daily_id == 0
    daily_id = nil
  end

  if params["percent"]? && params["percent"]? != "0"
    # set score

    if !(user_id && account_id)
      return "-1"
    end

    attempts = params["s1"].to_i - 8354
    clicks = params["s2"].to_i - 3991
    time = params["s3"].to_i - 4085
    progress = String.new(XorCrypt.encrypt_string(Base64.decode_string(params["s6"]), "41274"))
    coins = params["s9"].to_i - 5819
    if coins > 3 || coins < 0
      return "-1"
    end
    percent = params["percent"].to_i
    if percent > 100 || percent < 0
      return "-1"
    end

    if DATABASE.scalar("select count(*) from level_scores where account_id = ? and level_id = ? and daily_id is ?", account_id, level_id, daily_id).as(Int64) > 0
      # check if an update is truly necessary
      percent_old, coins_old = DATABASE.query_one("select percent, coins from level_scores where account_id = ? and level_id = ? and daily_id is ?", account_id, level_id, daily_id, as: {Int32, Int32})

      if percent > percent_old || coins > coins_old
        DATABASE.exec("update level_scores set account_id=?, percent=?, attempts=?, clicks=?, coins=?, progress=?, time=?, set_at=? where account_id = ? and level_id = ? and daily_id is ?", account_id, percent, attempts, clicks, coins, progress, time, Time.utc.to_s(Format::TIME_FORMAT), account_id, level_id, daily_id)
      end
    else
      DATABASE.exec("insert into level_scores (account_id, level_id, daily_id, percent, attempts, clicks, coins, progress, time) values (?, ?, ?, ?, ?, ?, ?, ?, ?)", account_id, level_id, daily_id, percent, attempts, clicks, coins, progress, time)
    end
  end

  # return set scores

  type = params["type"]? ? params["type"] : "1"

  joins = [] of String
  where_query = ["level_id = ? and daily_id is ?"]

  case type
  when "0"
    if !(user_id && account_id)
      return "-1"
    end

    # friends
    joins << "left join friend_links friend on (friend.account_id_1 = #{account_id} or friend.account_id_2 = #{account_id})"
    where_query << "level_scores.account_id = friend.account_id_1 or level_scores.account_id = friend.account_id_2"
  when "2"
    # weekly
    where_query << "level_scores.set_at > \"#{(Time.utc - 7.days).to_s(Format::TIME_FORMAT)}\""
  end

  scores = [] of String

  i = 0
  DATABASE.query_each "select distinct percent, level_scores.coins, set_at, users.username, users.id, users.icon_type, users.color1, users.color2, users.cube, users.ship, users.ball, users.ufo, users.wave, users.robot, users.spider, users.special, users.account_id from level_scores join users on level_scores.account_id = users.account_id #{joins.join(" ")} where (#{where_query.join(") and (")}) order by percent desc, level_scores.coins desc, set_at limit 200", level_id, daily_id do |rs|
    i += 1
    percent = rs.read(Int32)
    coins = rs.read(Int32)
    set_at = rs.read(String)

    username = rs.read(String)
    user_id = rs.read(Int32)
    icon_type = rs.read(Int32)
    color1 = rs.read(Int32)
    color2 = rs.read(Int32)

    icon_value = [rs.read(Int32), rs.read(Int32), rs.read(Int32), rs.read(Int32), rs.read(Int32), rs.read(Int32), rs.read(Int32)][icon_type]

    special = rs.read(Int32)

    account_id = rs.read(Int32)

    scores << Format.fmt_hash({
      1 => username,
      2 => user_id,
      9 => icon_value,
      10 => color1,
      11 => color2,
      14 => icon_type,
      15 => special,
      16 => account_id,
      3 => percent,
      6 => i,
      13 => coins,
      42 => Time.parse(set_at, Format::TIME_FORMAT, Time::Location::UTC)
    })
  end

  scores.join("|")
}
