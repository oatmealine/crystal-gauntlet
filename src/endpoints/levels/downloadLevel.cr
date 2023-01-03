require "uri"
require "base64"

include CrystalGauntlet

CrystalGauntlet.endpoints["/downloadGJLevel22.php"] = ->(context : HTTP::Server::Context): String {
  params = URI::Params.parse(context.request.body.not_nil!.gets_to_end)
  LOG.debug { params.inspect }

  response = [] of String

  DATABASE.query("select levels.id, levels.name, levels.level_data, levels.extra_data, levels.level_info, levels.password, levels.user_id, levels.description, levels.original, levels.game_version, levels.requested_stars, levels.version, levels.song_id, levels.length, levels.objects, levels.coins, levels.has_ldm, levels.two_player, levels.downloads, levels.likes, levels.difficulty, levels.community_difficulty, levels.demon_difficulty, levels.stars, levels.featured, levels.epic, levels.rated_coins, users.username, users.udid, users.account_id, users.registered, editor_time, editor_time_copies from levels join users on levels.user_id = users.id where levels.id = ?", params["levelID"].to_i32) do |rs|
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
      set_difficulty_int = rs.read(Int32 | Nil)
      set_difficulty = set_difficulty_int && LevelDifficulty.new(set_difficulty_int)
      community_difficulty_int = rs.read(Int32 | Nil)
      community_difficulty = community_difficulty_int && LevelDifficulty.new(community_difficulty_int)
      difficulty = set_difficulty || community_difficulty
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

      editor_time = rs.read(String)
      editor_time_copies = rs.read(String)

      xor_pass = "0"
      if !password
        password = "0"
      elsif params["gameVersion"].to_i >= 20
        xor_pass = Base64.urlsafe_encode(XorCrypt.encrypt_string(password, "26364"))
      else
        xor_pass = password
      end

      # todo: deduplicate this with getLevels?
      response << CrystalGauntlet::Format.fmt_hash({
        1 => id,
        2 => name,
        3 => Base64.urlsafe_encode(description),
        4 => level_data,
        5 => version,
        6 => user_id,
        # this is suppoused to be the amount of people who have
        # voted on a level, but this is unused by the game, so
        # we just always tell the game 10 people have voted
        8 => 10,
        # 0=N/A 10=EASY 20=NORMAL 30=HARD 40=HARDER 50=INSANE 50=AUTO 50=DEMON
        # divided by above value, which is why its multiplied by 10
        9 => (difficulty ? difficulty.to_star_difficulty : 0).not_nil! * 10,
        10 => downloads,
        12 => !Songs.is_custom_song(song_id) ? song_id : 0,
        13 => game_version,
        # likes - dislikes
        14 => likes,
        # dislikes - likes
        16 => -likes,
        15 => length,
        17 => difficulty && difficulty.demon?,
        18 => stars || 0,
        19 => featured,
        25 => difficulty && difficulty.auto?,
        27 => xor_pass,
        # todo
        # upload date
        28 => "1",
        # update date
        29 => "1",
        30 => original || 0,
        31 => two_player,26 => params.has_key?("extras") ? level_info : nil,
        35 => Songs.is_custom_song(song_id) ? song_id : 0,
        36 => extra_data,
        37 => coins,
        38 => rated_coins,
        39 => requested_stars || 0,
        40 => has_ldm,
        42 => epic,
        # 0 for n/a, 10 for easy, 20, for medium, ...
        43 => (demon_difficulty || DemonDifficulty::Hard).to_demon_difficulty,
        # todo
        44 => false,
        45 => objects,
        46 => editor_time,
        47 => editor_time_copies
      })
      response << Hashes.gen_solo(level_data)

      thing = [user_id, stars || 0, (difficulty && difficulty.demon?) || 0, id, rated_coins, featured, password, 0].map { |x| Format.fmt_value(x) }
      response << Hashes.gen_solo_2(thing.join(","))

      return response.join("#")
    else
      return "-1"
    end
  end
}
