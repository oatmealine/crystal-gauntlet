require "uri"

include CrystalGauntlet

CrystalGauntlet.endpoints["/uploadGJLevel21.php"] = ->(context : HTTP::Server::Context): String {
  params = URI::Params.parse(context.request.body.not_nil!.gets_to_end)
  LOG.debug { params.inspect }

  # todo: green user fixes? pretty please?
  user_id, account_id = Accounts.auth(params)
  if !(user_id && account_id)
    return "-1"
  end

  song_id = params["songID"] == "0" ? params["audioTrack"] : params["songID"]

  description = params["levelDesc"]
  if params["gameVersion"].to_i >= 20 # 2.0
    description = Clean.clean_special(Base64.decode_string description)
  else
    description = Clean.clean_special(description)
  end
  # todo: patch descriptions to prevent color bugs

  # todo: use 1.9 levelInfo..?
  # https://github.com/Cvolton/GMDprivateServer/blob/master/incl/levels/uploadGJLevel.php#L56

  # todo: use 2.2 unlisted

  # todo: https://github.com/Cvolton/GMDprivateServer/blob/master/incl/levels/uploadGJLevel.php#L53
  extraString = params["extraString"]? || "29_29_29_40_29_29_29_29_29_29_29_29_29_29_29_29"

  original = (params["original"]? || "0").to_i32
  if original == 0
    original = nil
  end

  # todo: cap level length
  # todo: cap coins
  # todo: cap ldm to bool
  # todo: cap twoplayer to bool
  # todo: cap unlisted to bool
  # todo: cap requested stars

  if config_get("levels.parsing.enabled").as?(Bool)
    LOG.debug { "parsing objects" }

    level_objects = Level.decode(params["levelString"])
    objects = level_objects.size - 1 # remove 1 to account for start state obj

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
      if !obj.has_key?("1")
        false
      else
        id = obj["1"].to_i
        if allowed_objects.size > 0
          if !allowed_objects.includes?(id)
            true
          end
        else
          if forbidden_objects.includes?(id)
            true
          end
        end
      end
    end
      LOG.info { "preventing upload of level with forbidden obj #{forbidden_obj["1"]}" }
      return "-1"
    end

    coins = level_objects.count { |obj| obj["1"]? == "1329" } # user coin id

    # todo: check if dual portals even exist?
    two_player = false
    level_objects.each do |obj|
      if !obj.has_key?("1") && obj["kA10"]? == "1"
        two_player = true
      end
    end
  else
    objects = params["objects"].to_i
    coins = params["coins"].to_i
    two_player = params["twoPlayer"].to_i == 1
  end

  if coins < 0 || coins > 3
    return "-1"
  end
  if objects <= 0
    return "-1"
  end

  max_objects = config_get("levels.max_objects").as?(Int64)
  if max_objects != nil && max_objects.not_nil! > 0 && objects > max_objects.not_nil!
    LOG.info { "preventing upload of level with #{objects} objects (max #{max_objects})" }
    return "-1"
  end

  # todo: verify level length

  # todo: check seed2?

  if DATABASE.scalar("select count(*) from levels where id = ? and user_id = ?", params["levelID"], params["accountID"]).as(Int64) > 0
    # update existing level
    # todo
    raise "not implemented"
  else
    # create new level
    next_id = IDs.get_next_id("levels")

    DATABASE.exec("insert into levels (id, name, user_id, description, original, game_version, binary_version, password, requested_stars, unlisted, version, level_data, extra_data, level_info, editor_time, editor_time_copies, song_id, length, objects, coins, has_ldm, two_player) values (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", next_id, Clean.clean_special(params["levelName"]), user_id, description, params["original"].to_i32, params["gameVersion"].to_i32, params["binaryVersion"].to_i32, params["password"] == "0" ? nil : params["password"].to_i32, params["requestedStars"].to_i32, params["unlisted"].to_i32, params["levelVersion"].to_i32, Clean.clean_b64(params["levelString"]), Clean.clean_special(extraString), Clean.clean_b64(params["levelInfo"]), params["wt"].to_i32, params["wt2"].to_i32, song_id.to_i32, params["levelLength"].to_i32, objects, coins, params["ldm"].to_i32, two_player)

    return "-1"

    #return next_id.to_s
  end
}
