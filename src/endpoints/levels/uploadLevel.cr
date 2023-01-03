require "uri"

include CrystalGauntlet

CrystalGauntlet.endpoints["/uploadGJLevel21.php"] = ->(body : String): String {
  params = URI::Params.parse(body)
  LOG.debug { params.inspect }

  # todo: green user fixes? pretty please?
  user_id, account_id = Accounts.auth(params)
  if !(user_id && account_id)
    return "-1"
  end

  song_id = params["songID"] == "0" ? params["audioTrack"] : params["songID"]

  description = params["levelDesc"]
  if params["gameVersion"].to_i >= 20 # 2.0
    description = Clean.clean_special(GDBase64.decode_string description)
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

  # todo: verify object count, coins and twoplayer (i'm sure it's possible)

  # todo: check seed2?

  if DATABASE.scalar("select count(*) from levels where id = ? and user_id = ?", params["levelID"], params["accountID"]).as(Int64) > 0
    # update existing level
    # todo
    raise "not implemented"
  else
    # create new level
    next_id = IDs.get_next_id("levels")

    DATABASE.exec("insert into levels (id, name, user_id, description, original, game_version, binary_version, password, requested_stars, unlisted, version, level_data, extra_data, level_info, wt1, wt2, song_id, length, objects, coins, has_ldm, two_player) values (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", next_id, Clean.clean_special(params["levelName"]), user_id, description, params["original"].to_i32, params["gameVersion"].to_i32, params["binaryVersion"].to_i32, params["password"] == "0" ? nil : params["password"].to_i32, params["requestedStars"].to_i32, params["unlisted"].to_i32, params["levelVersion"].to_i32, Clean.clean_b64(params["levelString"]), Clean.clean_special(extraString), Clean.clean_b64(params["levelInfo"]), Clean.clean_number(params["wt"]), Clean.clean_number(params["wt2"]), song_id.to_i32, params["levelLength"].to_i32, params["objects"].to_i32, params["coins"].to_i32, params["ldm"].to_i32, params["twoPlayer"].to_i32)

    next_id.to_s
  end
}
