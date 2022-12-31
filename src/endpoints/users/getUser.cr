require "uri"

include CrystalGauntlet

# URI::Params{"gameVersion" => ["21"], "binaryVersion" => ["35"], "gdw" => ["0"], "accountID" => ["1"], "gjp" => ["XFZBX1NSW1xcUw=="], "targetAccountID" => ["1"], "secret" => ["Wmfd2893gb7"]}

CrystalGauntlet.endpoints["/getGJUserInfo20.php"] = ->(body : String): String {
  params = URI::Params.parse(body)
  puts params.inspect

  DATABASE.query("select accounts.id, accounts.username, is_admin, messages_enabled, friend_requests_enabled, comments_enabled, youtube_url, twitter_url, twitch_url, accounts.created_at, users.id, stars, demons, coins, user_coins, diamonds, orbs, creator_points, icon_type, color1, color2, glow, cube, ship, ball, ufo, wave, robot, spider, explosion from accounts join users on accounts.id = users.account_id where accounts.id = ?", params["targetAccountID"]) do |rs|
    if rs.move_next
      id = rs.read(Int32)
      username = rs.read(String)
      is_admin = rs.read(Int32)
      messages_enabled = rs.read(Int32)
      friend_requests_enabled = rs.read(Int32)
      comments_enabled = rs.read(Int32)
      youtube_url = rs.read(String | Nil)
      twitter_url = rs.read(String | Nil)
      twitch_url = rs.read(String | Nil)
      created_at = rs.read(String)
      user_id = rs.read(Int32)
      stars = rs.read(Int32)
      demons = rs.read(Int32)
      coins = rs.read(Int32)
      user_coins = rs.read(Int32)
      diamonds = rs.read(Int32)
      orbs = rs.read(Int32)
      creator_points = rs.read(Int32)
      icon_type = rs.read(Int32)
      color1 = rs.read(Int32)
      color2 = rs.read(Int32)
      glow = rs.read(Int32)
      cube = rs.read(Int32)
      ship = rs.read(Int32)
      ball = rs.read(Int32)
      ufo = rs.read(Int32)
      wave = rs.read(Int32)
      robot = rs.read(Int32)
      spider = rs.read(Int32)
      explosion = rs.read(Int32)

      # "1:".$user["userName"].":2:".$user["userID"].":13:".$user["coins"].":17:".$user["userCoins"].":10:".$user["color1"].":11:".$user["color2"].":3:".$user["stars"].":46:".$user["diamonds"].":4:".$user["demons"].":8:".$creatorpoints.":18:".$msgstate.":19:".$reqsstate.":50:".$commentstate.":20:".$accinfo["youtubeurl"].":21:".$user["accIcon"].":22:".$user["accShip"].":23:".$user["accBall"].":24:".$user["accBird"].":25:".$user["accDart"].":26:".$user["accRobot"].":28:".$user["accGlow"].":43:".$user["accSpider"].":47:".$user["accExplosion"].":30:".$rank.":16:".$user["extID"].":31:".$friendstate.":44:".$accinfo["twitter"].":45:".$accinfo["twitch"].":29:1:49:".$badge . $appendix;
      return CrystalGauntlet::Format.fmt_hash({
        1 => username,
        2 => user_id,
        13 => coins,
        17 => user_coins,
        10 => color1,
        11 => color2,
        3 => stars,
        46 => diamonds,
        4 => demons,
        8 => creator_points,
        18 => !messages_enabled,
        19 => !friend_requests_enabled,
        50 => !comments_enabled,
        20 => youtube_url || "",
        21 => cube,
        22 => ship,
        23 => ball,
        24 => ufo,
        25 => wave,
        26 => robot,
        28 => glow,
        43 => spider,
        47 => explosion,
        30 => 1, # rank; todo
        16 => id,
        # 31 = isnt (0) or is (1) friend or (3) incoming request or (4) outgoing request
        # todo
        31 => 0,
        # also w/ friend requests:
        # 32 => id,
        # 35 => comment,
        # 37 => date,
        44 => twitter_url || "",
        45 => twitch_url || "",
        29 => 1,
        # badge, todo
        49 => 0
      })
    else
      "-1"
    end
  end
}
