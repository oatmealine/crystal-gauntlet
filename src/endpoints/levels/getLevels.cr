require "uri"
require "base64"

include CrystalGauntlet

# things might break if you modify this
levels_per_page = 10

CrystalGauntlet.endpoints["/getGJLevels21.php"] = ->(body : String): String {
  params = URI::Params.parse(body)
  puts params.inspect

  # where [...]
  queryParams = ["unlisted = 0"] # don't leave the default empty!!
  # order by [...]
  order = "levels.created_at desc"

  page_offset = Clean.clean_number(params["page"]? || "0").to_i * levels_per_page

  searchQuery = params["str"]? || ""

  # filters
  if params["featured"]? == "1"
    queryParams << "featured = 1"
  end
  if params["original"]? == "1"
    queryParams << "original is null"
  end
  if params["coins"]? == "1"
    queryParams << "rated_coins = 1 and levels.coins != 0"
  end
  if params["epic"]? == "1"
    queryParams << "epic = 1"
  end
  if params["uncompleted"]? == "1"
    # todo
    # $completedLevels = ExploitPatch::numbercolon($_POST["completedLevels"]);
	  # $params[] = "NOT levelID IN ($completedLevels)";
  end
  if params["onlyCompleted"]? == "1"
    # todo
	  # $completedLevels = ExploitPatch::numbercolon($_POST["completedLevels"]);
	  # $params[] = "levelID IN ($completedLevels)";
  end
  if params["song"]?
    if params["customSong"]? && params["customSong"]? != ""
      # todo
    else
      queryParams << "song_id = '#{Clean.clean_number(params["song"])}'"
    end
  end
  if params["twoPlayer"]? == "1"
    queryParams << "two_player = 1"
  end
  if params["star"]? == "1"
    queryParams << "levels.stars is not null"
  end
  if params["noStar"]? == "1"
    queryParams << "levels.stars is null"
  end
  if params["gauntlet"]?
    # todo
  end
  if params["len"]?
    # todo
  end
  if params["diff"]? && params["diff"]? != "-"
    case params["diff"]?
    when "-1"
      queryParams << "difficulty is null and community_difficulty is null" # NA
    when "-2"
      puts "demon :)"
      case params["demonFilter"]?
      when "1"
        queryParams << "demon_difficulty = #{DemonDifficulty::Easy.value}"
      when "2"
        queryParams << "demon_difficulty = #{DemonDifficulty::Medium.value}"
      when "3"
        queryParams << "demon_difficulty = #{DemonDifficulty::Hard.value}"
      when "4"
        queryParams << "demon_difficulty = #{DemonDifficulty::Insane.value}"
      when "5"
        queryParams << "demon_difficulty = #{DemonDifficulty::Extreme.value}"
      end
      queryParams << "difficulty = #{LevelDifficulty::Demon.value} or (difficulty is null and community_difficulty = #{LevelDifficulty::Demon.value})"
    when "-3"
      queryParams << "difficulty = #{LevelDifficulty::Auto.value} or (difficulty is null and community_difficulty = #{LevelDifficulty::Auto.value})"
    else
      # easy, normal, hard, harder, insane
      # todo
    end
  end

  # level search type
  case params["type"]
  when "0", "15", nil # default sort (gdw is 15)
    order = "likes desc"
  when "1" # most downloaded
    order = "downloads desc"
  when "2" # most liked
    order = "likes desc"
  when "3" # trending
    # todo
  when "5" # made by user
    queryParams << "levels.user_id = #{Clean.clean_number(searchQuery)}" # (you can't sql inject with numbers)
  when "6", "17" # featured (gdw is 17)
    # todo: order by feature date
    queryParams << "featured = 1"
  when "16" # hall of fame (epic)
    # todo: order by epic date
    queryParams << "epic = 1"
  when "7" # magic
    # todo
  when "10", "19" # map packs
    # todo
  when "11" # rated
    # todo: order by rate date
    queryParams << "levels.stars is not null"
  when "12" # followed
    # todo
  when "13" # friends
    # todo
  when "21" # daily
    # todo
  when "22" # weekly
    # todo
  when "23" # event (unused)
    # todo
  end

  # todo: search query

  where_str = "where (#{queryParams.join(") and (")})"
  query_base = "from levels join users on levels.user_id = users.id left join songs on levels.song_id = songs.id #{where_str} order by #{order}"

  puts query_base

  level_count = DATABASE.scalar("select count(*) #{query_base}").as(Int64)

  results = [] of String
  users = [] of String
  songs = [] of String

  hash_data = [] of Tuple(Int32, Int32, Bool)

  DATABASE.query "select levels.id, levels.name, levels.user_id, levels.description, levels.original, levels.game_version, levels.requested_stars, levels.version, levels.song_id, levels.length, levels.objects, levels.coins, levels.has_ldm, levels.two_player, levels.downloads, levels.likes, levels.difficulty, levels.community_difficulty, levels.demon_difficulty, levels.stars, levels.featured, levels.epic, levels.rated_coins, users.username, users.udid, users.account_id, users.registered, songs.name, songs.author_id, songs.author_name, songs.size, songs.disabled, songs.download #{query_base} limit #{levels_per_page} offset #{page_offset}" do |rs|
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

      song_name = rs.read(String | Nil)
      song_author_id = rs.read(Int32 | Nil)
      song_author_name = rs.read(String | Nil)
      song_size = rs.read(Int32 | Nil)
      song_disabled = rs.read(Int32 | Nil)
      song_download = rs.read(String | Nil)

      # https://github.com/Cvolton/GMDprivateServer/blob/master/incl/levels/getGJLevels.php#L266
      results << Format.fmt_hash({
        1 => id,
        2 => name,
        5 => version,
        6 => user_id,
        8 => 10,
        9 => difficulty ? difficulty.to_star_difficulty : 0, # 0=N/A 10=EASY 20=NORMAL 30=HARD 40=HARDER 50=INSANE 50=AUTO 50=DEMON
        10 => downloads,
        12 => !Songs.is_custom_song(song_id) ? song_id : 0,
        13 => game_version,
        14 => likes,
        17 => difficulty && difficulty.demon?,
        # 0 for n/a, 10 for easy, 20, for medium, ...
        43 => (demon_difficulty || DemonDifficulty::Hard).to_demon_difficulty,
        25 => difficulty && difficulty.auto?,
        18 => stars || 0,
        19 => featured,
        42 => epic,
        45 => objects,
        3 => GDBase64.encode(description),
        15 => length,
        30 => original || 0,
        31 => two_player,
        37 => coins,
        38 => rated_coins,
        39 => requested_stars || 0,
        46 => 1,
        47 => 2,
        40 => has_ldm,
        35 => Songs.is_custom_song(song_id) ? song_id : 0,
      })

      users << "#{user_id}:#{user_username}:#{user_registered ? user_account_id : user_udid}"

      if Songs.is_custom_song(song_id) && song_disabled == 0
        songs << Format.fmt_song({
          1 => song_id,
          2 => song_name,
          3 => song_author_id,
          4 => song_author_name,
          5 => song_size.not_nil! / (1000 * 1000),
          6 => "",
          10 => song_download,
          7 => "",
          8 => "1"
        })
      end

      hash_data << {id, stars || 0, rated_coins}
    end
  end

  # `${amount}:${offset}:${levelsPerPage}`
  searchMeta = "#{level_count}:#{page_offset}:#{levels_per_page}"

  res = [results.join("|"), users.join("|"), songs.join("~:~"), searchMeta, CrystalGauntlet::Hashes.gen_multi(hash_data)].join("#")
  puts res

  res
}
