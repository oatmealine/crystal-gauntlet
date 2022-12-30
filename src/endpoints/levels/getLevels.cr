require "uri"
require "base64"

include CrystalGauntlet

CrystalGauntlet.endpoints["/getGJLevels21.php"] = ->(body : String): String {
  params = URI::Params.parse(body)
  puts params.inspect

  results = [] of String
  users = [] of String
  songs = [] of String

  hash_data = [] of Tuple(Int32, Int32, Bool)

  DATABASE.query "select levels.id, levels.name, levels.user_id, levels.description, levels.original, levels.game_version, levels.requested_stars, levels.version, levels.song_id, levels.length, levels.objects, levels.coins, levels.has_ldm, levels.two_player, levels.downloads, levels.likes, levels.difficulty, levels.demon_difficulty, levels.stars, levels.featured, levels.epic, levels.rated_coins, users.username, users.udid, users.account_id, users.registered from levels join users on levels.user_id = users.id" do |rs|
    rs.each do
      id = rs.read(Int32)
      name = rs.read(String)
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

      # https://github.com/Cvolton/GMDprivateServer/blob/master/incl/levels/getGJLevels.php#L266
      results << CrystalGauntlet::Format.fmt_hash({
        1 => id,
        2 => name,
        5 => version,
        6 => user_id,
        8 => 10,
        9 => difficulty ? difficulty.to_star_difficulty : 0, # 0=N/A 10=EASY 20=NORMAL 30=HARD 40=HARDER 50=INSANE 50=AUTO 50=DEMON
        10 => downloads,
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
        3 => Base64.encode(description).sub('/', '_').sub('+', '-').strip("\n"),
        15 => length,
        30 => original || 0,
        31 => two_player,
        37 => coins,
        38 => rated_coins,
        39 => requested_stars || 0,
        46 => 1,
        47 => 2,
        40 => has_ldm,
        35 => song_id >= 50 ? song_id : 0, # 0 for n/a, 10 for easy, 20, for medium, ...
      })

      users << "#{user_id}:#{user_username}:#{user_registered ? user_account_id : user_udid}"

      hash_data << {id, stars || 0, rated_coins}
    end
  end

  # `:${offset}:${levelsPerPage}`
  searchMeta = "#{results.size}:0:10"

  res = [results.join("|"), users.join("|"), songs.join("|"), searchMeta, CrystalGauntlet::Hashes.gen_multi(hash_data)].join("#")
  puts res

  res
}
