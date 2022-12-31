require "uri"
require "base64"

include CrystalGauntlet

CrystalGauntlet.endpoints["/downloadGJLevel22.php"] = ->(body : String): String {
  params = URI::Params.parse(body)
  puts params.inspect

  response = ""

  DATABASE.query("select levels.id, levels.name, levels.level_data, levels.extra_data, levels.level_info, levels.password, levels.user_id, levels.description, levels.original, levels.game_version, levels.requested_stars, levels.version, levels.song_id, levels.length, levels.objects, levels.coins, levels.has_ldm, levels.two_player, levels.downloads, levels.likes, levels.difficulty, levels.demon_difficulty, levels.stars, levels.featured, levels.epic, levels.rated_coins, users.username, users.udid, users.account_id, users.registered from levels join users on levels.user_id = users.id where levels.id = ?", params["levelID"].to_i32) do |rs|
    if rs.move_next
      id = rs.read(Int32)
      name = rs.read(String)
      level_data = rs.read(String)
      extra_data = rs.read(String)
      level_info = rs.read(String)
      password = rs.read(String | Nil)
      user_id = rs.read(Int32)
      description = rs.read(String)
      original = rs.read(Int32 | Nil)
      game_version = rs.read(Int32)
      requested_stars = rs.read(Int32 | Nil)
      version = rs.read(Int32)
      song_id = rs.read(Int32)
      length = rs.read(Int32)
      objects = rs.read(Int32)
      coins = rs.read(Int32)
      has_ldm = rs.read(Bool)
      two_player = rs.read(Bool)
      downloads = rs.read(Int32)
      likes = rs.read(Int32)
      difficulty_int = rs.read(Int32 | Nil)
      difficulty = difficulty_int && LevelDifficulty.new(difficulty_int)
      demon_difficulty_int = rs.read(Int32 | Nil)
      demon_difficulty = demon_difficulty_int && DemonDifficulty.new(demon_difficulty_int)
      stars = rs.read(Int32 | Nil)
      featured = rs.read(Bool)
      epic = rs.read(Bool)
      rated_coins = rs.read(Bool)

      user_username = rs.read(String)
      user_udid = rs.read(String | Nil)
      user_account_id = rs.read(Int32 | Nil)
      user_registered = rs.read(Bool)

      xor_pass = "0"
      if !password
        password = "0"
      elsif params["gameVersion"].to_i >= 20
        xor_pass = GDBase64.encode(XorCrypt.encrypt_string(password, "26364"))
      else
        xor_pass = password
      end

      # https://github.com/Cvolton/GMDprivateServer/blob/master/incl/levels/getGJLevels.php#L266
      response += CrystalGauntlet::Format.fmt_hash({
        1 => id,
        2 => name,
        3 => GDBase64.encode(description),
        4 => level_data,
        5 => version,
        6 => user_id,
        8 => 10,
        9 => difficulty ? difficulty.to_star_difficulty : 0, # 0=N/A 10=EASY 20=NORMAL 30=HARD 40=HARDER 50=INSANE 50=AUTO 50=DEMON
        10 => downloads,
        11 => 1,
        12 => song_id < 50 ? song_id : 0,
        13 => game_version,
        14 => likes,
        17 => difficulty && difficulty.demon?,
        43 => (demon_difficulty || DemonDifficulty::Hard).to_demon_difficulty,
        25 => difficulty && difficulty.auto?,
        18 => stars || 0,
        19 => featured,
        42 => epic,
        45 => objects,
        15 => length,
        30 => original || 0,
        31 => two_player,
        28 => "1",
        29 => "1",
        35 => song_id >= 50 ? song_id : 0,
        36 => extra_data,
        37 => coins,
        38 => rated_coins,
        39 => requested_stars || 0,
        46 => 1,
        47 => 2,
        40 => has_ldm,
        27 => xor_pass,
        # 0 for n/a, 10 for easy, 20, for medium, ...
      })

      if params.has_key?("extras")
        response += ":26:" + level_info
      end

      response += "#" + Hashes.gen_solo(level_data)

      thing = [user_id, stars || 0, (difficulty && difficulty.demon?) || 0, id, rated_coins, featured, password, 0].map! { |x| Format.fmt_value(x) }
      response += "#" + Hashes.gen_solo_2(thing.join(","))
    else
      response += "-1"
    end
  end

  response
}
