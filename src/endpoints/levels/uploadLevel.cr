require "uri"

include CrystalGauntlet

CrystalGauntlet.endpoints["/uploadGJLevel21.php"] = ->(body : String): String {
  params = URI::Params.parse(body)
  puts params.inspect

  ext_id = Accounts.get_ext_id_from_params(params)
  if ext_id == "-1" || !Accounts.verify_gjp(ext_id, params["gjp"])
    return "-1"
  end
  user_id = Accounts.get_user_id(params["userName"], ext_id)

  song_id = params["songID"] == "0" ? params["audioTrack"] : params["songID"]

  description = params["levelDesc"]
  if params["gameVersion"].to_i >= 20 # 2.0
    description = GDBase64.decode description
  end

  if DATABASE.scalar("select count(*) from levels where id = ? and user_id = ?", params["levelID"], params["accountID"]).as(Int64) > 0
    # update existing level
    raise "not implemented"
  else
    # create new level
    next_id = (DATABASE.scalar("select max(id) from levels").as(Int64 | Nil) || 0) + 1

    DATABASE.exec("insert into levels (id, name, user_id, description, original, game_version, binary_version, password, requested_stars, unlisted, version, level_data, extra_data, level_info, wt1, wt2, song_id, length, objects, coins, has_ldm, two_player) values (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", next_id, params["levelName"], user_id, description, params["original"].to_i32, params["gameVersion"].to_i32, params["binaryVersion"].to_i32, params["password"] == "0" ? nil : params["password"].to_i32, params["requestedStars"].to_i32, params["unlisted"].to_i32, params["levelVersion"].to_i32, params["levelString"], params["extraString"], params["levelInfo"], params["wt"], params["wt2"], song_id.to_i32, params["levelLength"].to_i32, params["objects"].to_i32, params["coins"].to_i32, params["ldm"].to_i32, params["twoPlayer"].to_i32)

    next_id.to_s
  end
}
