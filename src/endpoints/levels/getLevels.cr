require "uri"
require "base64"

include CrystalGauntlet

# things might break if you modify this
levels_per_page = 10

CrystalGauntlet.endpoints["/getGJLevels21.php"] = ->(context : HTTP::Server::Context): String {
  params = URI::Params.parse(context.request.body.not_nil!.gets_to_end)
  LOG.debug { params.inspect }

  can_see_unlisted = false

  # where [...]
  queryParams = [] of String
  # order by [...]
  order = "levels.created_at desc"
  # joins go here
  joins = [] of String

  page_offset = (params["page"]? || "0").to_i * levels_per_page

  searchQuery = params["str"]? || ""

  if !searchQuery.blank? && params["type"] != "5" && params["type"] != "10" && params["type"] != "19"
    if searchQuery.to_i?
      # we do this to get rid of the initial "unlisted = 0" bit
      can_see_unlisted = true
      queryParams << "levels.id = #{searchQuery.to_i}"
    else
      # no sql injections to see here; clean_char only leaves A-Za-z0-9 intact
      # todo: make this configurable w/ fuzzy search
      queryParams << "levels.name like \"#{Clean.clean_char(searchQuery)}%\""
    end
  end

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
    clean_levels = params["completedLevels"][1..-2].split(",").map { |v| v.to_i }
    queryParams << "not levels.id in (#{clean_levels.join(",")})"
  end
  if params["onlyCompleted"]? == "1"
    clean_levels = params["completedLevels"][1..-2].split(",").map { |v| v.to_i }
    queryParams << "levels.id in (#{clean_levels.join(",")})"
  end
  if params["song"]?
    if params["customSong"]? && !params["customSong"].blank?
      queryParams << "song_id = '#{params["customSong"].to_i}'"
    else
      queryParams << "song_id = '#{params["song"].to_i}'"
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
    order = "gauntlet_links.idx asc"
    joins << "left join gauntlet_links on gauntlet_links.level_id = levels.id"
    queryParams << "gauntlet_id = #{params["gauntlet"].to_i}"
  end
  if params["len"]? && params["len"]? != "-"
    queryParams << "levels.length = #{params["len"].to_i}"
  end
  if params["diff"]? && params["diff"]? != "-"
    case params["diff"]?
    when "-1"
      queryParams << "difficulty is null and community_difficulty is null" # NA
    when "-2"
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
      diffs = params["diff"].split(",").map{ |v| v.to_i }.join(",")
      queryParams << "difficulty in (#{diffs}) or (difficulty is null and community_difficulty in (#{diffs}))"
    end
  end

  # level search type
  case params["type"]?
  when "0", "15", nil # default sort (gdw is 15)
    order = "likes desc"
  when "1" # most downloaded
    order = "downloads desc"
  when "2" # most liked
    order = "likes desc"
  when "3" # trending
    # todo: make configurable?
    order = "likes desc"
    queryParams << "levels.created_at > \"#{(Time.utc - 7.days).to_s(Format::TIME_FORMAT)}\""
  when "5" # made by user
    if params["local"]? == "1"
      user_id, account_id = Accounts.auth(params)
      if !(user_id && account_id)
        return "-1"
      end

      if user_id == searchQuery.to_i
        can_see_unlisted = true
        queryParams << "levels.user_id = #{searchQuery.to_i}"
      else
        return "-1"
      end
    else
      queryParams << "levels.user_id = #{searchQuery.to_i}" # (you can't sql inject with numbers)
    end
  when "6", "17" # featured (gdw is 17)
    # todo: order by feature date
    queryParams << "featured = 1"
  when "16" # hall of fame (epic)
    # todo: order by epic date
    queryParams << "epic = 1"
  when "7" # magic
    # todo: make configurable?
    queryParams << "objects > 4000"
  when "10", "19" # map packs
    order = "map_pack_links.idx asc"
    queryParams << "levels.id in (#{searchQuery.split(",").map{|v| v.to_i}.join(",")})"
    joins << "left join map_pack_links on map_pack_links.level_id = levels.id"
  when "11" # rated
    # todo: order by rate date
    queryParams << "levels.stars is not null"
  when "12" # followed
    clean_levels = params["followed"].split(",").map { |v| v.to_i }
    queryParams << "users.account_id in (#{clean_levels.join(",")})"
  when "13" # friends
    user_id, account_id = Accounts.auth(params)
    if !(user_id && account_id)
      return "-1"
    end

    joins << "left join friend_links friend_2 on friend_2.account_id_1 = #{account_id}"
    joins << "left join friend_links friend_1 on friend_1.account_id_2 = #{account_id}"
    joins << "left join users friend_user_1 on friend_1.account_id_1 = friend_user_1.id"
    joins << "left join users friend_user_2 on friend_2.account_id_2 = friend_user_2.id"

    queryParams << "levels.user_id = friend_user_1.id or levels.user_id = friend_user_2.id"
  when "21" # daily
    order = "daily_levels.idx desc"
    joins << "join daily_levels on levels.id = daily_levels.level_id"
  when "22" # weekly
    order = "weekly_levels.idx desc"
    joins << "join weekly_levels on levels.id = weekly_levels.level_id"
  when "23" # event (unused)
    # todo..?
  end

  if !can_see_unlisted
    queryParams << "unlisted = 0"
  end

  where_str = "where (#{queryParams.join(") and (")})"
  # todo: switch join users to left join to avoid losing levels to the shadow realm after a user vanishes
  query_base = "from levels join users on levels.user_id = users.id #{joins.join(" ")} #{where_str} order by #{order}"

  LOG.debug { "query: #{query_base}" }

  level_count = DATABASE.scalar("select count(*) #{query_base}").as(Int64)

  results = [] of String
  users = [] of String
  songs = [] of String

  hash_data = [] of Tuple(Int32, Int32, Bool)

  # fucking help
  DATABASE.query_all("select levels.id, levels.name, levels.user_id, levels.description, levels.original, levels.game_version, levels.requested_stars, levels.version, levels.song_id, levels.length, levels.objects, levels.coins, levels.has_ldm, levels.two_player, levels.downloads, levels.likes, levels.difficulty, levels.community_difficulty, levels.demon_difficulty, levels.stars, levels.featured, levels.epic, levels.rated_coins, users.username, users.udid, users.account_id, users.registered, editor_time, editor_time_copies #{query_base} limit #{levels_per_page} offset #{page_offset}", as: {Int32, String, Int32, String, Int32 | Nil, Int32, Int32 | Nil, Int32, Int32, Int32, Int32, Int32, Bool, Bool, Int32, Int32, Int32 | Nil, Int32 | Nil, Int32 | Nil, Int32 | Nil, Bool, Bool, Bool, String, String | Nil, Int32 | Nil, Bool, Int32, Int32}).each() do |id, name, user_id, description, original, game_version, requested_stars, version, song_id, length, objects, coins, has_ldm, two_player, downloads, likes, set_difficulty_int, community_difficulty_int, demon_difficulty_int, stars, featured, epic, rated_coins, user_username, user_udid, user_account_id, user_registered, editor_time, editor_time_copies|
    set_difficulty = set_difficulty_int && LevelDifficulty.new(set_difficulty_int)
    community_difficulty = community_difficulty_int && LevelDifficulty.new(community_difficulty_int)
    difficulty = set_difficulty || community_difficulty
    demon_difficulty = demon_difficulty_int && DemonDifficulty.new(demon_difficulty_int)

    # https://github.com/Cvolton/GMDprivateServer/blob/master/incl/levels/getGJLevels.php#L266
    results << Format.fmt_hash({
      1 => id,
      2 => name,
      3 => Base64.urlsafe_encode(description),
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
      # 0 for n/a, 10 for easy, 20, for medium, ...
      25 => difficulty && difficulty.auto?,
      30 => original || 0,
      31 => two_player,
      35 => Songs.is_custom_song(song_id) ? song_id : 0,
      37 => coins,
      38 => rated_coins,
      39 => requested_stars || 0,
      40 => has_ldm,
      42 => epic,
      43 => (demon_difficulty || DemonDifficulty::Hard).to_demon_difficulty,
      45 => objects,
      46 => editor_time,
      47 => editor_time_copies
    })

    users << "#{user_id}:#{user_username}:#{user_registered ? user_account_id : user_udid}"

    if Songs.is_custom_song(song_id)
      begin
        song = Songs.fetch_song(song_id, false)
      rescue
      else
        if song != nil
          song_name, song_author_id, song_author_name, song_size, song_download = song.not_nil!
          songs << Format.fmt_song({
            1 => song_id,
            2 => song_name,
            3 => song_author_id,
            4 => song_author_name,
            5 => (song_size || 0) / (1000 * 1000),
            6 => "",
            10 => song_download || "",
            7 => "",
            8 => "1"
          })
        end
      end
    end

    hash_data << {id, stars || 0, rated_coins}
  end

  # `${amount}:${offset}:${levelsPerPage}`
  searchMeta = "#{level_count}:#{page_offset}:#{levels_per_page}"

  res = [results.join("|"), users.join("|"), songs.join("~:~"), searchMeta, CrystalGauntlet::Hashes.gen_multi(hash_data)].join("#")

  res
}

CrystalGauntlet.endpoints["/getGJLevels20.php"] = CrystalGauntlet.endpoints["/getGJLevels21.php"]

