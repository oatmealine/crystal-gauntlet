require "uri"

include CrystalGauntlet

CrystalGauntlet.endpoints["/deleteGJAccComment20.php"] = ->(context : HTTP::Server::Context): String {
  params = URI::Params.parse(context.request.body.not_nil!.gets_to_end)
  LOG.debug { params.inspect }

  user_id, account_id = Accounts.auth(params)
  if !(user_id && account_id)
    return "-1"
  end

  comment_id = params["commentID"].to_i

  # kind of a dumb hack, but it works
  target_account_id = DATABASE.scalar("select max(account_id) from account_comments where id = ?", comment_id).as(Int64 | Nil)

  # todo: let mods delete any comment
  if target_account_id && account_id == target_account_id
    DATABASE.exec("delete from account_comments where id = ?", comment_id)
    return "1"
  else
    return "-1"
  end
}
