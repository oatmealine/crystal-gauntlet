require "uri"

include CrystalGauntlet

CrystalGauntlet.endpoints["/getGJLevelScores211.php"] = ->(body : String): String {
  params = URI::Params.parse(body)
  puts params.inspect

  account_id = Accounts.get_account_id_from_params(params)
  if !account_id || !Accounts.verify_gjp(account_id, params["gjp"])
    return "-1"
  end

  level_id = params["levelID"].to_i32
  daily_id = params["s10"].to_i32
  if daily_id == 0
    daily_id = nil
  end

  if params["percent"]? && params["percent"]? != "0"
    # set score

    attempts = params["s1"].to_i - 8354
    clicks = params["s2"].to_i - 3991
    time = params["s3"].to_i - 4085
    # todo: fix
    progress = String.new(XorCrypt.encrypt_string(GDBase64.decode_string(params["s6"]), "41274"))
    puts progress
    coins = params["s9"].to_i - 5819
    if coins > 3 || coins < 0
      return "-1"
    end
    percent = params["percent"].to_i
    if percent > 100 || percent < 0
      return "-1"
    end

    # todo: account for dailies

    if DATABASE.scalar("select count(*) from level_scores where account_id = ? and level_id = ?", account_id, level_id).as(Int64) > 0
      # check if an update is truly necessary
      percent_old, coins_old = DATABASE.query_one("select percent, coins from level_scores where account_id = ? and level_id = ?", account_id, level_id, as: {Int32, Int32})

      if percent > percent_old || coins > coins_old
        DATABASE.exec("update level_scores set account_id=?, level_id=?, daily_id=?, percent=?, attempts=?, clicks=?, coins=?, progress=?, time=?, set_at=? where account_id = ? and level_id = ?", account_id, level_id, daily_id, percent, attempts, clicks, coins, progress, time, Time.utc.to_s(Format::TIME_FORMAT), account_id, level_id)
      end
    else
      DATABASE.exec("insert into level_scores (account_id, level_id, daily_id, percent, attempts, clicks, coins, progress, time) values (?, ?, ?, ?, ?, ?, ?, ?, ?)", account_id, level_id, daily_id, percent, attempts, clicks, coins, progress, time)
    end
  end

  # return set scores

  type = params["type"]? ? params["type"] : "1"

  case type
  when 0
    # friends
    # todo
  when 1
    # global
    # todo
  when 2
    # weekly
    # todo
  end

  scores = [] of String

  i = 0
  DATABASE.query_each "select percent, level_scores.coins, set_at, users.username, users.id, users.icon_type, users.color1, users.color2, users.cube, users.ship, users.ball, users.ufo, users.wave, users.robot, users.spider, users.special, users.account_id from level_scores join users on level_scores.account_id = users.account_id where level_id = ? order by percent desc, level_scores.coins desc", level_id do |rs|
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
