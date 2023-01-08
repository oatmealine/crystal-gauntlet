require "uri"

include CrystalGauntlet

CrystalGauntlet.endpoints["/deleteGJLevelUser20.php"] = ->(context : HTTP::Server::Context): String {
  params = URI::Params.parse(context.request.body.not_nil!.gets_to_end)

  user_id, account_id = Accounts.auth(params)
  if !(user_id && account_id)
    user_id, account_id = Accounts.auth_old(context.request, params)
    if !(user_id && account_id)
      return "-1"
    end
  end

  level_id = params["levelID"].to_i

  prevent_rated_str = config_get("levels.prevent_deletion_rated").as(Bool | Nil) == true ? "and stars is null" : ""
  prevent_featured_str = config_get("levels.prevent_deletion_featured").as(Bool | Nil) == true ? "and featured = 0" : ""

  DATABASE.exec("delete from levels where id = ? and user_id = ? #{prevent_rated_str} #{prevent_featured_str}", level_id, user_id)

  return "1"
}

CrystalGauntlet.endpoints["/deleteGJLevelUser19.php"] = CrystalGauntlet.endpoints["/deleteGJLevelUser20.php"]
