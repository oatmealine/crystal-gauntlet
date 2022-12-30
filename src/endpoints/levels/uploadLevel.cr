require "uri"

include CrystalGauntlet

# URI::Params{"gameVersion" => ["21"], "binaryVersion" => ["35"], "gdw" => ["0"], "accountID" => ["8369"], "gjp" => ["Vw9mW0FBUgN_VXtZ"], "userName" => ["oatmealine"], "levelID" => ["0"], "levelName" => ["security"], "levelDesc" => [""], "levelVersion" => ["1"], "levelLength" => ["1"], "audioTrack" => ["0"], "auto" => ["0"], "password" => ["0"], "original" => ["0"], "twoPlayer" => ["0"], "songID" => ["1050575"], "objects" => ["207"], "coins" => ["0"], "requestedStars" => ["0"], "unlisted" => ["0"], "wt" => ["709"], "wt2" => ["0"], "ldm" => ["0"], "extraString" => ["0_73_0_39_0_0_0_0_0_0_0_0_66_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0"], "seed" => ["SbpPMJ9vjn"], "seed2" => ["UFIKAAQCA1RTB1cABFEMUlBRDwFRUgMPAlAHVFYMUQFXAwEGCAAPDQ=="], "levelString" => ["H4sIAAAAAAAAC61Xy5HYIAxtyLuDJCTB5JQatgAKSAspPvxssC1lc8jBZngPhNAP-PVF6YASpWBhKlQkFoCCzAVwNNSbWD6gSIEQQtECBbj9UgklFfgNtcX6Uf2-mQ7udAhYxuhvRGRTRBszJvyTkLrfYusyBAE2Qe3_jSD-X4LEEXT8-gl0hNbwaGQ08ah_OaB1dECzSa35otx72P9DQid-xv4fbJ3dGzjCDzhAYzzwoHDQAbyA3IDYgdoD4qtL1HiQhmj91dU-ucIHNDbCTmIl8MB46JjZydxICHOq9rldlUAXLXlMCBVB7BMApjLViLtumDpdl8QmI8SuRlhMTEe1WRpLILbdxqnCpXGkKaQh0BCBU-xLzS7j4iuEXfM1oyr8IW3bH7TPPjcg-_Ktr6dFth0MkYNRWDuoqAZjfMPJwcWTPyXt8gdOb7zvWofzaNipxcnYdO5AMzoE2UyJHUm6mWpCp602u5xTL8NAyPaOANAj2COSQyB4RPQIfahJjkNqAHuE5ZJOGDvGsK_ysFnEhzLRs0D0LMCWBYa_gZGW-JGg3LefX8EEHF_ELAdh1IOKpFE88i2FZx-2RUScRYQ8IryIUT9A-WGiCWzLaXKkKjpEAo94W2ESL7uR9IIXljFmCRxbOdXN-a5_zSHbkxgc32MwfI8hbNQ9rBCcrEBwsgLBqmK9fIeH-uhkBaKTFYhGVkTdhMsqzw0lz0DkGYic5MDoGSJahuj-w1gLZ6Uwr_MUuSuKtUbK8ZEvTQc8CypRn86yYRuQ-R7cfbA88v8EZAHpyr4ecKh6P0D3PvZz8xlwacvXljwXpNeQjGPI00yZHTy98Sl6iFKTYp9Kb6rfbMBUgEJ0cH3jYWPydSNYi89FLL3mOjaltsoQbNX2a1jvizMue7adok1thnSbEp_K9h7QjgdCOx4I3_EgEpakRNtVM2wKoBstcy2bcqKFnGghJ1rIiJa5BPkxQX5MkBMTlLNTbirVyk3aLmtTVjTc1nE0ZI17sUGcwhxHRydYIzm4E7TRD9roR2Y04nmtsmroFN9i3BBinTu3bd85yuMVgfrZSOFP5A2OaMJsj1Z7dLqPPtVh6wA7OefUI07G3teMty_YSVJ2i_acYvqI_QxlJw3nVgyN2XcjG2f4NCcH08oMpk-Y7NHRHi326DxggNjef_sDjsS5VJA4tysy34hL1NtV4hQs8QuW-AVLjKp0Uu9aNi0gYdgr3Qxwkoh_IelvM8V0gyTTDZIfidRAdWqWOjXLe3GT9-Qm883dCetJO02pfp1T_9xW_3DWd82eZlEwraV2SVO7pKld0tQuafosaUv5daVRzU8P1IOvEmm-2Wo0jNszmijRwHv9qGrsGBtY2rBxmibQ_TT9A3vViWgxFQAA"], "levelInfo" => ["H4sIAAAAAAAACyXQyxHAIAgE0I6YAPJx7L-v7MIl5ImA-snRp--T0w_f8EFcIs8gB7WZGvSiY9CD68Stx35P5WM1QhM2y-JBzESEImaiSvI_d1cZcZkw-dDMN-Mz3Xegy0XNke8CR0wJ60EYUTro816yUhEuthV7KoIGMUcr8SQiBolMb-sWw8UUz8DeiqugH0LOuW2zJoXVH1ldIOdMAQAA"], "secret" => ["Wmfd2893gb7"]}

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
