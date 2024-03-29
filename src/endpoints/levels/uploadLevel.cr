require "uri"

include CrystalGauntlet

CrystalGauntlet.endpoints["/uploadGJLevel21.php"] = ->(context : HTTP::Server::Context): String {
  params = URI::Params.parse(context.request.body.not_nil!.gets_to_end)
  LOG.debug { params.inspect }

  # todo: green user fixes? pretty please?
  user_id, account_id = Accounts.auth(params)
  if !(user_id && account_id)
    user_id, account_id = Accounts.auth_old(context.request, params)
    if !(user_id && account_id)
      return "-1"
    end
  end

  song_id = params["songID"] == "0" ? params["audioTrack"] : params["songID"]

  description = params["levelDesc"]
  if Versions.parse(params["gameVersion"]) >= Versions::V2_0
    description = Clean.clean_special(Base64.decode_string description)
  else
    description = Clean.clean_special(description)
  end
  # todo: patch descriptions to prevent color bugs

  # todo: use 1.9 levelInfo..?
  # https://github.com/Cvolton/GMDprivateServer/blob/master/incl/levels/uploadGJLevel.php#L56

  # todo: use 2.2 unlisted

  extraString = params["extraString"]? || Level::DEFAULT_EXTRA_STRING

  original = (params["original"]? || "0").to_i32
  if original == 0
    original = nil
  end

  if config_get("levels.parsing.enabled").as?(Bool)
    # todo: parse ldm
    # todo: parse level length

    LOG.debug { "parsing objects" }

    level_raw_objects = Level.decode(params["levelString"])
    level_objects = Level.to_objectdata(level_raw_objects)
    inner_level_string = level_raw_objects.find! { |obj| !obj.has_key?("1") && obj["kA9"]? == "0" }
    objects = level_objects.size

    forbidden_objects = config_get("levels.parsing.object_blocklist").as?(Array(TOML::Type))
    if forbidden_objects
      # stupid hack; i think this is a crystal compiler bug
      forbidden_objects = forbidden_objects.map { |v| v.as?(Int64) }.compact
    else
      forbidden_objects = [] of Int64
    end
    allowed_objects = config_get("levels.parsing.object_allowlist").as?(Array(TOML::Type))
    if allowed_objects
      allowed_objects = allowed_objects.map { |v| v.as?(Int64) }.compact
    else
      allowed_objects = [] of Int64
    end

    LOG.debug { "forbidden objects: #{forbidden_objects.inspect}" }
    LOG.debug { "allowed objects: #{allowed_objects.inspect}" }

    if forbidden_obj = level_objects.find do |obj|
      if allowed_objects.size > 0
        if !allowed_objects.includes?(obj.id)
          true
        end
      end
      if forbidden_objects.includes?(obj.id)
        true
      end
    end
      LOG.info { "preventing upload of level with forbidden obj #{forbidden_obj.id}" }
      return "-1"
    end

    if exploit_obj = level_objects.find { |obj|
      # target color ID
      (obj.target_color_id.try { |n| n < 0 } || obj.target_color_id.try { |n| n > 1100 } ) ||
      # target group ID
      (obj.target_group_id.try { |n| n < 0 } || obj.target_group_id.try { |n| n > 1100 } )
    }
      LOG.info { "preventing upload of level attempting to exploit invalid color/group IDs" }
      return "-1"
    end

    coins = level_objects.count { |obj| obj.id == 1329 } # user coin id

    # todo: check if dual portals even exist?
    two_player = inner_level_string["kA10"]? == "1"

    # todo: currently brokey
    #level_length_secs = Level.measure_length(level_objects, inner_level_string["kA4"]?.try &.to_i? || 0)
    #LOG.debug { "level is #{level_length_secs}s long" }
  else
    objects = params["objects"].to_i
    coins = params["coins"].to_i
    two_player = params["twoPlayer"].to_i == 1
  end

  level_length = params["levelLength"].to_i.clamp(0..4)

  if coins < 0 || coins > 3
    LOG.info { "preventing upload of level with #{coins} coins" }
    return "-1"
  end
  if objects <= 0
    LOG.info { "preventing upload of 0-object level" }
    return "-1"
  end

  max_objects = config_get("levels.max_objects").as?(Int64)
  if max_objects != nil && max_objects.not_nil! > 0 && objects > max_objects.not_nil!
    LOG.info { "preventing upload of level with #{objects} objects (max #{max_objects})" }
    return "-1"
  end

  # todo: check seed2?

  requested_stars = (params["requestedStars"]? || "0").to_i.clamp(0..10)
  if requested_stars == 0
    requested_stars = nil
  end

  if DATABASE.scalar("select count(*) from levels where id = ?", params["levelID"]).as(Int64) > 0
    # update existing level
    level_user_id = DATABASE.query_one("select user_id from levels where id = ?", params["levelID"].to_i, as: {Int32})

    if level_user_id != user_id
      return "-1"
    end

    DATABASE.exec("update levels set description = ?, password = ?, requested_stars = ?, version = ?, extra_data = ?, level_info = ?, editor_time = ?, editor_time_copies = ?, song_id = ?, length = ?, objects = ?, coins = ?, has_ldm = ?, two_player = ?, modified_at = ? where id = ?", description[..140-1], params["password"] == "0" ? nil : params["password"].to_i, requested_stars, params["levelVersion"].to_i, Clean.clean_special(extraString), Clean.clean_b64(params["levelInfo"]), (params["wt"]? || "0").to_i, (params["wt2"]? || "0").to_i, song_id.to_i, level_length, objects, coins, (params["ldm"]? || "0").to_i == 1, two_player, Time.utc.to_s(Format::TIME_FORMAT), params["levelID"].to_i)

    File.write(DATA_FOLDER / "levels" / "#{params["levelID"]}.lvl", Base64.decode(params["levelString"]))

    return params["levelID"]
  else
    # create new level
    next_id = IDs.get_next_id("levels")

    DATABASE.exec("insert into levels (id, name, user_id, description, original, game_version, binary_version, password, requested_stars, unlisted, version, extra_data, level_info, editor_time, editor_time_copies, song_id, length, objects, coins, has_ldm, two_player) values (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", next_id, Clean.clean_basic(params["levelName"])[..20-1], user_id, description[..140-1], params["original"].to_i, params["gameVersion"].to_i, (params["binaryVersion"]? || "0").to_i, params["password"] == "0" ? nil : params["password"].to_i, requested_stars, (params["unlisted"]? || "0").to_i == 1, params["levelVersion"].to_i, Clean.clean_special(extraString), Clean.clean_b64(params["levelInfo"]? || ""), (params["wt"]? || "0").to_i, (params["wt2"]? || "0").to_i, song_id.to_i, level_length, objects, coins, (params["ldm"]? || "0").to_i == 1, two_player)

    File.write(DATA_FOLDER / "levels" / "#{next_id.to_s}.lvl", Base64.decode(params["levelString"]))

    return next_id.to_s
  end
}

CrystalGauntlet.endpoints["/uploadGJLevel20.php"] = CrystalGauntlet.endpoints["/uploadGJLevel21.php"]

CrystalGauntlet.endpoints["/uploadGJLevel19.php"] = CrystalGauntlet.endpoints["/uploadGJLevel21.php"]

